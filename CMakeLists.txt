cmake_minimum_required(VERSION 3.16)
project(merlin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -O2 -g)
endif()

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

set(MERLIN_LIB_SOURCES
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

add_library(merlin_lib STATIC ${MERLIN_LIB_SOURCES})
target_include_directories(merlin_lib PUBLIC src)
target_link_libraries(merlin_lib PUBLIC Threads::Threads)

add_executable(merlin src/main.cpp)
target_link_libraries(merlin PRIVATE merlin_lib)

add_executable(test_merlin test/test_merlin.cpp)
target_link_libraries(test_merlin PRIVATE merlin_lib)

# Unit tests and the assembler open PUT/USE paths from the repository root.
set(MERLIN_ROOT ${CMAKE_SOURCE_DIR})

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
  COMMAND $<TARGET_FILE:merlin> ${COVERAGE_SOURCES}
  ${COVERAGE_COMPARE}
  DEPENDS merlin
  WORKING_DIRECTORY ${MERLIN_ROOT}
  USES_TERMINAL
  COMMENT "Assemble coverage fixtures and compare the objects"
)

add_custom_target(test
  COMMAND $<TARGET_FILE:test_merlin>
  COMMAND $<TARGET_FILE:merlin> test/fixtures/hello.s test/test.s
  COMMAND $<TARGET_FILE:merlin> ${COVERAGE_SOURCES}
  ${COVERAGE_COMPARE}
  DEPENDS merlin test_merlin
  WORKING_DIRECTORY ${MERLIN_ROOT}
  USES_TERMINAL
  COMMENT "Run unit tests, sample assembly, and coverage fixtures"
)

set(MERLIN_CLEAN_FILES
  ${MERLIN_ROOT}/test/fixtures/hello.bin
  ${MERLIN_ROOT}/test/fixtures/hello.lst
  ${MERLIN_ROOT}/test/fixtures/hello.pcode
  ${MERLIN_ROOT}/test/test.bin
  ${MERLIN_ROOT}/test/test.lst
  ${MERLIN_ROOT}/test/test.pcode
)
foreach(src ${COVERAGE_SOURCES})
  string(REGEX REPLACE "\\.s$" "" stem "${src}")
  list(APPEND MERLIN_CLEAN_FILES
    ${MERLIN_ROOT}/${stem}.bin
    ${MERLIN_ROOT}/${stem}.lst
    ${MERLIN_ROOT}/${stem}.pcode
  )
endforeach()
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${MERLIN_CLEAN_FILES})
