FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= -v0web -Sic -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)
O_LEVEL ?= 1

build: prepare
	$(FPC) $(FPC_FLAGS) -Fut/src -O$(O_LEVEL) t/*.pas

test: build
	prove build

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

