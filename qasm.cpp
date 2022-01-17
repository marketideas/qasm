#include "app.h"
#include "asm.h"
#ifdef CIDERPRESS
#include "DiskImg.h"
#endif

#define CLASS PAL_APPCLASS

// return a pointer to the actual Application class
PAL_BASEAPP *PAL::appFactory(void)
{
	return (new CLASS());
}

// you MUST supply this array 'appOptions'.  NULL line and end.
programOption PAL::appOptions[] =
{
#ifdef DEBUG
	{ "debug", "d", "enable debug info (repeat for more verbosity)", "", false, true},
#endif
	//{ "config", "f", "load configuration data from a <file>", "<file>", false, false},
	{ "exec", "x", "execute a command [asm, link, reformat] default=asm", "<command>", false, false},
	{ "objfile", "o", "write output to file", "<file>", false, false},
	{ "syntax", "s", "enforce syntax of other assembler [merlin16, merlin32]", "<syntax>", false, false},


	{ "", "", "", "", false, false}
};


void CLASS::displayVersion()
{
	std::string s = "";
#ifdef DEBUG
	s = "-debug";
#endif
	cerr << "quickASM 16++ v" << (std::string)STRINGIFY(APPVERSION) << s << endl;

#ifdef CIDERPRESS
	DiskImgLib::Global::AppInit();
	DiskImgLib::DiskImg prodos;

    DiskImgLib::Global::AppCleanup();
#endif

}

#ifdef SERVERAPP
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
#endif

void CLASS::showerror(int ecode, std::string fname)
{
	std::string s;
	switch (ecode)
	{
		case -2:
			s = "Permission Denied";
			break;
		case -3:
			s = "File not found";
			break;
		default:
			s = "Unknown Error";
			break;
	}
	if (ecode < -1)
	{
		std::string a = Poco::Util::Application::instance().config().getString("application.name", "");
		fprintf(stderr, "%s: %s: %s\n", a.c_str(), fname.c_str(), s.c_str());
	}
}

int CLASS::runCommandLineApp(void)
{
	TFileProcessor *t = NULL;
	std::string line;
	std::string startdirectory;
	std::string fname;

	int res = -1;


	startdirectory = Poco::Path::current();

	if (commandargs.size() == 0)
	{
		displayHelp();
		return (res);
	}

	for (ArgVec::const_iterator it = commandargs.begin(); it != commandargs.end(); ++it)
	{
		Poco::File fn(*it);
		int x;
		std::string p = fn.path();
		Poco::Path path(p);
		//logger().information(path.toString());

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
						t->filename = f;
						x = t->processfile(f, fname);
						if (x == 0)
						{
							t->process();
							t->complete();
						}
						else
						{
							showerror(x, fname);
							t->errorct = 1;
						}
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
				int x;
				t = new T65816Asm();
				if (t != NULL)
				{
					try
					{
						t->init();
						std::string f = path.toString();
						t->filename = f;
						x = t->processfile(f, fname);
						f = t->filename;
						if (x == 0)
						{
							t->process();
							t->complete();
						}
						else
						{
							showerror(x, fname);
							t->errorct = 1;
						}
						res = (t->errorct > 0) ? -1 : 0;
					}
					catch (...)
					{
						delete t;
						t = NULL;
					}
					if (chdir(startdirectory.c_str())) {}; // return us back to where we were
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



