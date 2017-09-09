#!/bin/sh
#$ -cwd
#$ -l q_node=1
#$ -l h_rt=01:00:00
#$ -o /gs/hs0/tga-crest-deep/shinodaG/hands-on/lstm/Lstm/log/lstmTrain.sh.o
#$ -e /gs/hs0/tga-crest-deep/shinodaG/hands-on/lstm/Lstm/log/lstmTrain.sh.e
. /etc/profile.d/modules.sh
./trainStarter.sh &
wait
