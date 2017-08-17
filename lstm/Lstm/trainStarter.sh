source /gs/hs0/tga-crest-deep/shinodaG/library/env/torch.sh

#Txt annotations file path
TRAIN_ANNOTATION_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/Train.txt
#Dataset name in Hdf5
DATA_SET_NAME=feature

#Dimension of the input feature
INPUT_DIM=1024
#Output class number
OUTPUT_DIM=20
#Number of hidden units of lstm
HIDDEN_DIM=128

#The directory where the trained models are saved
MODEL_SAVING_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/model/${HIDDEN_DIM}/
mkdir ${MODEL_SAVING_DIR}

#After every how many epochs the model should be saved
MODEL_SAVING_STEP=5
#Total trained epoch num
EPOCH_NUM=80
#Batch size
BATCH_SIZE=128
#Learning rate
LEARNING_RATE=0.005
#Learning rate decay
LEARNING_RATE_DECAY=1e-4
#Weight decay
WEIGHT_DECAY=0.005
#Momentum
MOMENTUM=0.9

#GPU ID
#Index from 1
GPU_ID=$1

th lstm_train.lua ${TRAIN_ANNOTATION_PATH} ${DATA_SET_NAME} ${INPUT_DIM} ${OUTPUT_DIM} ${HIDDEN_DIM} ${MODEL_SAVING_DIR} ${MODEL_SAVING_STEP} ${EPOCH_NUM} ${BATCH_SIZE} ${LEARNING_RATE} ${LEARNING_RATE_DECAY}  ${WEIGHT_DECAY} ${MOMENTUM} ${GPU_ID}
