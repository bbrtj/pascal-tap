FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= -v0web -Sic -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)
TEST_RUNNER ?= prove
TEST_VERBOSE ?= 0
TEST_FLAG ?= $$(if [ $(TEST_VERBOSE) == 1 ]; then echo "--verbose"; fi)

build: prepare
	for file in t/*.t.pas; do $(FPC) $(FPC_FLAGS) -Fut/src $${file}; done

test: build
	$(TEST_RUNNER) build $(TEST_FLAG)

examples: prepare
	for file in ex/*.pas; do $(FPC) $(FPC_FLAGS) $${file}; done

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

