#!/opt/homebrew/bin/bash

# Define input files and languages
declare -A inputs=(["no"]="no.mp4" ["nl"]="nl.mp4" ["en"]="en.mp4" ["de"]="de.mp4")

# HLS output directory
output_dir="hls_output"
temp_dir="hls_output/temp"
mkdir -p $output_dir

# Master playlist file
master_playlist="$output_dir/master_playlist.m3u8"

# Start the master playlist file
echo "#EXTM3U" > $master_playlist

# Process each input file
for lang in "${!inputs[@]}"; do
    input=${inputs[$lang]}

    # HLS stream output paths
    video_stream_dir="$output_dir/$lang/video"
    audio_stream_dir="$output_dir/$lang/audio"
    temp_video_stream_dir="$temp_dir/$lang/video"
    temp_audio_stream_dir="$temp_dir/$lang/audio"
    mkdir -p $output_dir/$lang $temp_video_stream_dir $temp_audio_stream_dir $video_stream_dir $audio_stream_dir

    # Extract audio/video
    ffmpeg -i $input -an -vcodec copy $temp_video_stream_dir/video_$lang.mp4
    ffmpeg -i $input -vn -acodec copy $temp_audio_stream_dir/audio_$lang.mp4

    # Convert video to HLS (without audio)
    ~/dev/tools/bento4/bin/mp42hls --index-filename $video_stream_dir/stream.m3u8 --segment-filename-template "$video_stream_dir/segment-%d.ts" $temp_video_stream_dir/video_$lang.mp4

    # Convert extracted audio to HLS
   # ~/dev/tools/bento4/bin/mp42hls --index-filename $audio_stream_dir/stream.m3u8 $temp_audio_stream_dir/audio_$lang.aac
    ~/dev/tools/bento4/bin/mp42hls --index-filename $audio_stream_dir/stream.m3u8 --segment-filename-template "$audio_stream_dir/segment-%d.ts" $temp_audio_stream_dir/audio_$lang.mp4

    # Add #EXT-X-MEDIA tag for this audio
    echo "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"audio_$lang\",LANGUAGE=\"$lang\",NAME=\"$lang\",DEFAULT=NO,AUTOSELECT=YES,URI=\"$lang/audio/stream.m3u8\"" >> $master_playlist

    # Add #EXT-X-STREAM-INF tag for this video, referencing the audio
    echo "#EXT-X-STREAM-INF:BANDWIDTH=1280000,CODECS=\"avc1.42e01e,mp4a.40.2\",RESOLUTION=1280x720,AUDIO=\"audio_$lang\"" >> $master_playlist
    echo "$lang/video/stream.m3u8" >> $master_playlist
done

# Set the master playlist name
mv $master_playlist "$output_dir/master_playlist.m3u8"

echo "HLS packaging complete. Master playlist located at $output_dir/master_playlist.m3u8"
