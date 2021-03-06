. /etc/profile.d/modules.sh
module load python-extension/2.7

#The directory containing the 'h5' result files to be evaluated, which are output by 'lstm_test'
H5_SOFTMAX_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/softmax/256_lstmSoftmax

#The csv annotations
TEST_EVENTDB=/gs/hs0/tga-crest-deep/shinodaG/annotations/csv/Kindred14-Test_20140428_EventDB.csv
TEST_REF=/gs/hs0/tga-crest-deep/shinodaG/hands-on/data/annotations/txt/testRef.csv

#EVENT_ID_OFFSET - firstEventId = 0
EVENT_ID_OFFSET=21
#If the softmax in 'h5' does not contain 'background', set to 0, otherwise set to 1
IS_H5_INCLUDE_BACKGROUND=1

#The directory to store mAP (mean Average Precision) scores
OUTPUT_AP_DIR=/gs/hs0/tga-crest-deep/shinodaG/hands-on/ap/lstmApScores_256
mkdir ${OUTPUT_AP_DIR}

./evaluateLstmDetectionResults.sh ${H5_SOFTMAX_DIR} ${TEST_EVENTDB} ${TEST_REF} ${EVENT_ID_OFFSET} ${IS_H5_INCLUDE_BACKGROUND} ${OUTPUT_AP_DIR}
