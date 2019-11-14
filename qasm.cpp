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
	{ "config", "f", "load configuration data from a <file>", "<file>", false, false},
	{ "exec", "x", "execute a command", "<command>", false, false},

	{ "", "", "", "", false, false}
};


int CLASS::runServerApp(PAL_EVENTMANAGER *em)
{
	int res = -1;
	if (em != NULL)
	{
		PAL_BASEAPP::runServerApp(em);
#if 0
		PAL_HTTPSERVERTASK *server = new PAL_HTTPSERVERTASK("httptask");
		if (server != NULL)
		{
			em->startTask(server);
			server->initServer(getConfig("http.listen", "0.0.0.0:9080"), false, 64);
			res = 0;
		}
#endif
	}
	return (res);
}

int CLASS::runCommandLineApp(void)
{
	TFileProcessor *t = NULL;
	std::string line;
	std::string startdirectory;

	// only called if SERVERAPP not defined
	int res = -1;


	startdirectory = Poco::Path::current();
	LOG_DEBUG << "currentdir: " << startdirectory << endl;
	if (commandargs.size() == 0)
	{
		fprintf(stderr, "No files given (--help for help)\n\n");
		return (res);
	}

	for (ArgVec::const_iterator it = commandargs.begin(); it != commandargs.end(); ++it)
	{
		Poco::File fn(*it);

		std::string p = fn.path();
		Poco::Path path(p);
		logger().information(path.toString());

		std::string e = toUpper(path.getExtension());

		std::string cmd = Poco::toUpper(getConfig("option.exec", "asm"));

		if (cmd.length() > 0)
		{
			if (cmd == "REFORMAT")
			{
				res = 0;
				t = new TMerlinConverter();
				if (t != NULL)
				{
					try
					{
						t->init();
						std::string f = path.toString();
						t->processfile(f);
						t->process();
						t->complete();
						res = (t->errorct > 0) ? -1 : 0;
					}
					catch (...)
					{
						delete t;
						t = NULL;
					}
				}
			}
			else if (cmd == "ASM")
			{
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
					try
					{
						t->init();
						std::string f = path.toString();
						t->processfile(f);
						t->process();
						t->complete();
						res = (t->errorct > 0) ? -1 : 0;
					}
					catch (...)
					{
						delete t;
						t = NULL;
					}
					chdir(startdirectory.c_str()); // return us back to where we were
				}
				else
				{
					printf("not supported type\n");
				}
			}
			else
			{
				fprintf(stderr, "Invalid command: <%s>\n\n", cmd.c_str());
			}
		}
	}
	return (res);
}



