import os
import sys
import multiprocessing
import getopt
import numpy as np
import caffe
import glob
import h5py
import skvideo.io
import skimage.io

from PIL import ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

def frameworker(qvideo, qframe):
    while True:
        video = qvideo.get()
        if video == '':
            break
        frames = glob.glob('%s/%s/*.png' %(inputPath, video))
        featlist = map(os.path.basename, frames)
        temp = [x.split('_')[1].split('.')[0] for x in featlist]
        ids = map(int, temp)
        ids.sort()
        num_frames = len(frames)
        for i in range(0, num_frames):
            imgpath = '%s/%s/%s_%08d.png' %(inputPath, video, video, ids[i])
            if os.path.getsize(imgpath) != 0:
                try:
                    image = skimage.io.imread(imgpath)
                    qframe.put(image)
                except:
                    print "    Failed to Load image: " + imgpath
                    sys.stdout.flush()
                    continue
        qframe.put([])

def videoworker(qvideo, qframe):
    while True:
        video = qvideo.get()
        if video == '':
            break
        try:
            reader = skvideo.io.ffmpeg.FFmpegReader('%s/%s.mp4' % (inputPath, video))
        except:
            print "    Something wrong in video " + video + " cannot read"
            sys.stdout.flush()
            qframe.put([])
            continue
        fstep = int(reader.inputfps) * 2
        fid = -1
        fct = 0
        fnum = int((reader.inputframenum + fid + fstep - 1) / fstep)
        try:
            for frame in reader.nextFrame():
                if fid % fstep == 0:
                    qframe.put(frame)
                    fct += 1
                    if fct == fnum:
                        break
                fid += 1
        except:
            if fct < fnum - 1:
                print "    Something wrong in video " + video + " at frame #" + str(fid) + '/' + str(fnum * fstep)
                sys.stdout.flush()
        print "    Video " + video + " had " + str(reader.inputframenum) + " frames, " + str(fnum) + " choosen, " + str(fct) + " read"
        sys.stdout.flush()
        reader.close()
        qframe.put([])

def deepworker(qu, gi, qvideo, qframe):
    print "[" + str(gi) + "] Initializing Caffe with GPU #" + str(gi) + "."
    sys.stdout.flush()
    caffe.set_device(gi)
    caffe.set_mode_gpu()

    print "[" + str(gi) + "] Loading Deep Model."
    sys.stdout.flush()
    net = caffe.Net(modelDef,      # defines the structure of the model
                    modelWeights,  # contains the trained weights
                    caffe.TEST)    # use test mode (e.g., don't perform dropout)

    if not 'data' in net.blobs:
        assert False, "[" + str(gi) + "] Deep Model doesn't have a layer named data."
    for layerName in layerNames:
        if not layerName in net.blobs:
            assert False, "[" + str(gi) + "] Deep Model doesn't have a layer named " + layerName + "."

    mu = np.load(meanImgPath)
    mu = mu.mean(1).mean(1)  # average over pixels to obtain the mean (BGR) pixel values

    transformer = caffe.io.Transformer({'data': net.blobs['data'].data.shape})

    transformer.set_transpose('data', (2, 0, 1))     # move image channels to outermost dimension
    transformer.set_mean('data', mu)                 # subtract the dataset-mean value in each channel
    transformer.set_raw_scale('data', 255)           # rescale from [0, 1] to [0, 255]
    transformer.set_channel_swap('data', (2, 1, 0))  # swap channels from RGB to BGR

    net.blobs['data'].reshape(1,         # batch size
                              3,         # 3-channel (BGR) images
                              224, 224)  # image size is 224x224
    print "[" + str(gi) + "] Deep Model Loaded."
    sys.stdout.flush()

    nfeat = {}
    for layerName in layerNames:
        nfeat[layerName] = int(net.blobs[layerName].data[0].size)

    while True:
        video = qu.get()
        if video == '':
            print "[" + str(gi) + "] Done."
            sys.stdout.flush()
            qvideo.put('')
            break

        feats = {}
        for layerName in layerNames:
            feats[layerName] = np.empty((0, nfeat[layerName]), dtype=np.float32)
        print "[" + str(gi) + "] Processing " + video
        sys.stdout.flush()
        qvideo.put(video)
        while True:
            frame = qframe.get()
            if frame == []:
                break
            image = skimage.img_as_float(frame).astype(np.float32)
            transformed_image = transformer.preprocess('data', image)
            net.blobs['data'].data[0, ...] = transformed_image
            net.forward()
            for layerName in layerNames:
                feats[layerName] = np.append(feats[layerName], net.blobs[layerName].data[0].reshape(1, -1), axis=0)

        for layerName in layerNames:
            if feats[layerName].shape[0] > 0:
                outFrameFeatureFile = os.path.join(outputFrameFeaturePath, layerName.split("/")[0], video + ".h5")
                with h5py.File(outFrameFeatureFile, 'w') as hf:
                    hf.create_dataset('feature', data=feats[layerName], dtype=np.float32)
                videofeat = feats[layerName].mean(axis=0)
                outAvgFeatureFile = os.path.join(outputAvgFeaturePath, layerName.split("/")[0], video)
                if not os.path.exists(outAvgFeatureFile):
                    os.mknod(outAvgFeatureFile)
                with open(outAvgFeatureFile, 'w') as writer:
                    videofeat = videofeat.reshape(1, -1)
                    np.savetxt(writer, videofeat, fmt='%.9g')
            else:
                with open(exceptionVideoList, 'a') as ll:
                    ll.write(video + "\n")

if __name__ == '__main__':
    #Parameter Parsing
    modelDef = ''
    modelWeights = ''
    meanImgPath = ''
    layerNames = ''

    input = ''
    inputPath = ''
    videoList = ''

    outputFrameFeaturePath = ''
    outputAvgFeaturePath = ''
    exceptionVideoList = ''

    gpuId = [0]

    opts, args = getopt.getopt(sys.argv[1:], "", ["modelDef=", "modelWeights=", "meanImg=", "input=", 
                                            "inputPath=", "outputFrameFeaturePath=", "outputAvgFeaturePath=",
                                            "videoList=", "videoListType=",
                                            "layerNames=", "exception=", "gpuId="])
    for opt, arg in opts:
        if opt == '--modelDef':
            modelDef = arg
        elif opt == '--modelWeights':
            modelWeights = arg
        elif opt == '--meanImg':
            meanImgPath = arg
        elif opt == '--input':
            input = arg
        elif opt == '--inputPath':
            inputPath = arg
        elif opt == '--outputFrameFeaturePath':
            outputFrameFeaturePath = arg
        elif opt == '--outputAvgFeaturePath':
            outputAvgFeaturePath = arg
        elif opt == '--videoList':
            videoList = arg
        elif opt == '--videoListType':
            videoListType = arg
        elif opt == '--layerNames':
            layerNames = arg
        elif opt == '--exception':
            exceptionVideoList = arg
        elif opt == '--gpuId':
            gpuId = map(int, arg.split(','))

    layerNames = layerNames.split(",")

    for layerName in layerNames:
        if not os.path.exists(os.path.join(outputFrameFeaturePath, layerName.split("/")[0])):
            os.makedirs(os.path.join(outputFrameFeaturePath, layerName.split("/")[0]))
    for layerName in layerNames:
        if not os.path.exists(os.path.join(outputAvgFeaturePath, layerName.split("/")[0])):
            os.makedirs(os.path.join(outputAvgFeaturePath, layerName.split("/")[0]))

    qgpu = multiprocessing.Queue()
    jobs = []
    for g in gpuId:
        qv = multiprocessing.Queue()
        qf = multiprocessing.Queue()
        job = multiprocessing.Process(target=deepworker, args=(qgpu, g, qv, qf))
        jobs.append(job)
        job.start()
        if input == 'video':
            job = multiprocessing.Process(target=videoworker, args=(qv, qf))
        elif videoListType == 'frame':
            job = multiprocessing.Process(target=frameworker, args=(qv, qf))
        else:
            assert False, "Unknown input"
        jobs.append(job)
        job.start()
    if videoListType == 'url':
        ch = open(videoList, 'r')
        for ln in ch.readlines():
            qgpu.put(ln.split('/')[5])
        ch.close()
    elif videoListType == 'checksum':
        ch = open(videoList, 'r')
        for ln in ch.readlines():
            qgpu.put((ln.split(' ')[2]).split('.')[0])
        ch.close()
    elif videoListType == 'list':
        ch = open(videoList, 'r')
        for ln in ch.readlines():
            if ln.endswith('.mp4'):
                qgpu.put(ln[0:-4])
            else:
                qgpu.put(ln)
        ch.close()
    elif videoListType == 'all':
        for ln in os.listdir(inputPath):
            if ln.endswith('.mp4'):
                qgpu.put(ln[0:-4])
    else:
        assert False, "Unknown videoListType"
    for g in gpuId:
        qgpu.put('')
    for job in jobs:
        job.join()
