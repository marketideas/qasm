#pragma once
#include <inttypes.h>

#include <palPoco.h>
#include <pallogger.h>
#include <eventtask.h>
#include <baseapp.h>
#include "app.h"
#include "qoptions.h"
#include "util.h"
//#include <httpserver.h>

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
#ifdef SERVERAPP
	virtual int runServerApp(PAL_EVENTMANAGER *em);
#endif
	virtual void displayVersion();

public:

};

extern PAL_LOGGER logger;

#undef CLASS
