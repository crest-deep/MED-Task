#!/bin/bash

SRC_PATH="./src/*.cpp ./BasicOperations/*.cpp"

DES_PATH=./convertCsvToTxt

LIB="-lboost_system -lboost_filesystem"

CPL=g++

CPL_OPTS="-O2"

${CPL} ${CPL_OPTS} -o ${DES_PATH} ${SRC_PATH} ${LIB}
