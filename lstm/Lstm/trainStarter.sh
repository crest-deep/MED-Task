source /gs/hs0/tga-crest-deep/shinodaG/library/env/torch.sh

#Txt annotations file path
TRAIN_ANNOTATION_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/Train.txt
#Dataset name in Hdf5
DATA_SET_NAME=feature

#Dimension of the input feature
INPUT_DIM=1024
#Output class number
OUTPUT_DIM=21
#Number of hidden units of lstm
HIDDEN_DIM=256

#After every how many epochs the model should be saved
MODEL_SAVING_STEP=3
#Total trained epoch num
EPOCH_NUM=40
#Batch size
BATCH_SIZE=128
#Learning rate
LEARNING_RATE=0.001
#Learning rate decay
LEARNING_RATE_DECAY=1e-4
#Weight decay
WEIGHT_DECAY=0.01
#Gradient clipping threshold
GRADIENT_CLIP=5

#GPU ID
#Index from 1
GPU_ID=1

#The directory where the trained models are saved
MODEL_SAVING_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/model/${HIDDEN_DIM}/
mkdir ${MODEL_SAVING_DIR}

th lstm_train.lua ${TRAIN_ANNOTATION_PATH} ${DATA_SET_NAME} ${INPUT_DIM} ${OUTPUT_DIM} ${HIDDEN_DIM} ${MODEL_SAVING_DIR} ${MODEL_SAVING_STEP} ${EPOCH_NUM} ${BATCH_SIZE} ${LEARNING_RATE} ${LEARNING_RATE_DECAY}  ${WEIGHT_DECAY} ${GRADIENT_CLIP} ${GPU_ID}
