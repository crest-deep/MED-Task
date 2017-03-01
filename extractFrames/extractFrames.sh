#!/bin/bash

videodir='' # directory of videos
outdir='' # directory of frames
# list='' # optional list of videos (each line contains a file name of a video e.g. 000001.mp4)

# create outdir if missing
if [ ! -d $outdir ]
then
	mkdir $outdir
fi

echo 'start extraction'
date '+%Y.%m.%d-%k:%M:%S-%N'

# list files and process
if [ -r $list ]
then
	cat $list
else
	ls -U $videodir
fi | grep '\.mp4$' | while read videoname
do
	video=$videodir/$videoname

	# check video is not empty
	# sometimes video is missing in original data
	if [ -s $video ]
	then
		mkdir -m 755 $outdir/${videoname%.*}

		# obtain floor of fps
		fps=`ffprobe $video 2>&1 | grep -o '[0-9.]\+ fps' | sed -e 's/\..*$//g'`

		# extract frames
		ffmpeg -i $video -vf trim=start_frame=1,framestep=`expr $fps \* 2` -loglevel error $outdir/${videoname%.*}/${videoname%.*}_%08d.png
	fi
done
echo 'finished extraction'
date '+%Y.%m.%d-%k:%M:%S-%N'
