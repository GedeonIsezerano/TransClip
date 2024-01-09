#!/usr/bin/env python3

import os
import sys
import openai
import pysrt
import shutil
from pathlib import Path
from pydub import AudioSegment


def main():
    if len(sys.argv) != 6:
        print("Usage: python script.py <audio_file> <secret_key> <voice_name> <output_dir> <sequence_number>")
        sys.exit(1)

    audio_file_path = sys.argv[1]
    secret_key = sys.argv[2]
    voice_name = sys.argv[3]
    output_dir = sys.argv[4]
    sequence_number = sys.argv[5]

    openai.api_key = secret_key

    with open(audio_file_path, "rb") as audio_file:
        # Translate from Korean to English - SRT format
        transcript = openai.audio.translations.create(
            model="whisper-1",
            response_format="srt",
            file=audio_file
        )

    srt_file_path = audio_file_path.replace('.mp3', '.srt')

    with open(srt_file_path, "w") as file:
        file.write(transcript)

    # Load and TTS each segment of the srt
    subs = pysrt.open(srt_file_path)
    audio_files = []

    mp3s_directory = Path.cwd() / "mp3s"
    mp3s_directory.mkdir(exist_ok=True)

    def convert_to_speech(text, index):
        speech_file_path = mp3s_directory / f"segment_{index}.mp3"
        response = openai.audio.speech.create(
            model="tts-1",
            voice=voice_name,
            input=text
        )
        response.stream_to_file(speech_file_path)
        audio_files.append(str(speech_file_path))

    for i, sub in enumerate(subs):
        text = sub.text
        convert_to_speech(text, i)

    # Stitch SRT audio segment into one free-flowing audio
    final_audio = stitch_audio(subs, audio_files)

    # delete the audio segments used
    shutil.rmtree(mp3s_directory)
    print(f"The folder '{mp3s_directory}' has been deleted.")

    # Export the stitched translated audio into one mp3 file
    output_dir_path = Path(output_dir)
    output_dir_path.mkdir(exist_ok=True)

    # Ensure the audio file exists
    if not os.path.exists(audio_file_path):
        print(f"Audio file '{audio_file_path}' not found.")
        sys.exit(1)

    final_audio.export(output_dir_path /
                       f"segment_{sequence_number}.mp3", format="mp3")
    print("Audio export complete.")


def stitch_audio(subtitles, audio_files):
    final_audio = AudioSegment.empty()
    last_end_time = 0

    for index, sub in enumerate(subtitles):
        start_time = sub.start.ordinal  # Start time in milliseconds
        end_time = sub.end.ordinal  # End time in milliseconds

        # Load the audio file for this subtitle
        audio_clip = AudioSegment.from_file(audio_files[index])

        # Calculate silence needed before this clip (if any)
        silence_duration = start_time - last_end_time
        if silence_duration > 0:
            final_audio += AudioSegment.silent(duration=silence_duration)

        # Adjust audio clip duration to fit the subtitle duration
        subtitle_duration = end_time - start_time
        if len(audio_clip) > subtitle_duration:
            audio_clip = audio_clip[:subtitle_duration]
        elif len(audio_clip) < subtitle_duration:
            silence_needed = subtitle_duration - len(audio_clip)
            audio_clip += AudioSegment.silent(duration=silence_needed)

        final_audio += audio_clip
        last_end_time = end_time

    return final_audio


if __name__ == "__main__":
    main()
