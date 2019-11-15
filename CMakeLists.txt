cmake_minimum_required(VERSION 3.0)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(QAsm)

set(CMAKE_BUILD_TYPE Debug)
set(APPVERSION "1.0.1")
set(LIBRARY_NAME pal)
set(FIND_LIBRARY_USE_LIB64_PATHS TRUE)

include(./lib${LIBRARY_NAME}/cmake/CMakeHeader.txt)
set ( PROJECT_NAME "qasm" )

set(SOURCE
  ${PROJECT_ROOT}/${PROJECT_NAME}.cpp
  ${PROJECT_ROOT}/asm.cpp
  ${PROJECT_ROOT}/opcodes.cpp
  ${PROJECT_ROOT}/eval.cpp
  ${PROJECT_ROOT}/psuedo.cpp
)

find_package(OpenSSL REQUIRED)
find_package(Poco REQUIRED Foundation Util XML JSON NetSSL)

include_directories(BEFORE 
  ${PROJECT_ROOT}
  ${PROJECT_ROOT}/lib${LIBRARY_NAME}/include/${LIBRARY_NAME}
  ${OPENSSL_INCLUDE_DIR}
  ${Poco_INCLUDE_DIRS}
)

add_subdirectory(${PROJECT_ROOT}/lib${LIBRARY_NAME})

include(${PROJECT_ROOT}/lib${LIBRARY_NAME}/cmake/CMakeApp.txt)

add_executable( ${PROJECT_NAME} ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
${LIBRARY_NAME}
pthread
${Poco_LIBRARIES}
)

include(./lib${LIBRARY_NAME}/cmake/CMakeCommands.txt)



