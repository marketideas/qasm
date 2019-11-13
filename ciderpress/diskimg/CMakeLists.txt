cmake_minimum_required(VERSION 3.0)
set(CMAKE_BUILD_TYPE DEBUG)

set(BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(PROJECT_NAME diskimg)
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



