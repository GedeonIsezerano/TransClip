# Video Translation Tool

This tool is designed to translate videos in various languages into English, utilizing ffmpeg, OpenAI's Text-to-Speech (TTS), and Whisper APIs.

## Overview
The tool works by extracting audio from a video file, splitting it into manageable chunks, and then using the Whisper API for translation and OpenAI's TTS to convert the translated text back into audio. Finally, it stitches the translated audio segments together and combines them with the original video, producing a video with the audio translated into English.

## Requirements
ffmpeg: A powerful multimedia processing tool.
openai: OpenAI's Python library, required for TTS.
whisper: API for audio translation.
Python 3 and necessary Python libraries.

** All package installations are done using pip within the bash script
## Usage
### Split Audio from Video:
Extract the audio from the video file into chunks that can be processed by the Whisper API.

### Translate and Convert Audio:
Feed the audio chunks into a Python script (audio_translate.py) that utilizes the Whisper API to translate the audio. The script then uses OpenAI's TTS API to convert the translated SRT (subtitles) into audio.

### Stitch Translated Audios:
Use ffmpeg to stitch the translated audio segments into one continuous audio file.

### Combine Video with Translated Audio:
Merge the video with the newly translated stitched audio using the following command:

```
ffmpeg -i original_video.mp4 -i stitched_audio_output.mp3 -map 0:v -map 1:a -c:v copy -shortest translated_video.mp4
```
Script Execution
Run the provided Bash script (TransClip.sh) with the video file, open_ai api key, as arguments:

```
./TransClip.sh video_file.mp4  xxxxx
```
This script automates the steps mentioned above and produces a video file with the audio translated into English.
** The execution time depends on the size of video being translated

## Notes
The script requires an OpenAI API key in the script for TTS to work.
The translated video will use an ai generated voice.
Currently the script only translates videos to english.


