cmake_minimum_required(VERSION 3.16)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type: Debug or Release" FORCE)
endif()
if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release)$")
  message(FATAL_ERROR "CMAKE_BUILD_TYPE must be Debug or Release")
endif()
project(qasm LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra)
  set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g" CACHE STRING "Debug compile flags" FORCE)
  set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG" CACHE STRING "Release compile flags" FORCE)
endif()

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# major.minor.patch for each program. The build number is not set here.
# Debug and release each add one per build, stored in bin/.<name>.<config>.build.
set(QASM_VERSION_MAJOR 0)
set(QASM_VERSION_MINOR 1)
set(QASM_VERSION_PATCH 0)
set(QLINK_VERSION_MAJOR 0)
set(QLINK_VERSION_MINOR 1)
set(QLINK_VERSION_PATCH 0)
set(MAKEBIN_VERSION_MAJOR 0)
set(MAKEBIN_VERSION_MINOR 1)
set(MAKEBIN_VERSION_PATCH 0)
set(QOMF_VERSION_MAJOR 0)
set(QOMF_VERSION_MINOR 1)
set(QOMF_VERSION_PATCH 0)
set(QPRO_VERSION_MAJOR 0)
set(QPRO_VERSION_MINOR 1)
set(QPRO_VERSION_PATCH 0)

set(BIN_DIR ${CMAKE_SOURCE_DIR}/bin)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(VERSION_CONFIG debug)
  set(BIN_OUT ${BIN_DIR}/debug)
else()
  set(VERSION_CONFIG release)
  set(BIN_OUT ${BIN_DIR})
endif()

# Write <name>_version.cpp and a trigger file. The trigger is removed after
# the link, so the next build of this program and configuration increments.
function(add_version_source target name major minor patch)
  set(cpp ${CMAKE_BINARY_DIR}/generated/${name}_version.cpp)
  set(trigger ${CMAKE_BINARY_DIR}/generated/${name}_version.trigger)
  add_custom_command(
    OUTPUT ${cpp} ${trigger}
    COMMAND ${CMAKE_COMMAND}
            -DNAME=${name}
            -DMAJOR=${major}
            -DMINOR=${minor}
            -DPATCH=${patch}
            -DCONFIG=${VERSION_CONFIG}
            -DCOUNTER=${BIN_DIR}/.${name}.${VERSION_CONFIG}.build
            -DOUT=${cpp}
            -DTRIGGER=${trigger}
            -P ${CMAKE_SOURCE_DIR}/cmake/bump_build.cmake
    DEPENDS ${CMAKE_SOURCE_DIR}/cmake/bump_build.cmake
    COMMENT "Increment ${name} ${VERSION_CONFIG} build number"
    VERBATIM
  )
  target_sources(${target} PRIVATE ${cpp})
  set_source_files_properties(${cpp} PROPERTIES GENERATED TRUE)
  set(${name}_VERSION_TRIGGER ${trigger} PARENT_SCOPE)
endfunction()

# Copy the linked executable into the untracked bin/ directory.
# Release lands in bin/. Debug lands in bin/debug/.
function(copy_to_bin target)
  cmake_parse_arguments(ARG "" "TRIGGER" "" ${ARGN})
  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BIN_OUT}
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${target}> ${BIN_OUT}/$<TARGET_FILE_NAME:${target}>
    VERBATIM
  )
  if(ARG_TRIGGER)
    add_custom_command(TARGET ${target} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E rm -f ${ARG_TRIGGER}
      VERBATIM
    )
  endif()
endfunction()

set(QASM_LIB_SOURCES
  src/qasm/util.cpp
  src/qasm/parse.cpp
  src/qasm/expr.cpp
  src/qasm/opcode.cpp
  src/qasm/assemble.cpp
  src/qasm/compile.cpp
  src/qasm/front_merlin.cpp
  src/qasm/front_orca.cpp
  src/qasm/front_lisa.cpp
  src/qasm/front_ca65.cpp
  src/omf/omf.cpp
)

add_library(qasm_lib STATIC ${QASM_LIB_SOURCES})
target_include_directories(qasm_lib PUBLIC src/qasm PRIVATE src/omf)
target_link_libraries(qasm_lib PUBLIC Threads::Threads)

add_executable(qasm src/qasm/main.cpp)
target_link_libraries(qasm PRIVATE qasm_lib)
add_version_source(qasm qasm ${QASM_VERSION_MAJOR} ${QASM_VERSION_MINOR} ${QASM_VERSION_PATCH})
copy_to_bin(qasm TRIGGER ${qasm_VERSION_TRIGGER})

add_executable(qlink src/qlink/qlink.cpp src/qlink/link.cpp src/omf/omf.cpp)
target_include_directories(qlink PRIVATE src/qlink src/omf)
add_version_source(qlink qlink ${QLINK_VERSION_MAJOR} ${QLINK_VERSION_MINOR} ${QLINK_VERSION_PATCH})
copy_to_bin(qlink TRIGGER ${qlink_VERSION_TRIGGER})

add_executable(test_qasm test/test_qasm.cpp)
target_link_libraries(test_qasm PRIVATE qasm_lib)
copy_to_bin(test_qasm)

add_executable(test_qlink test/test_qlink.cpp src/qlink/link.cpp src/omf/omf.cpp)
target_include_directories(test_qlink PRIVATE src/qlink src/omf)
copy_to_bin(test_qlink)

add_executable(makeBin src/makebin/main.cpp src/makebin/makebin.cpp src/omf/omf.cpp)
target_include_directories(makeBin PRIVATE src/makebin src/omf)
add_version_source(makeBin makeBin ${MAKEBIN_VERSION_MAJOR} ${MAKEBIN_VERSION_MINOR} ${MAKEBIN_VERSION_PATCH})
copy_to_bin(makeBin TRIGGER ${makeBin_VERSION_TRIGGER})

add_executable(test_makebin test/test_makebin.cpp src/makebin/makebin.cpp src/qlink/link.cpp src/omf/omf.cpp)
target_include_directories(test_makebin PRIVATE src/makebin src/qlink src/omf)
copy_to_bin(test_makebin)

add_executable(qomf src/qomf/main.cpp src/qomf/qomf.cpp)
target_include_directories(qomf PRIVATE src/qomf)
add_version_source(qomf qomf ${QOMF_VERSION_MAJOR} ${QOMF_VERSION_MINOR} ${QOMF_VERSION_PATCH})
copy_to_bin(qomf TRIGGER ${qomf_VERSION_TRIGGER})

add_executable(test_qomf test/test_qomf.cpp src/qomf/qomf.cpp src/qlink/link.cpp src/omf/omf.cpp)
target_include_directories(test_qomf PRIVATE src/qomf src/qlink src/omf)
copy_to_bin(test_qomf)

add_executable(qpro src/qpro/main.cpp src/qpro/qpro.cpp)
target_include_directories(qpro PRIVATE src/qpro)
add_version_source(qpro qpro ${QPRO_VERSION_MAJOR} ${QPRO_VERSION_MINOR} ${QPRO_VERSION_PATCH})
copy_to_bin(qpro TRIGGER ${qpro_VERSION_TRIGGER})

add_executable(test_qpro test/test_qpro.cpp src/qpro/qpro.cpp)
target_include_directories(test_qpro PRIVATE src/qpro)
copy_to_bin(test_qpro)

# Unit tests and the assembler open PUT/USE paths from the repository root.
set(QASM_ROOT ${CMAKE_SOURCE_DIR})

# One program, six syntaxes. The objects are compared after assembly.
set(COVERAGE_SOURCES
  test/fixtures/coverage-merlin.s
  test/fixtures/coverage-merlin32.s
  test/fixtures/coverage-orca.s
  test/fixtures/coverage-apw.s
  test/fixtures/coverage-lisa.s
  test/fixtures/coverage-ca65.s
)

# Two relocatable sections. CODE calls and addresses DATA, and DATA calls
# and addresses CODE. Each syntax assembles to the same bytes.
set(REL_CODE_SOURCES
  test/fixtures/rel-code-merlin.s
  test/fixtures/rel-code-merlin32.s
  test/fixtures/rel-code-orca.s
  test/fixtures/rel-code-apw.s
  test/fixtures/rel-code-lisa.s
  test/fixtures/rel-code-ca65.s
)
set(REL_DATA_SOURCES
  test/fixtures/rel-data-merlin.s
  test/fixtures/rel-data-merlin32.s
  test/fixtures/rel-data-orca.s
  test/fixtures/rel-data-apw.s
  test/fixtures/rel-data-lisa.s
  test/fixtures/rel-data-ca65.s
)

set(COVERAGE_COMPARE
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-merlin32.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-orca.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-apw.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-lisa.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-ca65.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-code-merlin.bin test/fixtures/rel-code-merlin32.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-code-merlin.bin test/fixtures/rel-code-orca.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-code-merlin.bin test/fixtures/rel-code-apw.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-code-merlin.bin test/fixtures/rel-code-lisa.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-code-merlin.bin test/fixtures/rel-code-ca65.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-data-merlin.bin test/fixtures/rel-data-merlin32.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-data-merlin.bin test/fixtures/rel-data-orca.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-data-merlin.bin test/fixtures/rel-data-apw.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-data-merlin.bin test/fixtures/rel-data-lisa.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/rel-data-merlin.bin test/fixtures/rel-data-ca65.bin
)

add_custom_target(fixtures
  COMMAND $<TARGET_FILE:qasm> ${COVERAGE_SOURCES} ${REL_CODE_SOURCES} ${REL_DATA_SOURCES}
  ${COVERAGE_COMPARE}
  DEPENDS qasm
  WORKING_DIRECTORY ${QASM_ROOT}
  USES_TERMINAL
  COMMENT "Assemble coverage fixtures and compare the objects"
)

add_custom_target(test
  COMMAND $<TARGET_FILE:test_qasm>
  COMMAND $<TARGET_FILE:qasm> test/fixtures/hello.s test/test.s
  COMMAND $<TARGET_FILE:qasm> ${COVERAGE_SOURCES} ${REL_CODE_SOURCES} ${REL_DATA_SOURCES}
  ${COVERAGE_COMPARE}
  COMMAND $<TARGET_FILE:test_qlink>
  COMMAND ${CMAKE_COMMAND} -E env MAKEBIN=$<TARGET_FILE:makeBin> $<TARGET_FILE:test_makebin>
  COMMAND ${CMAKE_COMMAND} -E env QOMF=$<TARGET_FILE:qomf> $<TARGET_FILE:test_qomf>
  COMMAND ${CMAKE_COMMAND} -E env QPRO=$<TARGET_FILE:qpro> $<TARGET_FILE:test_qpro>
  DEPENDS qasm test_qasm test_qlink test_makebin test_qomf test_qpro qlink makeBin qomf qpro
  WORKING_DIRECTORY ${QASM_ROOT}
  USES_TERMINAL
  COMMENT "Run unit tests, sample assembly, coverage fixtures, and the linker"
)

set(QASM_CLEAN_FILES
  ${QASM_ROOT}/test/fixtures/hello.bin
  ${QASM_ROOT}/test/fixtures/hello.lst
  ${QASM_ROOT}/test/fixtures/hello.pcode
  ${QASM_ROOT}/test/test.bin
  ${QASM_ROOT}/test/test.lst
  ${QASM_ROOT}/test/test.pcode
)
foreach(src ${COVERAGE_SOURCES} ${REL_CODE_SOURCES} ${REL_DATA_SOURCES})
  string(REGEX REPLACE "\\.s$" "" stem "${src}")
  list(APPEND QASM_CLEAN_FILES
    ${QASM_ROOT}/${stem}.bin
    ${QASM_ROOT}/${stem}.lst
    ${QASM_ROOT}/${stem}.pcode
    ${QASM_ROOT}/${stem}.o
  )
endforeach()
foreach(out apple.omf apple-orca.omf apple-ca65.omf apple-apw.omf prog.omf
            proglib.omf gap.omf merged.omf runtime.lib bad.omf)
  list(APPEND QASM_CLEAN_FILES ${QASM_ROOT}/test/fixtures/${out})
endforeach()
# ProDOS 8 disk that boots BASIC.SYSTEM. Not part of `all` or `test`.
# Intermediates stay in build/boot. The image and the two SYS files land in bin/.
# `make boot` deletes those and builds the boot.2mg target.
set(BOOT_DIR ${QASM_ROOT}/build/boot)
set(BOOT_BIN ${QASM_ROOT}/bin)
set(P8_MLI ${QASM_ROOT}/IIGS.601.SRC/GS.OS/P8/MliSrc.aii)
set(P8_RAM ${QASM_ROOT}/IIGS.601.SRC/GS.OS/P8/P8.Drivers/Ram.n)
set(P8_CLOCK ${QASM_ROOT}/IIGS.601.SRC/GS.OS/P8/P8.Drivers/CClock.n)
set(BS_DIR ${QASM_ROOT}/IIGS.601.SRC/BASIC.SYSTEM)
set(BOOT_PACK ${QASM_ROOT}/boot/pack.py)

add_custom_command(
  OUTPUT ${BOOT_DIR}/mli.lst ${BOOT_DIR}/mli.bin
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_DIR}
  COMMAND $<TARGET_FILE:qasm> --syntax apw -I ${QASM_ROOT}/boot/inc
          -l ${BOOT_DIR}/mli.lst -o ${BOOT_DIR}/mli.bin ${P8_MLI}
  DEPENDS qasm ${P8_MLI}
          ${QASM_ROOT}/boot/inc/e16.memory ${QASM_ROOT}/boot/inc/M16.UTIL
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Assemble the ProDOS 8 kernel"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_DIR}/ram.lst ${BOOT_DIR}/ram.bin
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_DIR}
  COMMAND $<TARGET_FILE:qasm> --syntax apw
          -l ${BOOT_DIR}/ram.lst -o ${BOOT_DIR}/ram.bin ${P8_RAM}
  DEPENDS qasm ${P8_RAM}
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Assemble the ProDOS 8 RAM driver"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_DIR}/clock.lst ${BOOT_DIR}/clock.bin
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_DIR}
  COMMAND $<TARGET_FILE:qasm> --syntax apw
          -l ${BOOT_DIR}/clock.lst -o ${BOOT_DIR}/clock.bin ${P8_CLOCK}
  DEPENDS qasm ${P8_CLOCK}
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Assemble the ProDOS 8 GS clock driver"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_BIN}/PRODOS
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_BIN}
  COMMAND python3 ${BOOT_PACK} prodos ${BOOT_BIN}/PRODOS
          ${BOOT_DIR}/mli.lst ${BOOT_DIR}/ram.lst ${BOOT_DIR}/clock.lst
  DEPENDS ${BOOT_PACK} ${BOOT_DIR}/mli.lst ${BOOT_DIR}/ram.lst ${BOOT_DIR}/clock.lst
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Pack PRODOS"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_DIR}/basic.s
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_DIR}
  COMMAND python3 ${BOOT_PACK} join-basic -o ${BOOT_DIR}/basic.s
          ${BS_DIR}/LOADER ${BS_DIR}/MAIN ${BS_DIR}/GLOBALS
  DEPENDS ${BOOT_PACK} ${BS_DIR}/LOADER ${BS_DIR}/MAIN ${BS_DIR}/GLOBALS
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Join BASIC.SYSTEM"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_DIR}/basic.lst ${BOOT_DIR}/basic.bin
  COMMAND $<TARGET_FILE:qasm> --syntax apw -I ${BS_DIR}
          -l ${BOOT_DIR}/basic.lst -o ${BOOT_DIR}/basic.bin ${BOOT_DIR}/basic.s
  DEPENDS qasm ${BOOT_DIR}/basic.s ${BS_DIR}/EQUATES
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Assemble BASIC.SYSTEM"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_BIN}/BASIC.SYSTEM
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_BIN}
  COMMAND python3 ${BOOT_PACK} basic ${BOOT_BIN}/BASIC.SYSTEM ${BOOT_DIR}/basic.lst
          --oracle ${BS_DIR}/BASIC.SYSTEM
  DEPENDS ${BOOT_PACK} ${BOOT_DIR}/basic.lst ${BS_DIR}/BASIC.SYSTEM
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Pack BASIC.SYSTEM"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_DIR}/p8boot.lst ${BOOT_DIR}/p8boot.bin
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOT_DIR}
  COMMAND $<TARGET_FILE:qasm> --syntax merlin
          -l ${BOOT_DIR}/p8boot.lst -o ${BOOT_DIR}/p8boot.bin
          ${QASM_ROOT}/boot/p8boot.s
  DEPENDS qasm ${QASM_ROOT}/boot/p8boot.s
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Assemble the ProDOS 8 boot block"
  VERBATIM
)

add_custom_command(
  OUTPUT ${BOOT_BIN}/boot.2mg
  COMMAND ${CMAKE_COMMAND} -E rm -f ${BOOT_DIR}/image.2mg ${BOOT_BIN}/boot.2mg
  COMMAND $<TARGET_FILE:qpro> create ${BOOT_DIR}/image.2mg -name BASIC -size 800k
  COMMAND $<TARGET_FILE:qpro> boot ${BOOT_DIR}/image.2mg ${BOOT_DIR}/p8boot.bin
  COMMAND $<TARGET_FILE:qpro> add ${BOOT_DIR}/image.2mg PRODOS ${BOOT_BIN}/PRODOS -t FF -a 0000
  COMMAND $<TARGET_FILE:qpro> add ${BOOT_DIR}/image.2mg BASIC.SYSTEM ${BOOT_BIN}/BASIC.SYSTEM -t FF -a 2000
  COMMAND python3 ${BOOT_PACK} check ${BOOT_DIR}/image.2mg
          ${BOOT_BIN}/PRODOS ${BOOT_BIN}/BASIC.SYSTEM
  COMMAND ${CMAKE_COMMAND} -E copy ${BOOT_DIR}/image.2mg ${BOOT_BIN}/boot.2mg
  DEPENDS qpro ${BOOT_PACK} ${BOOT_BIN}/PRODOS ${BOOT_BIN}/BASIC.SYSTEM ${BOOT_DIR}/p8boot.bin
  WORKING_DIRECTORY ${QASM_ROOT}
  COMMENT "Build boot.2mg"
  VERBATIM
)

add_custom_target(prodos DEPENDS ${BOOT_BIN}/PRODOS)
add_custom_target(basic.system DEPENDS ${BOOT_BIN}/BASIC.SYSTEM)
add_custom_target(boot.2mg DEPENDS ${BOOT_BIN}/boot.2mg)

list(APPEND QASM_CLEAN_FILES
  ${BOOT_BIN}/PRODOS
  ${BOOT_BIN}/BASIC.SYSTEM
  ${BOOT_BIN}/boot.2mg
)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${QASM_CLEAN_FILES})
