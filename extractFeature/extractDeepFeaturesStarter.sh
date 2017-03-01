source /usr/apps.sp3/nosupport/gsic/env/boost-1.58.0.sh
source /usr/apps.sp3/nosupport/gsic/env/caffe-0.13.sh
source /usr/apps.sp3/nosupport/gsic/env/cmake-3.0.2.sh
source /usr/apps.sp3/nosupport/gsic/env/python-2.7.7.sh

#Caffe Model: model proto, model weight, mean img, from which layer the feature is extracted
MODEL_DEF=/work1/t2g-crest-deep/ShinodaLab/models/caffeModels/imageShuffleNet/Bottom_up_13k_deploy.prototxt
MODEL_WEIGHTS=/work1/t2g-crest-deep/ShinodaLab/models/caffeModels/imageShuffleNet/bvlc_googlenet_bottomup_12988_trainval.caffemodel
MEAN_IMG_PATH=/work1/t2g-crest-deep/ShinodaLab/models/caffeModels/imageShuffleNet/ilsvrc_2012_mean.npy
LAYER_NAME=pool5/7x7_s1

#The directory of extracted frames. Choose the frame directory you want to extract features from
#The frame data is located in /work1/t2g-crest-deep/ShinodaLab/frame/
#INPUT_PATH=/work1/t2g-crest-deep/ShinodaLab/frame/LDC2014E16
INPUT_PATH=$1

#The list of urls/checksums of videos provided by TRECVID
#The urls/checksums are located in /work1/t2g-crest-deep/ShinodaLab/frameMeta
#VIDEO_LIST=/work1/t2g-crest-deep/ShinodaLab/frameMeta/LDC2014E16_videoList_checksum.txt
VIDEO_LIST=$2
#"VIDEO_LIST_TYPE" can be "url" or "checksum"
#VIDEO_LIST_TYPE=checksum
VIDEO_LIST_TYPE=$3

#Output diretory of features
#OUTPUT_FEATURE_PATH=/work1/t2g-crest-deep/ShinodaLab/feature/test/LDC2014E16
OUTPUT_FEATURE_PATH=$4
#Output directory of per-frame features
OUTPUT_FRAME_FEATURE_PATH=${OUTPUT_FEATURE_PATH}/perFrameFeature
#Output directory of avg feature over frames per video
OUTPUT_AVG_FEATURE_PATH=${OUTPUT_FEATURE_PATH}/avgFeature
#Output errors about videos during feature extraction
EXCEPTION_VIDEO_LIST=${OUTPUT_FEATURE_PATH}/errorList.txt

#Which gpu to use, indexed from 0
#GPU_ID=0
GPU_ID=$5

mkdir ${OUTPUT_FEATURE_PATH}
mkdir ${OUTPUT_FRAME_FEATURE_PATH}
mkdir ${OUTPUT_AVG_FEATURE_PATH}

python extractDeepFeatures.py --modelDef=${MODEL_DEF} --modelWeights=${MODEL_WEIGHTS} --meanImg=${MEAN_IMG_PATH} --layerName=${LAYER_NAME} --inputPath=${INPUT_PATH} --videoList=${VIDEO_LIST} --videoListType=${VIDEO_LIST_TYPE} --outputFrameFeaturePath=${OUTPUT_FRAME_FEATURE_PATH} --outputAvgFeaturePath=${OUTPUT_AVG_FEATURE_PATH} --exception=${EXCEPTION_VIDEO_LIST} --gpuId=${GPU_ID}
