#address of the input file
input="$1"
declare -i tiles
tiles=$2**2
filename=$(basename "$input")
extension="${filename##*.}"

#get video duration in seconds/miliseconds
declare -i duration
duration=$(mediainfo --Inform="Video;%Duration%" "$input")/1000

echo "Input file: ${input}" 
echo "Duration (s): ${duration}s" 
echo "Duration (ms): $(mediainfo --Inform="Video;%Duration%" "$input")ms" 
echo "Extension of buffer files: ${extension}"

#~ tiles=100

declare -i segments
#~ segments=$((($duration/$tiles) + ($duration % $tiles > 0)))
segments=$duration/$tiles

echo "Duration of each segment: ${segments}s approx."

echo "Splitting WebM's..."

#~ ffmpeg -i "$input" -acodec copy -f segment -segment_time $segments -vf scale=192:-1,copy -reset_timestamps 1 -map 0 -an -sn -c:v libx264 buffer%d.$extension #use this one
ffmpeg -i "$input" -acodec copy -f segment -segment_time $segments -vf scale=192:-1,copy -reset_timestamps 1 -an -sn -c:v libx264 buffer%d.$extension #use this one
#~ ffmpeg -i "$input" -acodec copy -f segment -segment_time $segments -vf scale='192:trunc(ow/a/2)*2',copy -reset_timestamps 1 -map 0 -b:v 1500K -crf 20 -an buffer%d.$extension

echo "Done."

echo "Creating mosaic/zoetrope..."

#creating the script

#get width and height of clips

width=$(mediainfo --Inform="Video;%Width%" buffer0.$extension)
height=$(mediainfo --Inform="Video;%Height%" buffer0.$extension)
declare -i tmp_count1
declare -i tmp_count2
declare -i bu_count
declare -i posx
declare -i posy
declare -i tmpvar #for calculations in the loop
declare -i tmpvar2 #for calculations in the loop

#counters that will be used on the loop
declare -i tiles_loop
declare -i tiles_pos
declare -i tiles_end

tiles_loop=$tiles-1
tiles_pos=$(echo "sqrt ( $tiles )" | bc -l  | sed '/\./ s/\.\{0,1\}0\{1,\}$//' )
tiles_end=$tiles_pos-1

echo $tiles_pos

#~ for i in {0..99}
for ((i=0; i<=$tiles_loop; i++));
	do
		#~ inp="${inp} -i buffer${i}.webm"
		#~ inp="${inp} -i buffer${i}.mp4"
		inp="${inp} -i buffer${i}.${extension}"
		
		spt="${spt} [${i}:v] setpts=PTS-STARTPTS, scale=${width}x${height} [bu${i}];"
		
		tmp_count1=++$i
		tmp_count2=$tmp_count1+1
		bu_count=++$i
		
		#~ posx=$i%10
		#~ posy=$i/10
		posx=$i%$tiles_pos
		posy=$i/$tiles_pos
	
		if [ "$posx" -eq 0 ] && [ "$posy" -eq 0 ]
			then
				til="[base][bu0] overlay=shortest=1 [tmp1]; ${til}";
		elif  [ "$posx" -gt 0 ] && [ "$posy" -eq 0 ]
			then
				tmpvar=$width*$posx;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar} [tmp${tmp_count2}];"
		elif  [ "$posx" -eq 0 ] && [ "$posy" -gt 0 ]
			then
				tmpvar=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:y=${tmpvar} [tmp${tmp_count2}];"
		#~ elif  [ "$posx" -eq "$posy" ] && [ "$posx" -eq 9 ]
		elif  [ "$posx" -eq "$posy" ] && [ "$posx" -eq $tiles_end ]
			then
				tmpvar=$width*$posx;
				tmpvar2=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar}:y=${tmpvar2}"
		else
				tmpvar=$width*$posx;
				tmpvar2=$height*$posy;
				til="${til}[tmp${tmp_count1}][bu${bu_count}] overlay=shortest=1:x=${tmpvar}:y=${tmpvar2} [tmp${tmp_count2}];"
		fi
		
		#~ echo "$posx;$posy"
		
	done
	
#~ assemble the statement

declare -i nullbasex
declare -i nullbasey
#~ nullbasex=$width*10
#~ nullbasey=$height*10
nullbasex=$width*$tiles_pos
nullbasey=$height*$tiles_pos

nullbase="nullsrc=size="$nullbasex"x"$nullbasey" [base];";
output=$(basename "$input")"-zoetrope"

ffmpeg $inp  -filter_complex "$nullbase$spt$til" -c:v libvpx -crf 5 -bufsize 1000k -quality best -b:v 2M  -an -sn "$output".webm #good settings

#~ ffmpeg $inp  -filter_complex "$nullbase$spt$til" -c:v libvpx  -qmin 5 -qmax 30  -bufsize 1000k -quality best -b:v 2M  -an -sn "$output".webm #best settings




#~ if [ $del == "-del" ]
	#~ then
		#~ rm -rf buffer*
#~ fi

echo "Done."