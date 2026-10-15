cmake_minimum_required(VERSION 3.16)
project(qasm LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -O2 -g)
endif()

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

set(QASM_LIB_SOURCES
  src/util.cpp
  src/parse.cpp
  src/expr.cpp
  src/opcode.cpp
  src/assemble.cpp
  src/compile.cpp
  src/front_merlin.cpp
  src/front_orca.cpp
  src/front_lisa.cpp
  src/front_ca65.cpp
)

add_library(qasm_lib STATIC ${QASM_LIB_SOURCES})
target_include_directories(qasm_lib PUBLIC src)
target_link_libraries(qasm_lib PUBLIC Threads::Threads)

add_executable(qasm src/main.cpp)
target_link_libraries(qasm PRIVATE qasm_lib)

add_executable(test_qasm test/test_qasm.cpp)
target_link_libraries(test_qasm PRIVATE qasm_lib)

# Unit tests and the assembler open PUT/USE paths from the repository root.
set(QASM_ROOT ${CMAKE_SOURCE_DIR})

# One program, five syntaxes. The objects are compared after assembly.
set(COVERAGE_SOURCES
  test/fixtures/coverage-merlin.s
  test/fixtures/coverage-merlin32.s
  test/fixtures/coverage-orca.s
  test/fixtures/coverage-lisa.s
  test/fixtures/coverage-ca65.s
)

set(COVERAGE_COMPARE
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-merlin32.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-orca.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-lisa.bin
  COMMAND ${CMAKE_COMMAND} -E compare_files
          test/fixtures/coverage-merlin.bin test/fixtures/coverage-ca65.bin
)

add_custom_target(fixtures
  COMMAND $<TARGET_FILE:qasm> ${COVERAGE_SOURCES}
  ${COVERAGE_COMPARE}
  DEPENDS qasm
  WORKING_DIRECTORY ${QASM_ROOT}
  USES_TERMINAL
  COMMENT "Assemble coverage fixtures and compare the objects"
)

add_custom_target(test
  COMMAND $<TARGET_FILE:test_qasm>
  COMMAND $<TARGET_FILE:qasm> test/fixtures/hello.s test/test.s
  COMMAND $<TARGET_FILE:qasm> ${COVERAGE_SOURCES}
  ${COVERAGE_COMPARE}
  DEPENDS qasm test_qasm
  WORKING_DIRECTORY ${QASM_ROOT}
  USES_TERMINAL
  COMMENT "Run unit tests, sample assembly, and coverage fixtures"
)

set(QASM_CLEAN_FILES
  ${QASM_ROOT}/test/fixtures/hello.bin
  ${QASM_ROOT}/test/fixtures/hello.lst
  ${QASM_ROOT}/test/fixtures/hello.pcode
  ${QASM_ROOT}/test/test.bin
  ${QASM_ROOT}/test/test.lst
  ${QASM_ROOT}/test/test.pcode
)
foreach(src ${COVERAGE_SOURCES})
  string(REGEX REPLACE "\\.s$" "" stem "${src}")
  list(APPEND QASM_CLEAN_FILES
    ${QASM_ROOT}/${stem}.bin
    ${QASM_ROOT}/${stem}.lst
    ${QASM_ROOT}/${stem}.pcode
  )
endforeach()
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${QASM_CLEAN_FILES})
