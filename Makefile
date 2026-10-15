# Drive the CMake build. Objects and binaries land in build/.
BUILD ?= build
CMAKE ?= cmake

.PHONY: all test fixtures clean

all: $(BUILD)/CMakeCache.txt
	$(CMAKE) --build $(BUILD) --target merlin --parallel

$(BUILD)/CMakeCache.txt: CMakeLists.txt
	$(CMAKE) -S . -B $(BUILD)

test fixtures: $(BUILD)/CMakeCache.txt
	$(CMAKE) --build $(BUILD) --target $@ --parallel

clean:
	@if [ -f $(BUILD)/CMakeCache.txt ]; then $(CMAKE) --build $(BUILD) --target clean; fi
	rm -rf $(BUILD)
