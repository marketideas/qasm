cmake_minimum_required(VERSION 3.0)
set(CMAKE_BUILD_TYPE DEBUG)

set(BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(PROJECT_NAME nufx)
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
project(${PROJECT_NAME})


set(ALL_DEFINES " " )
set(DEBUG_OPT "-D_DEBUG -DDEBUG -O0 -g3 " )
set(RELEASE_OPT "-O3 "  )

set(CMAKE_C_FLAGS "-Wall ${ALL_DEFINES} ")
set(CMAKE_CXX_FLAGS "-Wall ${ALL_DEFINES} ")

set(CMAKE_CXX_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_OPT}")
set(CMAKE_C_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_C_FLAGS_RELEASE "${RELEASE_OPT}")

set(FIND_LIBRARY_USE_LIB64_PATHS TRUE)

set (SOURCE 
Archive.c 
ArchiveIO.c 
Bzip2.c 
Charset.c 
Compress.c
Crc16.c
Debug.c
Deferred.c 
Deflate.c 
Entry.c 
Expand.c 
FileIO.c 
Funnel.c
Lzc.c 
Lzw.c 
MiscStuff.c 
MiscUtils.c 
Record.c 
SourceSink.c
Squeeze.c 
Thread.c 
Value.c 
Version.c
) 

include_directories(BEFORE 
  ${PROJECT_ROOT}
)

add_library( ${PROJECT_NAME} SHARED ${SOURCE})
add_library( ${PROJECT_NAME}_static STATIC ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
)



