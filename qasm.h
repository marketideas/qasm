#pragma once
#include "palPoco.h"
#include "pallogger.h"
#include "eventtask.h"
#include "baseapp.h"
#include "httpserver.h"

#define CLASS PAL_APPCLASS
using namespace PAL_NAMESPACE;

class CLASS : public PAL_BASEAPP
{
protected:
	virtual int runCommandLineApp(void);
	virtual int runServerApp(PAL_EVENTMANAGER *em);
public:
};

#undef CLASS
