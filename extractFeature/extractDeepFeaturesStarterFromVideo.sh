#!/bin/sh
#$ -cwd
#$ -l f_node=1
#$ -l h_rt=0:30:00
#$ -N feature

. /etc/profile.d/modules.sh
module load python-extension/2.7

pip install --user sk-video

#Caffe Model: model proto, model weight, mean img, from which layer the feature is extracted
MODEL_DEF=/gs/hs0/tga-crest-deep/shinodaG/models/caffeModels/imageShuffleNet/Bottom_up_13k_deploy.prototxt
MODEL_WEIGHTS=/gs/hs0/tga-crest-deep/shinodaG/models/caffeModels/imageShuffleNet/bvlc_googlenet_bottomup_12988_trainval.caffemodel
MEAN_IMG_PATH=/gs/hs0/tga-crest-deep/shinodaG/models/caffeModels/imageShuffleNet/ilsvrc_2012_mean.npy
#You can specify multiple layers. Separate with ","
LAYER_NAMES=pool5/7x7_s1

#The type of the input: video or frame.
INPUT=video

#The directory of videos or extracted frames. Choose the frame directory you want to extract features from
#The frame data is located in /work1/t2g-crest-deep/ShinodaLab/frame/
#INPUT_PATH=/work1/t2g-crest-deep/ShinodaLab/frame/LDC2014E16
#INPUT_PATH=$1
INPUT_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/video

#The list of urls/checksums of videos provided by TRECVID
#The urls/checksums are located in /work1/t2g-crest-deep/ShinodaLab/frameMeta
#VIDEO_LIST=/work1/t2g-crest-deep/ShinodaLab/frameMeta/LDC2014E16_videoList_checksum.txt
#VIDEO_LIST=$2
VIDEO_LIST=
#"VIDEO_LIST_TYPE" can be "url" or "checksum", or "all"
#VIDEO_LIST_TYPE=checksum
#VIDEO_LIST_TYPE=$3
VIDEO_LIST_TYPE=all

#Output diretory of features
#OUTPUT_FEATURE_PATH=/work1/t2g-crest-deep/ShinodaLab/feature/test/LDC2014E16
#OUTPUT_FEATURE_PATH=$4
#OUTPUT_FEATURE_PATH=/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2014E16
OUTPUT_FEATURE_PATH=/gs/hs0/tga-crest-deep/$USER/feature
#Output directory of per-frame features
OUTPUT_FRAME_FEATURE_PATH=${OUTPUT_FEATURE_PATH}/perFrameFeature
#Output directory of avg feature over frames per video
OUTPUT_AVG_FEATURE_PATH=${OUTPUT_FEATURE_PATH}/avgFeature
#Output errors about videos during feature extraction
EXCEPTION_VIDEO_LIST=${OUTPUT_FEATURE_PATH}/errorList.txt

#Which gpu to use, indexed from 0
#GPU_ID=0
#GPU_ID=$5
GPU_ID=0,1,2,3

FFMPEG_PATH=/gs/hs0/tga-crest-deep/shinodaG/library/ffmpeg/bin/

date

MPLBACKEND=Agg PATH=$FFMPEG_PATH:$PATH python extractDeepFeaturesFromVideo.py --modelDef=${MODEL_DEF} --modelWeights=${MODEL_WEIGHTS} --meanImg=${MEAN_IMG_PATH} --layerNames=${LAYER_NAMES} --input=${INPUT} --inputPath=${INPUT_PATH} --videoList=${VIDEO_LIST} --videoListType=${VIDEO_LIST_TYPE} --outputFrameFeaturePath=${OUTPUT_FRAME_FEATURE_PATH} --outputAvgFeaturePath=${OUTPUT_AVG_FEATURE_PATH} --exception=${EXCEPTION_VIDEO_LIST} --gpuId=${GPU_ID}

date
