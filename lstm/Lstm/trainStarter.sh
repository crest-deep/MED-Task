. /work1/t2g-crest-deep/ShinodaLab/library/torch/distro/install/bin/torch-activate

#Txt annotations file path
TRAIN_ANNOTATION_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/txt/Train-7983
#How many sample in the file
TRAIN_SAMPLE_NUM=7983

#Dimension of the input feature
FEAT_DIM=1024
#Maximum number of unrolling steps of Lstm. 
#If the sequence length is longer than 'SEQ_LENGTH_MAX', Lstm only unrolls for the first 'SEQ_LENGTH_MAX' steps
SEQ_LENGTH_MAX=2000
#Output class number
TARGET_CLASS_NUM=21
#Number of hidden units of lstm
#HIDDEN_NUM=128
HIDDEN_NUM=$1

#The directory where the trained models are saved
MODEL_SAVING_DIR=/work1/t2g-crest-deep/ShinodaLab/models/torchModels/${HIDDEN_NUM}/
#After every how many epochs the model should be saved
MODEL_SAVING_STEP=5
#Total trained epoch num
EPOCH_NUM=75
#Batch size
BATCH_SIZE=5
#Learning rate
LEARNING_RATE=0.005
#Learning rate decay
LEARNING_RATE_DECAY=1e-4
#Weight decay
WEIGHT_DECAY=0.005
#Momentum
MOMENTUM=0.9

#GPU ID
#GPU_ID=0
GPU_ID=$2

mkdir ${MODEL_SAVING_DIR}

th lstm_train.lua ${TRAIN_ANNOTATION_PATH} ${TRAIN_SAMPLE_NUM} ${FEAT_DIM} ${SEQ_LENGTH_MAX} ${TARGET_CLASS_NUM} ${HIDDEN_NUM} ${MODEL_SAVING_DIR} ${MODEL_SAVING_STEP} ${EPOCH_NUM} ${BATCH_SIZE} ${LEARNING_RATE} ${LEARNING_RATE_DECAY}  ${WEIGHT_DECAY} ${MOMENTUM} ${GPU_ID}
