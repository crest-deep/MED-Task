#!/bin/bash

source /usr/apps.sp3/nosupport/gsic/env/boost-1.58.0.sh 

SRC_PATH="./src/*.cpp ./BasicOperations/*.cpp"

DES_PATH=./convertCsvToTxt

CPL=g++

CPL_OPTS="-O2"

LIB="-lboost_system -lboost_filesystem"

#echo $PATH

#echo $LD_LIBRARY_PATH

${CPL} ${CPL_OPTS} -o ${DES_PATH} ${SRC_PATH} ${LIB}

