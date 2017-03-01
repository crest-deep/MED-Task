import numpy as np
import caffe
import os 
import sys
import getopt
import glob
import h5py

from PIL import ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

#Parameter Parsing
modelDef = ''
modelWeights = ''
meanImgPath = ''
layerName = ''

inputPath = ''
videoList = ''

outputFrameFeaturePath = ''
outputAvgFeaturePath = ''
exceptionVideoList = ''

gpuId = 0

opts, args = getopt.getopt(sys.argv[1:], "", ["modelDef=", "modelWeights=", "meanImg=", 
										"inputPath=", "outputFrameFeaturePath=", "outputAvgFeaturePath=",
										"videoList=", "videoListType=",
										"layerName=", "exception=", "gpuId="])
for opt, arg in opts:
	if opt == '--modelDef':
		modelDef = arg
	elif opt == '--modelWeights':
		modelWeights = arg
	elif opt == '--meanImg':
		meanImgPath = arg
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
	elif opt == '--layerName':
		layerName = arg
	elif opt == '--exception':
		exceptionVideoList = arg
	elif opt == '--gpuId':
		gpuId = int(arg)

#caffe_root = '/work1/t2g-shinoda2011/15M54105/trecvid/caffe-origin/'  
#modelDef = caffe_root + 'examples/_temp/Bottom_up_13k_deploy.prototxt'
#modelWeights = caffe_root + 'examples/_temp/bvlc_googlenet_bottomup_12988_trainval.caffemodel'
#https://staff.fnwi.uva.nl/p.s.m.mettes/
#paper:The ImageNet Shuffle: Reorganized Pre-training for Video Event Detection
'''
inputPath=sys.argv[1]
outputFrameFeaturePath=sys.argv[2]
videoList=sys.argv[3]
layerName=sys.argv[4]#'pool5/7x7_s1'
nolist=sys.argv[5]
'''
#inputPath="/work0/t2g-shinoda2011/15M54105/frames/frame4"
#outputFrameFeaturePath="/work0/t2g-shinoda2011/15M54105/feature/temp"
#videoList="Download_4"
#layerName="pool5/7x7_s1"
#nolist="/work0/t2g-shinoda2011/15M54105/nolist"

if layerName == "pool5/7x7_s1":
	nfeat = 1024
else:
	print layerName
	assert False, "Now only support GoogleNet's pool5/7x7_s1, change [extractDeepFeatures.py] if you would like to use the other deep models"

if not os.path.exists(outputFrameFeaturePath):
	os.makedirs(outputFrameFeaturePath)
if not os.path.exists(outputAvgFeaturePath):
	os.makedirs(outputAvgFeaturePath)
#sys.path.insert(0, caffe_root + 'python')
caffe.set_device(gpuId)  # if we have multiple GPUs, pick the first one
caffe.set_mode_gpu()

print "Loading Deep Model."
net = caffe.Net(modelDef,      # defines the structure of the model
                modelWeights,  # contains the trained weights
                caffe.TEST)     # use test mode (e.g., don't perform dropout)

#mu = np.load(caffe_root + 'python/caffe/imagenet/ilsvrc_2012_mean.npy')
mu = np.load(meanImgPath)
mu = mu.mean(1).mean(1)  # average over pixels to obtain the mean (BGR) pixel values

transformer = caffe.io.Transformer({'data': net.blobs['data'].data.shape})

transformer.set_transpose('data', (2,0,1))  # move image channels to outermost dimension
transformer.set_mean('data', mu)            # subtract the dataset-mean value in each channel
transformer.set_raw_scale('data', 255)      # rescale from [0, 1] to [0, 255]
transformer.set_channel_swap('data', (2,1,0))  # swap channels from RGB to BGR

net.blobs['data'].reshape(1,        # batch size
                          3,         # 3-channel (BGR) images
                          224, 224)  # image size is 224x224
print "Deep Model Loaded."

ch = open(videoList, 'r')
f_lines = ch.readlines()
ch.close()
for ix, line in enumerate(f_lines):
	video = None
	if videoListType == 'url':
		video = line.split('/')[5]
	elif videoListType == 'checksum':
		video = (line.split(' ')[2]).split('.')[0]
	else:
		assert False, "videoListType Unrecognized"

	outFrameFeatureFile = os.path.join(outputFrameFeaturePath, video + ".h5") 
	outAvgFeatureFile = os.path.join(outputAvgFeaturePath, video)
	frames = glob.glob('%s/%s/*.png' %(inputPath, video))	
	featlist = map(os.path.basename, frames)
	temp = [x.split('_')[1].split('.')[0] for x in featlist]
	ids = map(int,temp)
	ids.sort()
	num_frames = len(frames)
	feats = np.zeros((num_frames,nfeat))
	frameBrokenNum = 0
	for i in range(0, num_frames):	       
		imgpath = '%s/%s/%s_%08d.png' %(inputPath, video, video, ids[i])
		print "Processing " + imgpath
		if os.path.getsize(imgpath) != 0:
			try:
				image = caffe.io.load_image(imgpath)
				print "success"
			except:
				print "Fail to Load image: " + imgpath
				frameBrokenNum = frameBrokenNum + 1
				continue
			transformed_image = transformer.preprocess('data', image)
			net.blobs['data'].data[0,...] = transformed_image
			output = net.forward()		
			feats[i] = net.blobs[layerName].data[0].reshape(1,-1)
		else:
			frameBrokenNum = frameBrokenNum + 1
			if not os.path.exists(exceptionVideoList):
				os.mknod(exceptionVideoList)
			with open(exceptionVideoList, 'a') as ll:
				ll.write(video + "," + imgpath + ":size=0\n")
			
	if len(featlist) != 0 and frameBrokenNum < 3:	    
		with h5py.File(outFrameFeatureFile, 'w') as hf:
			hf.create_dataset('feature', data=feats)
		videofeat = feats.sum(axis=0) / len(feats)
		if not os.path.exists(outAvgFeatureFile):
			os.mknod(outAvgFeatureFile)
		with open(outAvgFeatureFile, 'w') as writer:
			videofeat = videofeat.reshape(1,-1)
			np.savetxt(writer, videofeat, fmt='%.8g')
	else:
		if not os.path.exists(exceptionVideoList):
			os.mknod(exceptionVideoList)
		with open(exceptionVideoList, 'a') as ll:
			ll.write(video + "\n")


