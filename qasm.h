#pragma once
//#include ""
// if this file is called app.h...it is a link o qasm.h

#include <inttypes.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>


#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <deque>
#include <stdio.h>
#include <math.h>
#include <palPoco.h>
#include <pallogger.h>
#include <eventtask.h>
#include <baseapp.h>
#include "qoptions.h"
#include "qasm.h"
extern ConfigOptions qoptions;

#include "asm.h"
#include "util.h"
#include "eval.h"
#include "psuedo.h"
#ifdef CIDERPRESS
#include "cider.h"
#include "DiskImg.h"
#endif



//#include <httpserver.h>

#ifndef UNUSED
#define UNUSED (void)
#endif

#define CLASS PAL_APPCLASS
using namespace PAL_NAMESPACE;

//#define printf myprintf

extern int myprintf(const char *, ...);

class CLASS : public PAL_BASEAPP
{
protected:
	void showerror(int ecode,std::string fname);
	virtual int runCommandLineApp(void);
#ifdef SERVERAPP
	virtual int runServerApp(PAL_EVENTMANAGER *em);
#endif
	virtual void displayVersion();
	virtual void displayHelp();

public:

};

extern PAL_LOGGER logger;

#undef CLASS
