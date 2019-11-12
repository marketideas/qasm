#include "app.h"
#include "asm.h"

#define CLASS PAL_APPCLASS

// return a pointer to the actual Application class
PAL_BASEAPP *PAL::appFactory(void)
{
	return (new CLASS());
}

// you MUST supply this array 'appOptions'.  NULL line and end.
programOption PAL::appOptions[] =
{
	{ "debug", "d", "enable debug info (repeat for more verbosity)", "", false, true},
	{ "config-file", "f", "load configuration data from a <file>", "file", false, false},
	{ "", "", "", "", false, false}
};


int CLASS::runServerApp(PAL_EVENTMANAGER *em)
{
	int res = -1;
	if (em != NULL)
	{
		PAL_BASEAPP::runServerApp(em);
		PAL_HTTPSERVERTASK *server = new PAL_HTTPSERVERTASK("httptask");
		if (server != NULL)
		{
			em->startTask(server);
			server->initServer(getConfig("http.listen", "0.0.0.0:9080"), false, 64);
			res = 0;
		}
	}
	return (res);
}

int CLASS::runCommandLineApp(void)
{
	TFileProcessor *t = NULL;
	std::string line;

	// only called if SERVERAPP not defined
	int res = -1;

	//LOG_DEBUG << "command line mode" << endl;
	for (ArgVec::const_iterator it = commandargs.begin(); it != commandargs.end(); ++it)
	{
		Poco::File fn(*it);

		std::string p = fn.path();
		Poco::Path path(p);
		//logger().information(path.toString());

		std::string e = toUpper(path.getExtension());

		if (e == "S")
		{
			//logger().information("ASM: " + path.toString());

			t = new T65816Asm();
		}
		if (e == "LNK")
		{
			//logger().information("LNK: " + path.toString());
			t = new T65816Link();
		}
		if (t != NULL)
		{
			t->init();

			std::string f = path.toString();
			t->processfile(f);
			t->process();
			t->complete();
			delete t;
			t = NULL;
		}
		else
		{
			printf("not supported type\n");
		}


		//logger().information(*it);
		res = 0;
	}

	return (res);
}



