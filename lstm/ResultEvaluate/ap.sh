#!/bin/bash

SYSCSV=$1  # "000069.E021","0.00731022" ...
EVENTDB=$2 # "E021","Attempting_a_bike_trick" ...
REF=$3     # "000069.E021","n" ...

cat ${EVENTDB} | sed -e '1d' -e 's/\"//g' | cut -d',' -f1 | while read EVENT
do
    if [ $EVENT == 'NULL' ]
    then
    	continue
    fi

    grep '\"[0-9]\+\.'${EVENT}'\"' ${SYSCSV} | sort | sed -e 's/\"//g' > ${EVENT}.det
    grep '\"[0-9]\+\.'${EVENT}'\"' ${REF} | sort | sed -e 's/\"//g' > ${EVENT}.ref
    # 000069.E021,0.00731022,n ...          sort by score            calculate average precision
    join -t ',' ${EVENT}.det ${EVENT}.ref | sort -gr -k 2,2 -t ',' | awk -F ',' '$3=="y"{ap+=++right/NR}END{print "\"'${EVENT}'\",\"" ap/right "\""}' >> ap.csv
    rm ${EVENT}.det ${EVENT}.ref
done

# calculate mean average precision
cat ap.csv | sed -e 's/\"//g' | awk -F ',' '{sum+=$2}END{print "\"Mean\",\"" sum/NR "\""}' >> ap.csv


