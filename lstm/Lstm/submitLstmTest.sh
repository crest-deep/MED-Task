#!/bin/sh
#$ -cwd
#$ -l q_node=1
#$ -l h_rt=00:20:00
#$ -o /gs/hs0/tga-crest-deep/shinodaG/hands-on/lstm/Lstm/log/lstmTest.sh.o
#$ -e /gs/hs0/tga-crest-deep/shinodaG/hands-on/lstm/Lstm/log/lstmTest.sh.e
. /etc/profile.d/modules.sh
./testStarterBatch.sh &
wait
