#!/bin/bash
#$ -cwd
#$ -l f_node=1
#$ -l h_rt=1:00:00
#$ -N eval

EXPID='TokyoTech_MED16_KINDRED_PS_100Ex_SML_DCNN-pool5-STRICTREF_1'
TempOutDir=$TMPDIR'/TempOutDir/'
LIBSVM='/gs/hs0/tga-crest-deep/shinodaG/library/libsvm-3.22/'
IS_LINEAR=0
SVSUFFIX=''
ANNOT_DIR="/gs/hs0/tga-crest-deep/shinodaG/annotations/csv/"
TEST_DATA="Kindred14-Test_20140428"
BG_DATA="EVENTS-BG_20160701"
TRAIN_DATA="EVENTS-PS-100Ex_20160701"

TEST_CLIPMD="${ANNOT_DIR}${TEST_DATA}_ClipMD.csv"
TEST_EVENTDB="${ANNOT_DIR}${TEST_DATA}_EventDB.csv"
TEST_EVENTS=( `sed -e '1d' -e 's/\"//g' ${TEST_EVENTDB} | cut -d',' -f1` )
TEST_REF="${ANNOT_DIR}${TEST_DATA}_Ref.csv"
TEST_SVDIR=( \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2011E41_TEST/avgFeature/" \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2012E110/avgFeature/" \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2013E56/avgFeature/" \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2014E16/avgFeature/" \
)
BG_CLIPMD="${ANNOT_DIR}${BG_DATA}_ClipMD.csv"
TRAIN_JUDGEMENTMD="${ANNOT_DIR}${TRAIN_DATA}_JudgementMD.csv"
TRAIN_SVDIR=( \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2012E01/avgFeature/" \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2013E115/avgFeature/" \
	"/gs/hs0/tga-crest-deep/shinodaG/feature/LDC2011E41_TEST/avgFeature/" \
)

threads=24

function log()
{
	echo `date '+[%Y%m%d-%H%M%S]'` $@
}

trap 'kill -- -$$; exit 1' 1 2 3 15


if [[ ! -d $TempOutDir ]]
then
	mkdir $TempOutDir
fi


if [[ -r ${EXPID} ]]
then
	rm -r $EXPID
	mkdir ${EXPID} 
	cd ${EXPID}
	log 'The directory '${EXPID}' already exists.' | tee -a log
else
	mkdir ${EXPID} 
	cd ${EXPID}
fi


log 'Start experiment '${EXPID} | tee -a log


cat ${TEST_CLIPMD} | cut -d ',' -f 1 | sed -e '1d' -e 's/\"//g' -e 's\HVC\\g' > $TempOutDir/test_clipid.tmp
log 'Generating feature vectors of '`wc -l < $TempOutDir/test_clipid.tmp`' test clips...' | tee -a log
split -l $(((`wc -l < $TempOutDir/test_clipid.tmp` + $threads - 1) / $threads)) $TempOutDir/test_clipid.tmp $TempOutDir/test_clipid.tmp.
pids=()

for file in $TempOutDir/test_clipid.tmp.*
do
	(
		while read i
		do
			printf '0 '
			E=1
			for DIR in ${TEST_SVDIR[@]} #for DIR in $TEST_SVDIR 
			do
				SV=${DIR}'/HVC'${i}${SVSUFFIX}
				if [[ -r $SV ]]
				then
					# Add feature indices to each column
					cat $SV | tr ' ' '\n' | nl -n ln -w 1 -s : | tr '\n' ' '
					E=0
					break
				fi
			done
			if [[ $E -eq 1 ]]
			then
				echo 'HVC'${i}${SVSUFFIX}' doesn'"'"'t exist anywhere.' | tee -a log
				exit 1
			fi
			printf '\n'
		done
	) < $file > $TempOutDir/test.sv.${file##*.} &
	pids+=($!)
done

for pid in ${pids[@]}
do
	wait $pid
	if [[ $? -ne 0 ]]
	then
		exit 1
	fi
done

cat $TempOutDir/test.sv.* > $TempOutDir/test.sv
log 'Generated' | tee -a log


cat ${BG_CLIPMD} | cut -d ',' -f 1 | sed -e '1d' -e 's/\"//g' -e 's\HVC\\g' > $TempOutDir/bg_clipid.tmp
log 'Generating feature vectors of '`wc -l < $TempOutDir/bg_clipid.tmp`' background clips...' | tee -a log
split -l $(((`wc -l < $TempOutDir/bg_clipid.tmp` + $threads - 1) / $threads)) $TempOutDir/bg_clipid.tmp $TempOutDir/bg_clipid.tmp.
pids=()

for file in $TempOutDir/bg_clipid.tmp.*
do
	(
		while read i
		do
			printf -- '-1 '
			E=1
			for DIR in ${TRAIN_SVDIR[@]} #for DIR in $TRAIN_SVDIR 
			do
				SV=${DIR}'/HVC'${i}${SVSUFFIX}
				if [[ -r $SV ]]
				then
					# Add feature indices to each column
					cat $SV | tr ' ' '\n' | nl -n ln -w 1 -s : | tr '\n' ' '
					E=0
					break
				fi
			done
			if [[ $E -eq 1 ]]
			then
				log 'HVC'${i}${SVSUFFIX}' doesn'"'"'t exist anywhere.' | tee -a log
				exit 1
			fi
			printf '\n'
		done
	) < $file > $TempOutDir/bg.sv.${file##*.} &
	pids+=($!)
done

for pid in ${pids[@]}
do
	wait $pid
	if [[ $? -ne 0 ]]
	then
		exit 1
	fi
done

cat $TempOutDir/bg.sv.* > $TempOutDir/bg.sv
log 'Generated' | tee -a log


if [[ ${IS_LINEAR} -eq 0 ]]
then
	SVMKERNEL=2
else
	SVMKERNEL=0
fi

for EVENT in ${TEST_EVENTS[@]} 
do
	(
		log ${EVENT}' start training and testing SVM, detailed log in log_'${EVENT} | tee -a log
		log 'Start training and testing SVM for event '${EVENT} >> log_${EVENT}
		if [[ $EVENT == 'NULL' ]]
		then
			continue
		fi
		
		log 'Generating feature vectors of '`grep ${EVENT} ${TRAIN_JUDGEMENTMD} | wc -l`' training clips...' >> log_${EVENT}
		while read i
		do
			# Label: +1 / -1
			grep -q '\"HVC'${i}'\",\"'${EVENT}'\",\"positive\"' ${TRAIN_JUDGEMENTMD}
			if [[ $? -eq 0 ]]
			then
				printf '+1 '
			else
				printf -- '-1 '
			fi

			E=1
			for DIR in ${TRAIN_SVDIR[@]} #for DIR in $TRAIN_SVDIR 
			do
				SV="$DIR/HVC${i}${SVSUFFIX}"
				if [[ -r $SV ]]
				then
					# Add feature indices to each column
					cat $SV | tr ' ' '\n' | nl -n ln -w 1 -s : | tr '\n' ' '
					E=0
					break
				fi
			done
			if [[ $E -eq 1 ]]
			then
				log "HVC${i}${SVSUFFIX} doesn't exist anywhere." >> log_${EVENT}
				exit 1
			fi
			printf '\n'
		done < <(grep ${EVENT} ${TRAIN_JUDGEMENTMD} | cut -d ',' -f 1 | sed -e '1d' -e 's\"\\g' -e 's\HVC\\g') | cat - $TempOutDir/bg.sv > $TempOutDir/${EVENT}.sv
		log 'Gererated' >> log_${EVENT}

		log 'Training SVM...' >> log_${EVENT}
		${LIBSVM}/svm-train -s 0 -t ${SVMKERNEL} -c 2 -e 0.001 -g 0.00098 -b 1 $TempOutDir/${EVENT}.sv $TempOutDir/${EVENT}.svm >> log_${EVENT}
		log 'Finished' >> log_${EVENT}

		log 'Testing SVM...' >> log_${EVENT}
		${LIBSVM}/svm-predict -b 1 -q $TempOutDir/test.sv $TempOutDir/${EVENT}.svm /dev/stdout | sed -e '1d' | cut -d ' ' -f 2 | paste $TempOutDir/test_clipid.tmp - | sed -e 's/^/\"/g' -e 's/\t/.'${EVENT}'\",\"/g' -e 's/$/\"/g' > $TempOutDir/${EXPID}.detection.${EVENT}.csv.tmp
		log 'Finished' >> log_${EVENT}

		log ${EVENT}' finished' | tee -a log
	) &
done

wait
log 'Finished training and testing SVM, for all of events' | tee -a log


log 'Calculating average precisions...' | tee -a log
echo '\"TrialID\",\"Score\"' > ${EXPID}.detection.csv
cat $TempOutDir/${EXPID}.detection.*.csv.tmp | sort >> ${EXPID}.detection.csv

if [[ -r ${TEST_REF} ]]
then
	../ap.sh ${EXPID}.detection.csv ${TEST_EVENTDB} ${TEST_REF}
fi
log 'Calculated' | tee -a log
log 'mAP: '`tail -n 1 ap.csv | cut -d '"' -f 4` | tee -a log


log 'Finished experimet '${EXPID} | tee -a log
