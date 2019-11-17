cmake_minimum_required(VERSION 3.0)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(QAsm)

set(CIDER "0")

#set(CMAKE_BUILD_TYPE DEBUG)
set(APPVERSION "4.0.9")
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

#find_package(OpenSSL REQUIRED)
find_package( Poco REQUIRED Foundation Util XML JSON )

if ( ${CIDER} )
find_package( ZLIB )
endif ( ${CIDER} )

include_directories(BEFORE 
  ${PROJECT_ROOT}
  ${PROJECT_ROOT}/lib${LIBRARY_NAME}/include/${LIBRARY_NAME}
  #${OPENSSL_INCLUDE_DIR}
  ${Poco_INCLUDE_DIRS}
)

include(${PROJECT_ROOT}/lib${LIBRARY_NAME}/cmake/CMakeApp.txt)

set (CIDERLIBS "" )
if ( ${CIDER} )
add_definitions(-DCIDERPRESS)
include_directories(AFTER ${PROJECT_ROOT}/ciderpress/diskimg)
add_subdirectory(${PROJECT_ROOT}/ciderpress/nufxlib)
add_subdirectory(${PROJECT_ROOT}/ciderpress/diskimg)

find_library(DISKIMG_LIB libnufx_static.a ${PROJECT_ROOT}/build )
find_library(HFS_LIB libnufx_static.a ${PROJECT_ROOT}/build )
find_library(NUFX_LIB libnufx_static.a ${PROJECT_ROOT}/build )
set (CIDERLIBS diskimg_static hfs_static nufx_static ${ZLIB_LIBRARIES})
endif ( ${CIDER} )

add_subdirectory(${PROJECT_ROOT}/lib${LIBRARY_NAME})

add_executable( ${PROJECT_NAME} ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
${LIBRARY_NAME}
pthread
${CIDERLIBS}
${Poco_LIBRARIES}
)

include(./lib${LIBRARY_NAME}/cmake/CMakeCommands.txt)



