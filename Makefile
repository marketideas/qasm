# Drive the CMake build. Objects land in build/release and build/debug.
# Release executables are copied to bin/. Debug executables are copied to bin/debug/.
BUILD_RELEASE ?= build/release
BUILD_DEBUG ?= build/debug
CMAKE ?= cmake

.PHONY: all release debug test fixtures clean boot

all: release debug

release: $(BUILD_RELEASE)/CMakeCache.txt
	$(CMAKE) --build $(BUILD_RELEASE) --target qasm --target qlink --target makeBin --target qomf --target qpro --parallel

debug: $(BUILD_DEBUG)/CMakeCache.txt
	$(CMAKE) --build $(BUILD_DEBUG) --target qasm --target qlink --target makeBin --target qomf --target qpro --parallel

$(BUILD_RELEASE)/CMakeCache.txt: CMakeLists.txt
	$(CMAKE) -S . -B $(BUILD_RELEASE) -DCMAKE_BUILD_TYPE=Release
	touch $(BUILD_RELEASE)/CMakeCache.txt

$(BUILD_DEBUG)/CMakeCache.txt: CMakeLists.txt
	$(CMAKE) -S . -B $(BUILD_DEBUG) -DCMAKE_BUILD_TYPE=Debug
	touch $(BUILD_DEBUG)/CMakeCache.txt

test fixtures: $(BUILD_RELEASE)/CMakeCache.txt
	$(CMAKE) --build $(BUILD_RELEASE) --target $@ --parallel

# Remove the disk and assemble it again. The image is bin/boot.2mg.
boot: $(BUILD_RELEASE)/CMakeCache.txt
	rm -f bin/boot.2mg bin/PRODOS bin/BASIC.SYSTEM
	rm -rf build/boot $(BUILD_RELEASE)/boot
	$(CMAKE) --build $(BUILD_RELEASE) --target boot.2mg --parallel

clean:
	@if [ -f $(BUILD_RELEASE)/CMakeCache.txt ]; then $(CMAKE) --build $(BUILD_RELEASE) --target clean; fi
	rm -rf build
	rm -f bin/qasm bin/qlink bin/makeBin bin/qomf bin/qpro bin/test_qasm bin/test_qlink bin/test_makebin bin/test_qomf bin/test_qpro
	rm -f bin/debug/qasm bin/debug/qlink bin/debug/makeBin bin/debug/qomf bin/debug/qpro bin/debug/test_qasm bin/debug/test_qlink bin/debug/test_makebin bin/debug/test_qomf bin/debug/test_qpro
	rm -f bin/boot.2mg bin/PRODOS bin/BASIC.SYSTEM
	rm -f bin/debug/boot.2mg bin/debug/PRODOS bin/debug/BASIC.SYSTEM
