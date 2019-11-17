#pragma once
#include <inttypes.h>

#include "palPoco.h"
#include "pallogger.h"
#include "eventtask.h"
#include "baseapp.h"
#include "httpserver.h"

#ifndef UNUSED
#define UNUSED (void)
#endif

#define CLASS PAL_APPCLASS
using namespace PAL_NAMESPACE;

class CLASS : public PAL_BASEAPP
{
protected:
	void showerror(int ecode,std::string fname);
	virtual int runCommandLineApp(void);
	virtual int runServerApp(PAL_EVENTMANAGER *em);
	virtual void displayVersion();

public:
};

#undef CLASS
