source /usr/apps.sp3/nosupport/gsic/env/boost-1.58.0.sh

#Background Video CSV for Training. The videos are used as negatives for training.
TRAIN_BG_FILE_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/csv/EVENTS-BG_20160701_ClipMD.csv
#Event Related Video CSV for Training. The positive videos are denoted with 'positive', while the negative videos are denoted with 'missing'
TRAIN_EVENT_FILE_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/csv/EVENTS-PS-100Ex_20160701_JudgementMD.csv

#List of videos for testing. The CSV contains the groundtruth for each test video.
TEST_REF_FILE_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/csv/Kindred14-Test_20140428_Ref.csv

#The output path of the training 'txt' annotation file for Lstm
TRAIN_TXT_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/txt/Train-7983
#The output path of the testing 'txt' annotation file for Lstm
TEST_TXT_PATH=/work1/t2g-crest-deep/ShinodaLab/annotations/txt/Test

#Number of directories that contain the features for training and testing
FEATURE_DIR_NUM=6
#The directory paths of the features for training and testing. The paths are split by a space.
FEATURE_DIR_PATH="/work1/t2g-crest-deep/ShinodaLab/feature/LDC2011E41_TEST/perFrameFeature /work1/t2g-crest-deep/ShinodaLab/feature/LDC2012E01/perFrameFeature /work1/t2g-crest-deep/ShinodaLab/feature/LDC2012E110/perFrameFeature /work1/t2g-crest-deep/ShinodaLab/feature/LDC2013E115/perFrameFeature /work1/t2g-crest-deep/ShinodaLab/feature/LDC2013E56/perFrameFeature /work1/t2g-crest-deep/ShinodaLab/feature/LDC2014E16/perFrameFeature"

./convertCsvToTxt ${TRAIN_BG_FILE_PATH} ${TRAIN_EVENT_FILE_PATH} ${TEST_REF_FILE_PATH} ${TRAIN_TXT_PATH} ${TEST_TXT_PATH} ${FEATURE_DIR_NUM} ${FEATURE_DIR_PATH}
