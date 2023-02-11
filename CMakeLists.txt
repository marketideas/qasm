cmake_minimum_required(VERSION 3.0)

set(CIDER "1")

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

set (CMAKE_VERBOSE_MAKEFILE "1")

project(QAsm)


set(APPVERSION "4.0.10")
set(LIBRARY_NAME pal)
set(FIND_LIBRARY_USE_LIB64_PATHS TRUE)


#message("root: ${PROJECT_ROOT}")
#include(./lib${LIBRARY_NAME}/cmake/CMakeHeader.txt)

set ( PROJECT_NAME "qasm" )

set(ALL_DEFINES )
set(ALL_FLAGS "-Wall -Wno-unused-const-variable" )
set(DEBUG_OPT "-D_DEBUG -DDEBUG -O0 -g3 ${ALL_FLAGS} " )
set(RELEASE_OPT "-O3 ${ALL_FLAGS} " )

set(CMAKE_C_FLAGS "${ALL_FLAGS}")
set(CMAKE_CXX_FLAGS "${ALL_FLAGS}")

set(CMAKE_CXX_FLAGS_DEBUG "${DEBUG_OPT}")
set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_OPT}")
set(CMAKE_C_FLAGS_DEBUG "${DEBUG_OPT}")
set(CMAKE_C_FLAGS_RELEASE "${RELEASE_OPT}")


set(SOURCE
  ${PROJECT_ROOT}/${PROJECT_NAME}.cpp
  ${PROJECT_ROOT}/asm.cpp
  ${PROJECT_ROOT}/opcodes.cpp
  ${PROJECT_ROOT}/eval.cpp
  ${PROJECT_ROOT}/psuedo.cpp
  ${PROJECT_ROOT}/qoptions.cpp
  ${PROJECT_ROOT}/cider.cpp
  ${PROJECT_ROOT}/util.cpp

)

#find_package(OpenSSL REQUIRED)
find_package( Poco REQUIRED Foundation Util JSON)

if ( ${CIDER} )
find_package( ZLIB )
endif ( ${CIDER} )

include_directories(BEFORE 
  ${PROJECT_ROOT}
  ${PROJECT_ROOT}/lib${LIBRARY_NAME}/include/${LIBRARY_NAME}
  #${PROJECT_ROOT}/libpal/pal/include
  #${OPENSSL_INCLUDE_DIR}
  ${Poco_INCLUDE_DIRS}
)

#include(${PROJECT_ROOT}/lib${LIBRARY_NAME}/cmake/CMakeApp.txt)

set (CIDERLIBS "" )
if ( ${CIDER} )
add_definitions(-DCIDERPRESS)

include_directories(AFTER ${PROJECT_ROOT}/diskimg)
add_subdirectory(${PROJECT_ROOT}/libhfs)
add_subdirectory(${PROJECT_ROOT}/nufxlib)
add_subdirectory(${PROJECT_ROOT}/diskimg)


find_library(DISKIMG_LIB libnufx_static.a ${PROJECT_ROOT}/build )
find_library(HFS_LIB libnufx_static.a ${PROJECT_ROOT}/build )
find_library(NUFX_LIB libnufx_static.a ${PROJECT_ROOT}/build )
set (CIDERLIBS diskimg_static hfs_static nufx_static ${ZLIB_LIBRARIES})
endif ( ${CIDER} )

add_definitions(-DAPPVERSION=${APPVERSION})

add_subdirectory(${PROJECT_ROOT}/libpal)

add_executable( ${PROJECT_NAME} ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
${LIBRARY_NAME}
pthread
${CIDERLIBS}
${Poco_LIBRARIES}
)

#include(./lib${LIBRARY_NAME}/cmake/CMakeCommands.txt)



