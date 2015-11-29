#!/bin/bash

#address of the input file
input="$1"
declare -i tiles=$2**2
filename=$(basename "$input")
extension="${filename##*.}"

#get video duration in seconds/minutes/hours
#~ declare -i duration
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")
duration_formatted=$(ffprobe -v error -show_entries format=duration -sexagesimal -of default=noprint_wrappers=1:nokey=1 "$input")
duration=${duration%.*}

echo "Input file: ${input}" 
echo "Duration (ms): ${duration_formatted}" 
echo "Duration (s): ${duration}s" 
echo "Extension of buffer files: ${extension}"

declare -i segments=$duration/$tiles

echo "Duration of each segment: ${segments}s approx."

echo "Splitting video into tile pieces..."

ffmpeg -i "$input" -acodec copy -f segment -segment_time $segments -vf "scale=190:trunc(ow/a/2)*2",copy -reset_timestamps 1 -an -sn -c:v libx264 buffer%d.$extension
#~ ffmpeg -i "$input" -acodec copy -f segment -segment_time $segments -vf "scale=190:-1",copy -reset_timestamps 1 -an -sn -c:v libx264 buffer%d.$extension #use this one

echo "Done."

echo "Creating mosaic/zoetrope..."

#creating the script

#get width and height of clips

#~ width=$(mediainfo --Inform="Video;%Width%" buffer0.$extension)
#~ height=$(mediainfo --Inform="Video;%Height%" buffer0.$extension)
width=$(ffprobe -v error -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 buffer0.$extension)
height=$(ffprobe -v error -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 buffer0.$extension)

#counters that will be used on the loop

declare -i tiles_loop=$tiles-1
declare -i tiles_pos=$(echo "sqrt ( $tiles )" | bc -l  | sed '/\./ s/\.\{0,1\}0\{1,\}$//' )
declare -i tiles_end=$tiles_pos-1

for ((i=0; i<=$tiles_loop; i++));
	do

		inp="${inp} -i buffer${i}.${extension}"
		spt="${spt} [${i}:v] setpts=PTS-STARTPTS, scale=${width}x${height} [bu${i}];"
		
		declare -i tmp_count1=++$i
		declare -i tmp_count2=$tmp_count1+1
		declare -i bu_count=++$i
		
		declare -i posx=$i%$tiles_pos
		declare -i posy=$i/$tiles_pos
	
		if [ "$posx" -eq 0 ] && [ "$posy" -eq 0 ]
			then
				til="[base][bu0] overlay=shortest=1 [tmp1]; ${til}";
		elif  [ "$posx" -gt 0 ] && [ "$posy" -eq 0 ]
			then
				declare -i tmpvar=$width*$posx;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar} [tmp${tmp_count2}];"
		elif  [ "$posx" -eq 0 ] && [ "$posy" -gt 0 ]
			then
				declare -i tmpvar=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:y=${tmpvar} [tmp${tmp_count2}];"

		elif  [ "$posx" -eq "$posy" ] && [ "$posx" -eq $tiles_end ]
			then
				declare -i tmpvar=$width*$posx;
				declare -i tmpvar2=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar}:y=${tmpvar2}"
		else
				declare -i tmpvar=$width*$posx;
				declare -i tmpvar2=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar}:y=${tmpvar2} [tmp${tmp_count2}];"
		fi
		
		#~ echo "$posx;$posy"
		
	done
	
#~ assemble the statement

declare -i nullbasex=$width*$tiles_pos
declare -i nullbasey=$height*$tiles_pos

nullbase="nullsrc=size="$nullbasex"x"$nullbasey" [base];";
output=$(basename "$input")"-zoetrope"

#~ Still trying to find a good quality setting

ffmpeg $inp  -filter_complex "$nullbase$spt$til" -c:v libvpx -qmin 0 -qmax 50 -b:v 2M -an -sn "$output".webm #good settings
#~ ffmpeg $inp  -filter_complex "$nullbase$spt$til" -c:v libvpx  -qmin 5 -qmax 30  -bufsize 1000k -quality best -b:v 2M  -an -sn "$output".webm #best settings

#~ This will come in handy pretty soon (for obvious reasons)
		#~ rm -rf buffer*

echo "Done."