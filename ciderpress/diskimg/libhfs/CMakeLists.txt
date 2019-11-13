cmake_minimum_required(VERSION 3.0)
set(CMAKE_BUILD_TYPE DEBUG)

set(BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(PROJECT_NAME diskimg)
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
project(${PROJECT_NAME})


set(ALL_DEFINES "-DHAVE_CONFIG_H -Wwrite-strings -Wno-pointer-sign -Wpointer-arith -Wshadow -Wstrict-prototypes -D_FILE_OFFSET_BITS=64" )
set(DEBUG_OPT "-O0 -g3 " )
set(RELEASE_OPT "-O3 "  )

set(CMAKE_C_FLAGS "-Wall ${ALL_DEFINES} ")
set(CMAKE_CXX_FLAGS "-Wall ${ALL_DEFINES} ")

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



