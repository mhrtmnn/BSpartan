AUDIO       := audio.wav
OUTPUT_PATH := output.raw
HEADER_PATH := ../bram_init.mem

# Audio Config
CHANNELS    := 1
SAMPLE_RATE := 11025
CODEC       := s16le

all:
	ffmpeg -i $(AUDIO) -f $(CODEC) -acodec pcm_$(CODEC) -ac $(CHANNELS) -ar $(SAMPLE_RATE) $(OUTPUT_PATH) -y
	python3 ./converter.py $(OUTPUT_PATH) $(HEADER_PATH)

vlc:
	cvlc --demux=rawaud --rawaud-channels $(CHANNELS) --rawaud-samplerate $(SAMPLE_RATE) $(OUTPUT_PATH)
