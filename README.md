# cinegrid
Bash script to create mosaics of video clips, based on ffmpeg.

Main requirements:
------------------

* ffmpeg compiled with the flags --enable-libvpx --enable-libx264

Basic usage:
------------

Make the bash file executable first:
`chmod +x cinegrid_zoetrope.sh`

`./cinegrid_zoetrope.sh input.mp4 [number_of_tiles] [resolution (optional)]`

Example: 
--------

`./cinegrid_zoetrope.sh Blade_Runner_1983.mkv 5 320`

The above example will generate a 5x5 mosaic with tiles 320px wide, the height determined by the source video ratio.

Extra notes: 
------------
* If you don't specify a resolution, the script generates a mosaic with tiles 200px wide.
* The generated mosaic will have the audio and subtitle channels (if they're present) stripped to decrease file size.
* The mosaics are saved in .webm format, in future updates it will be possible to select the output format [webm/mp4/mkv].
* As a rule of thumb, the higher amount of tiles the lower the length of the generated video, and viceversa. 
