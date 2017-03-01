#!/bin/bash

RESULT_DIR=$1
TEST_EVENTDB=$2
TEST_REF=$3
OUTPUT_SCORE_DIR=$4

TEMP_DIR=./temp
mkdir ${TEMP_DIR}

TARGET_CLASS_NUM=20

APB=./ap.sh
for OUTFILE in ${RESULT_DIR}/*.h5
do
	echo ${OUTFILE}
	id=`echo ${OUTFILE##*/} | cut -d'.' -f1 `
	OUTFILE_CSV=${TEMP_DIR}/${id}_csv
    python ./hdf5ToList.py ${OUTFILE} ${TEST_REF} ${OUTFILE_CSV} ${TARGET_CLASS_NUM}
    ${APB} ${OUTFILE_CSV} ${TEST_EVENTDB} ${TEST_REF}
    id=`echo ${OUTFILE##*/} | cut -d'.' -f1 `
	mv ap.csv ${OUTPUT_SCORE_DIR}/ap_${id}.csv
done
rm -r ${TEMP_DIR}

