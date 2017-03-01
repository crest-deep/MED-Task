
#The directory containing the 'h5' result files to be evaluated, which are output by 'lstm_test'
RESULT_DIR=/work1/t2g-crest-deep/ShinodaLab/result/lstm/256

#The csv annotations
TEST_EVENTDB=/work1/t2g-crest-deep/ShinodaLab/annotations/csv/Kindred14-Test_20140428_EventDB.csv
TEST_REF=/work1/t2g-crest-deep/ShinodaLab/annotations/csv/Kindred14-Test_20140428_Ref.csv

#The directory to store AP (Average Precision) scores
OUTPUT_SCORE_DIR=/work1/t2g-crest-deep/ShinodaLab/result/lstm/apScore256

mkdir ${OUTPUT_SCORE_DIR}

./evaluateLstmDetectionResults.sh ${RESULT_DIR} ${TEST_EVENTDB} ${TEST_REF} ${OUTPUT_SCORE_DIR}
