source /gs/hs0/tga-crest-deep/shinodaG/library/env/boost.sh

#Background Video CSV for Training. The videos are used as negatives for training.
TRAIN_BG_FILE_PATH=/gs/hs0/tga-crest-deep/shinodaG/annotations/csv/EVENTS-BG_20160701_ClipMD.csv

#Event Related Video CSV for Training. The positive videos are denoted with 'positive', while the negative videos are denoted with 'missing'
TRAIN_EVENT_FILE_PATH=/gs/hs0/tga-crest-deep/shinodaG/annotations/csv/EVENTS-PS-100Ex_20160701_JudgementMD.csv

#List of videos for testing. The CSV contains the groundtruth for each test video.
TEST_REF_FILE_PATH=/gs/hs0/tga-crest-deep/shinodaG/annotations/csv/Kindred14-Test_20140428_Ref.csv

#The output path of the training 'txt' annotation file for Lstm
TRAIN_TXT_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/Train.txt
#The output path of the testing 'txt' annotation file for Lstm
TEST_TXT_PATH=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/Test.txt

#Number of directories that contain the features for training and testing
FEATURE_DIR_NUM=6
#The directory paths of the features for training and testing. The paths are split by a space.
FEATURE_DIR_PATH="/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2012E01/perFrameFeature /gs/hs0/tga-crest-deep/shinodaG/feature/LDC2013E115/perFrameFeature /gs/hs0/tga-crest-deep/shinodaG/feature/LDC2013E56/perFrameFeature /gs/hs0/tga-crest-deep/shinodaG/feature/LDC2014E16/perFrameFeature /gs/hs0/tga-crest-deep/shinodaG/feature/LDC2011E41_TEST/perFrameFeature /gs/hs0/tga-crest-deep/shinodaG/feature/LDC2012E110/perFrameFeature"

#FirstEventId - eventIdOffset = 1
EVENT_ID_OFFSET=20
#Number of events
EVENT_NUM=20

#If 'IS_OMMIT_BACKGROUND' = 1, all the background videos will be filtered out for both training and test sets
IS_OMMIT_BACKGROUND=1

#If 'NEW_TEST_REF_FILE' is not empty, i.e. \"\", a new test ref file will be created, corresponding to the contents in 'TEST_TXT_PATH'
#If you set 'IS_OMMIT_BACKGROUND' = 1, please set this parameter so that you can correctly evaluate results in the following stages
NEW_TEST_REF_FILE=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/testRef.csv

#convertCsvToTxt
./convertCsvToTxt ${TRAIN_BG_FILE_PATH} ${TRAIN_EVENT_FILE_PATH} ${TEST_REF_FILE_PATH} ${TRAIN_TXT_PATH} ${TEST_TXT_PATH} ${FEATURE_DIR_NUM} ${FEATURE_DIR_PATH} ${EVENT_ID_OFFSET} ${EVENT_NUM} ${IS_OMMIT_BACKGROUND} ${NEW_TEST_REF_FILE}
