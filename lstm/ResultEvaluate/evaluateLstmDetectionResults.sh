#!/bin/bash

H5_SOFTMAX_DIR=$1
TEST_EVENTDB=$2
TEST_REF=$3
EVENT_ID_OFFSET=$4
IS_H5_INCLUDE_BACKGROUND=$5
OUTPUT_AP_DIR=$6

TEMP_DIR=./temp
mkdir ${TEMP_DIR}

APB=./ap.sh
for H5_SOFTMAX in ${H5_SOFTMAX_DIR}/*.h5
do
	id=`echo ${H5_SOFTMAX##*/} | cut -d'.' -f1 `
	SOFTMAX_CSV=${TEMP_DIR}/${id}_csv
	python ./convertH5SoftmaxToCsv.py ${H5_SOFTMAX} ${TEST_REF} ${SOFTMAX_CSV} ${EVENT_ID_OFFSET} ${IS_H5_INCLUDE_BACKGROUND}
	${APB} ${SOFTMAX_CSV} ${TEST_EVENTDB} ${TEST_REF}
	id=`echo ${H5_SOFTMAX##*/} | cut -d'.' -f1 `
	mv ap.csv ${OUTPUT_AP_DIR}/ap_${id}.csv
done
rm -r ${TEMP_DIR}

