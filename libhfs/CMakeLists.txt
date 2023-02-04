cmake_minimum_required(VERSION 3.0)
set(CMAKE_BUILD_TYPE DEBUG)

set(BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(PROJECT_NAME hfs)
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
project(${PROJECT_NAME})


set(ALL_DEFINES "-Wwrite-strings -Wno-pointer-sign -Wpointer-arith -Wshadow -Wstrict-prototypes -D_FILE_OFFSET_BITS=64" )
set(CONFIG_DEF "-DSTDC_HEADERS=1 -DHAVE_MKTIME=1 -DHAVE_FCNTL_H=1 -DHAVE_UNISTD_H=1" )
set(DEBUG_OPT "-O0 -g3 " )
set(RELEASE_OPT "-O3 "  )

set(CMAKE_C_FLAGS "-Wall ${ALL_DEFINES} ${CONFIG_DEF}")
set(CMAKE_CXX_FLAGS "-Wall ${ALL_DEFINES} ${CONFIG_DEF}")

set(CMAKE_CXX_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_OPT}")
set(CMAKE_C_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_C_FLAGS_RELEASE "${RELEASE_OPT}")

set(FIND_LIBRARY_USE_LIB64_PATHS TRUE)

set (SOURCE 
block.c  
btree.c  
data.c  
file.c  
hfs.c  
low.c  
medium.c  
memcmp.c  
node.c  
os.c  
record.c  
version.c  
volume.c
) 

include_directories(BEFORE 
  ${PROJECT_ROOT}
)

add_library( ${PROJECT_NAME} SHARED ${SOURCE})
add_library( ${PROJECT_NAME}_static STATIC ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
)



