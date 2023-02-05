#include "app.h"
#include "asm.h"
#ifdef CIDERPRESS
#include "cider.h"
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
	{ "exec", "x", "execute a command [asm, link, reformat, script] default=asm", "<command>", false, false},
	{ "objfile", "o", "write output to file", "<file>", false, false},
	{ "syntax", "s", "enforce syntax of other assembler [qasm, merlin, merlin32, ORCA, APW, MPW, CC65]", "<syntax>", false, false},


	{ "", "", "", "", false, false}
};


void CLASS::displayVersion()
{
	std::string s = "";
#ifdef DEBUG
	s = "-debug";
#endif
	cerr << "quickASM 16++ v" << (std::string)STRINGIFY(APPVERSION) << s << endl;

//#ifdef CIDERPRESS
//	DiskImgLib::Global::AppInit();
//	DiskImgLib::DiskImg prodos;

//   DiskImgLib::Global::AppCleanup();
//#endif

}

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

// int main(int argc, char *argv[])
// this is where libpal calls to run a command line program
int CLASS::runCommandLineApp(void)
{
	TFileProcessor *t = NULL;
	std::string line;
	std::string startdirectory;
	std::string fname;
	uint32_t syntax;
	int res = -1;


	startdirectory = Poco::Path::current();

	if (commandargs.size() == 0)
	{
		displayHelp();
		return (res);
	}

	options.ReadFile(startdirectory+"/parms.json");

	string syn=options.GetString("assembler.syntax","QASM");

	string cmdsyn = Poco::toUpper(getConfig("option.syntax", ""));
	if (cmdsyn!="")
	{
		syn=cmdsyn; // if they overrode the syntax on the command line, use it
	}

	syn=Poco::toUpper(syn);
	syn=Poco::trim(syn);
	syntax=SYNTAX_QASM;
	if ((syn=="MERLIN") || (syn=="MERLIN16") || (syn=="MERLIN8") || (syn=="MERLIN16+"))
	{
		syntax=SYNTAX_MERLIN;
	}
	else if (syn=="MERLIN32")
	{
		syntax=SYNTAX_MERLIN32;
	}
	else if (syn=="QASM")
	{
		syntax=SYNTAX_QASM;
	}
	else if (syn=="APW")
	{
		syntax=SYNTAX_APW;
	}
	else if (syn=="ORCA")
	{
		syntax=SYNTAX_ORCA;
	}
	else if (syn=="MPW")
	{
		syntax=SYNTAX_MPW;
	}
	else if (syn=="CC65")
	{
		syntax=SYNTAX_CC65;
	}

	printf("SYNTAX: |%s|\n",syn.c_str());

	try
	{
#ifdef CIDERPRESS

		//CiderPress *cp=new CiderPress();
		//int err=cp->CreateVolume("./a2.2mg","PRODOS1",800*1024,CP_PRODOS);
		//printf("volume create: %d\n",err);

		//cp->RunScript(startdirectory+"/disk_commands.txt");

		//delete(cp);

#endif

		for (ArgVec::const_iterator it = commandargs.begin(); it != commandargs.end(); ++it)
		{
			Poco::File fn(*it);
			int x;
			std::string p = fn.path();
			Poco::Path path(p);
			//logger().information(path.toString());

			std::string e = toUpper(path.getExtension());

			std::string cmd = Poco::toUpper(getConfig("option.exec", "asm"));

			//printf("DEBUG=%d\n",isDebug());
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
							t->setSyntax(syntax);

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
							t->setSyntax(syntax);

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
						catch(const std::exception& e)
						{
							delete t;
							t = NULL;
						}
						if (chdir(startdirectory.c_str())) {}; // return us back to where we were
					}
				}
#ifdef CIDERPRESS
				else if (cmd == "SCRIPT")
				{
					res = 0;
					t = new TImageProcessor();
					if (t!=NULL)
					{
						try
						{
							t->init();
							t->setSyntax(syntax);

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
						catch(const std::exception& e)
						{
							std::cerr << e.what() << '\n';
							if (t!=NULL)
							{
								delete t;
								t=NULL;
							}
						}
					}
				}
#endif
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
	catch(...)
	{
#ifdef CIDERPRESS
		DiskImgLib::Global::AppCleanup();
#endif
	}
	return (res);
}



