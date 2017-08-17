#!/bin/bash

source /gs/hs0/tga-crest-deep/shinodaG/library/env/boost.sh 

SRC_PATH="./src/*.cpp ./BasicOperations/*.cpp"

DES_PATH=./convertCsvToTxt

CPL=g++

CPL_OPTS="-O2"

LIB="-lboost_system -lboost_filesystem"

BOOST_LIB_PATH=/gs/hs0/tga-crest-deep/shinodaG/library/boost_1_59_0Bin/lib
#echo $PATH

#echo $LD_LIBRARY_PATH

${CPL} ${CPL_OPTS} -o ${DES_PATH} ${SRC_PATH} -L${BOOST_LIB_PATH} ${LIB}

