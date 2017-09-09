source /gs/hs0/tga-crest-deep/shinodaG/library/env/torch.sh

#Txt annotations file path
TEST_ANNOTATION_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/Test.txt
#Dataset name in Hdf5
DATA_SET_NAME=feature

#The model path
#MODEL_PATH=/work1/t2g-crest-deep/ShinodaLab/models/torchModels/256/model_100ex_batch5_unit256_epoch45
MODEL_PATH=$1
#Batch size
BATCH_SIZE=256

#Detection output path
OUTPUT_PATH=$2

#GPU to use
#Index from 1
GPU_ID=$3


th lstm_test.lua ${TEST_ANNOTATION_PATH} ${DATA_SET_NAME} ${MODEL_PATH} ${BATCH_SIZE} ${OUTPUT_PATH} ${GPU_ID}
