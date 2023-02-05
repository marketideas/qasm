#pragma once

#include "asm.h"
#include "eval.h"
#include "psuedo.h"
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include "DiskImg.h"

#define CLASS CiderPress

enum CIDER_VOLFORMAT {CP_PRODOS,CP_HFS}; 
class CLASS
{
   public:
    CLASS();
    int CreateVolume(string OSName, string VolName, uint64_t size, CIDER_VOLFORMAT format);
    int RunScript(string path);
};

#undef CLASS