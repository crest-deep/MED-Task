#!/bin/bash

if [[ ! -z ${PBS_O_WORKDIR} ]]
then
	cd ${PBS_O_WORKDIR}
fi

videodir='/work1/t2g-crest-deep/ShinodaLab/video/LDC2013E56' # directory of videos
outdir='' # directory of frames
# list='' # optional list of videos (each line contains a file name of a video e.g. 000001.mp4)
ffdir='/work1/t2g-crest-deep/ShinodaLab/library/ffmpeg-3.2.4/bin/' # optional path of ffmpeg and ffprobe executable, not required if those executables can be found in PATH
threads=8

# create outdir if missing
if [[ ! -d $outdir ]]
then
	mkdir $outdir
fi

echo `date '+[%Y%m%d-%H%M%S]'`' start extraction'

tmpfile=`mktemp`
# list files and process
if [[ -z $list ]]
then
	ls -U $videodir
else
	cat $list
fi | grep '\.mp4$' > $tmpfile

split -l $(((`wc -l < $tmpfile` + $threads - 1) / $threads)) $tmpfile $tmpfile.

rm $tmpfile

for file in $tmpfile.*
do
	(
		while read videoname
		do
			video=$videodir/$videoname

			# check video is not empty
			# sometimes video is missing in original data
			if [[ ! -s $video ]]
			then
				echo ${videoname%.*}' has no data, skipping'
				continue
			fi
			if [[ -d $outdir/${videoname%.*} ]]
			then
				echo ${videoname%.*}' already exists, skipping'
				continue
			fi
			mkdir $outdir/${videoname%.*}

			# obtain floor of fps and extract frames
			${ffdir}/ffmpeg -i $video -vf trim=start_frame=1,framestep=$((`${ffdir}/ffprobe $video 2>&1 | grep -o '[0-9.]\+ fps' | sed -e 's/[\. ].*$//g'` * 2)) -loglevel error -nostdin $outdir/${videoname%.*}/${videoname%.*}_%08d.png 2>&1 > /dev/null | sed -e 's/^/    ['${videoname%.*}'] /g' >&2

			if [[ $? = 0 ]]
			then
				echo ${videoname%.*}' processed'
			else
				echo 'error when processing '${videoname%.*}
			fi
		done
	) < $file &

	rm $file
done

wait

echo `date '+[%Y%m%d-%H%M%S]'`' finished extraction'
