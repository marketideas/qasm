cmake_minimum_required(VERSION 3.0)
set(CMAKE_BUILD_TYPE DEBUG)

set(BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(PROJECT_NAME diskimg)
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
project(${PROJECT_NAME})



#set (ALL_DEFINES "\
#-DSTDC_HEADERS=1 -DHAVE_FDOPEN=1 -DHAVE_FTRUNCATE=1 -DHAVE_LOCALTIME_R=1 -DHAVE_MEMMOVE=1 \
#-DHAVE_MKDIR=1 -DHAVE_MKSTEMP=1 -DHAVE_MKTIME=1 -DHAVE_SNPRINTF=1 -DHAVE_STRCASECMP=1 -DHAVE_STRNCASECMP=1 -DHAVE_STRERROR=1 \
#-DHAVE_STRTOUL=1 -DHAVE_TIMELOCAL=1 -DHAVE_VSNPRINTF=1 -DHAVE_FCNTL_H=1 -DHAVE_MALLOC_H=1 -DHAVE_STDLIB_H=1 -DHAVE_SYS_STAT_H=1 \
#-DHAVE_SYS_TIME_H=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_UNISTD_H=1 -DHAVE_UTIME_H=1 -DSPRINTF_RETURNS_INT=1 -DSNPRINTF_DECLARED=1 \
#-DVSNPRINTF_DECLARED=1 -DENABLE_SQ=1 -DENABLE_LZW=1 -DENABLE_LZC=1 -DENABLE_DEFLATE=1 \
#"
#)

set(DEBUG_OPT "-D_DEBUG -DDEBUG -O0 -g3 " )
set(RELEASE_OPT "-O3 "  )

set(CMAKE_C_FLAGS "-Wall ${ALL_DEFINES} ")
set(CMAKE_CXX_FLAGS "-Wall ${ALL_DEFINES} ")

set(CMAKE_CXX_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_OPT}")
set(CMAKE_C_FLAGS_DEBUG "${DEBUG_OPT} ")
set(CMAKE_C_FLAGS_RELEASE "${RELEASE_OPT}")

set(FIND_LIBRARY_USE_LIB64_PATHS TRUE)

#add_subdirectory( ${CMAKE_CURRENT_SOURCE_DIR}/libhfs)

set (SOURCE 
ASPI.cpp       
DiskFS.cpp    
FAT.cpp         
Gutenberg.cpp     
Nibble35.cpp      
ProDOS.cpp  
UNIDOS.cpp
CFFA.cpp       
DiskImg.cpp   
FDI.cpp         
HFS.cpp           
Nibble.cpp        
RDOS.cpp    
VolumeUsage.cpp
Container.cpp  
DIUtil.cpp    
FocusDrive.cpp  
ImageWrapper.cpp  
OuterWrapper.cpp  
SPTI.cpp    
Win32BlockIO.cpp
CPM.cpp        
DOS33.cpp     
GenericFD.cpp   
MacPart.cpp       
OzDOS.cpp         
StdAfx.cpp
DDD.cpp        
DOSImage.cpp  
Global.cpp      
MicroDrive.cpp    
Pascal.cpp        
TwoImg.cpp
) 

include_directories(BEFORE 
  ${PROJECT_ROOT}
)

add_library( ${PROJECT_NAME} SHARED ${SOURCE})
add_library( ${PROJECT_NAME}_static STATIC ${SOURCE})

target_link_libraries (
${PROJECT_NAME}
)



