#!/bin/bash

MODEL_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/model/$1

OUTPUT_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/$1_lstmSoftmax
mkdir ${OUTPUT_DIR}

GPU_ID=$2

for MODEL_PATH in ${MODEL_DIR}/*
do
	MODEL_NAME=$(echo ${MODEL_PATH} | sed "s/.*\///")
	OUTPUT_PATH=${OUTPUT_DIR}/${MODEL_NAME}_softmax.h5
	
	./testStarter.sh ${MODEL_PATH} ${OUTPUT_PATH} ${GPU_ID}
	echo "Finish model testing: " ${MODEL_NAME}
done


