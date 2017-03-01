. /work1/t2g-crest-deep/ShinodaLab/library/torch/distro/install/bin/torch-activate

#Txt annotations file path
TEST_ANNOTATION_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/txt/Test
#How many sample in the file
TEST_SAMPLE_NUM=12632

#Dimension of the input feature
FEAT_DIM=1024
#Maximum number of unrolling steps of Lstm. 
#If the sequence length is longer than 'SEQ_LENGTH_MAX', Lstm only unrolls for the first 'SEQ_LENGTH_MAX' steps
SEQ_LENGTH_MAX=2000
#Output class number
TARGET_CLASS_NUM=21

#The model path
#MODEL_PATH=/work1/t2g-crest-deep/ShinodaLab/models/torchModels/256/model_100ex_batch5_unit256_epoch45
MODEL_PATH=$1
#Batch size
BATCH_SIZE=4

#Detection output path
#OUTPUT_PATH=/work1/t2g-crest-deep/ShinodaLab/result/lstm/results.h5
OUTPUT_PATH=$2

#GPU to use
GPU_ID=$3
#GPU_ID=0

th lstm_test.lua ${TEST_ANNOTATION_PATH} ${TEST_SAMPLE_NUM} ${FEAT_DIM} ${SEQ_LENGTH_MAX} ${TARGET_CLASS_NUM} ${MODEL_PATH} ${BATCH_SIZE} ${OUTPUT_PATH} ${GPU_ID}
