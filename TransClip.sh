#!/bin/bash

# Usage Check
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <video file> <secret key>"
    exit 1
fi

# Check for Python 3
if ! command -v python3 &>/dev/null; then
    echo "Python 3 is required to run this script."
    exit 1
fi

# Install necessary Python modules
echo "Checking and installing required Python modules..."
python3 -m pip install --user openai pysrt pydub



# Variables
VIDEO_FILE=$1
SECRET_KEY=$2
VOICE_NAME="onyx"
AUDIO_FILE="original_audio.mp3"
TEMP_DIR="temp_audio_chunks"
OUTPUT_DIR="translated_audio_chunks"

STITCHED_AUDIO="stiched_audio_output.mp3"
FINAL_VIDEO="output_video.mp4"

# Create Temporary and Output Directories
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

# Step 1: Extract Audio
ffmpeg -i "$VIDEO_FILE" -vn -ar 44100 -ac 2 -ab 192k -f mp3 "$AUDIO_FILE"

# Audio Chunking Parameters
BITRATE_BYTES_PER_MS=$((192 * 125 / 1000))
CHUNK_SIZE_BYTES=$((24 * 1024 * 1024))
CHUNK_DURATION_MS=$(($CHUNK_SIZE_BYTES / $BITRATE_BYTES_PER_MS))
CHUNK_DURATION_SEC=$(($CHUNK_DURATION_MS / 1000))

# Step 2: Split Audio
ffmpeg -i "$AUDIO_FILE" -f segment -segment_time $CHUNK_DURATION_SEC -c copy "$TEMP_DIR/chunk%02d.mp3"

# Initialize sequence counter
sequence_number=0

# Process Each Chunk with Python Script
for CHUNK in $TEMP_DIR/*.mp3; do
    echo "RUNNING PYTHON SCRIPT"
    ((sequence_number++))

    # Start timer
    start_time=$(date +%s)

    python3 audio_translate.py "$CHUNK" "$SECRET_KEY" "$VOICE_NAME" "$OUTPUT_DIR" $sequence_number

    # End timer
    end_time=$(date +%s)

    # Calculate and print execution time
    duration=$((end_time - start_time))
    echo "Python script execution time: $duration seconds"    
    echo "DONE"
done



# Step 3: Stitch Translated Audio

num_segments=$(ls -1 "$OUTPUT_DIR"/segment_*.mp3 | wc -l)

if [ "$num_segments" -eq 1 ]; then
    # Only one segment, use it directly
    single_audio_segment=$(ls "$OUTPUT_DIR"/segment_*.mp3)
    echo "Only one audio segment found. Proceeding to combine it with the video."

    # Step 4: Combine Video and Single Audio Segment
    ffmpeg -i "$VIDEO_FILE" -i "$single_audio_segment" -map 0:v -map 1:a -c:v copy -shortest "$FINAL_VIDEO"
else
    # Multiple segments, stitch them together first
    echo "Multiple audio segments found. Proceeding to stitch them."

    # Generate a list of files for ffmpeg to concatenate
    LIST_FILE="list.txt"
    touch "$LIST_FILE"

    # Sort files numerically and append to list file
    for f in $(ls "$OUTPUT_DIR"/segment_*.mp3 | sort -V); do
        echo "file '$f'" >> "$LIST_FILE"
    done

    ffmpeg -f concat -safe 0 -i "$LIST_FILE" -c copy "$STITCHED_AUDIO"

    # Step 4: Combine Video and Stitched Audio
    ffmpeg -i "$VIDEO_FILE" -i "$STITCHED_AUDIO" -map 0:v -map 1:a -c:v copy -shortest "$FINAL_VIDEO"
fi

# Optional Cleanup
rm -rf "$TEMP_DIR"
rm -rf "$OUTPUT_DIR"
rm "$AUDIO_FILE"
rm "$STITCHED_AUDIO"
rm "$LIST_FILE"

echo "Video translation complete. Output file: $FINAL_VIDEO"