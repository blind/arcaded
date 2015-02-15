
MESS_OPTIONS:= -cfg_directory tools/mess/cfg -nvram_directory tools/mess/nvram

OUT=md_input_test.smd


VASM_FLAGS=-quiet -Fbin

.PHONY: all clean test debug


all: build $(OUT)

build:
	@mkdir -p build

$(OUT): src/start.s
	vasmm68k_mot $(VASM_FLAGS) -Ibuild -Isrc -Fbin -o $(OUT) src/start.s 
	@python tools/gen_checksum.py $(OUT)

clean:
	rm -f $(OUT) build/*

test: $(OUT)
	@mess64 genesis -cart $(OUT) $(MESS_OPTIONS) -waitvsync

teste: $(OUT)
	@mess64 megadriv -cart $(OUT) $(MESS_OPTIONS)

debug: $(OUT)
	@mess64 megadriv -cart $(OUT) $(MESS_OPTIONS) -debug

