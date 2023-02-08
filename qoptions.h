#pragma once
#include "qasm.h"

using namespace Poco;

#define ENV_QASM "QASM_BASE"

#define MAX_PREFIX 32

#define MODE_6502 0
#define MODE_65C02 1
#define MODE_65816 2

#define SYNTAX_MERLIN 	0x01
#define SYNTAX_MERLIN16 0x02
#define SYNTAX_MERLIN16PLUS 0x04
#define SYNTAX_MERLIN32 0x08
#define SYNTAX_APW	    0x10
#define SYNTAX_MPW		0x20
#define SYNTAX_ORCA	    0x40
#define SYNTAX_CC65		0x80
#define SYNTAX_LISA		0x100
#define SYNTAX_QASM	    (0x200 | SYNTAX_MERLIN)

#define OPTION_ALLOW_A_OPERAND 0x0100
#define OPTION_ALLOW_LOCAL     0x0200
#define OPTION_ALLOW_COLON	   0x0400
#define OPTION_FORCE_REPSEP    0x0800
#define OPTION_NO_REPSEP       0x1000
#define OPTION_CFG_REPSEP	   0x2000
#define OPTION_M32_VARS		   0x4000
#define OPTION_M16_PLUS	       0x8000


class myLayeredConfiguration : public Poco::Util::LayeredConfiguration
{
public:
	myLayeredConfiguration() : Poco::Util::LayeredConfiguration() {};
	~myLayeredConfiguration() {};
};

#undef CLASS
#define CLASS ConfigOptions
class CLASS
{
protected:
	//vector<shared_ptr<JSONConfiguration>> configs;
	vector<std::string> valid_files;
public:
	//Poco::JSON::Parser parser;
	//string jsonin;
	//Dynamic::Var jsonobj=NULL;
	uint16_t format_flags;

	uint16_t cpu_mode;
	string language;
	uint16_t langlevel;
	string prefixes[MAX_PREFIX];

	uint8_t start_mx;
	bool start_listmode;
	bool listmode;

	bool casesen;
	bool showmx;
	bool allowDuplicate;
	bool trackrep;
	bool merlinerrors;
	bool m32vars;
	bool allowA;
	bool allowLocal;
	bool allowColon;
	bool oldevaluation;
	int16_t linebytes;
	int16_t overflowbytes;

	myLayeredConfiguration *config=NULL;

	bool usecolor;

	CLASS()
	{
		language="";
		setEnvironment();
		clear();
		setDefaults();
		setLanguage("QASM",true);
		setCurrent();
	}
	~CLASS()
	{
		clear();
	}

	void clear()
	{
		if (config!=NULL)
		{
			delete config;
			config=NULL;
		}
		config=new myLayeredConfiguration();
		valid_files.clear();

	}

	bool useColor(void)
	{
		bool res=false;
		if (PAL::getBool("option.color",false))
		{
			res=true;
		}
		if ((!isatty(STDOUT_FILENO)) || (0))
		{
			res=false;
		}

		return(res);
	}
	bool isQuiet(void)
	{
		bool res;
		res=PAL::getBool("option.quiet",false);
		if (isDebug()>0)
		{
			res=false;
		}
		return(res);
	}

	bool isList(void)
	{
		bool res;
		res=PAL::getBool("option.list",false);
		//printf("list: %d\n",res);
		return(res);
	}

	int printDefaults(string lang)
	{
		int res=-1;
		string s;
		int i;
		string l=Poco::toUpper(lang);
		if (l=="")
		{
			l=Poco::toUpper(language);
		}
		if (l!="")
		{
			setLanguage(l,false);
			setCurrent();
			printf("Defaults for language (%s)\n",language.c_str());
			printf("\t\tLanguage:\t\t\t%s\n",language.c_str());
			printf("\t\tlanguageLevel:\t\t\t%d\n",langlevel);
			s="<unknown>";
			switch(cpu_mode)
			{
			case 0:
				s="M6502";
				break;
			case 1:
				s="M65C02";
				break;
			case 2:
				s="M65816";
				break;
			}
			printf("\t\tcpu_mode:\t\t\t%s\n",s.c_str());
			printf("\t\tstart_mx:\t\t\t%%%d%d\n",start_mx&0x02?1:0,start_mx&0x01?1:0);
			//printf("\t\tstart_mx:\t\t\t%d\n",start_mx);
			printf("\t\tPrefixes:\n");

			for (i=0; i<MAX_PREFIX; i++)
			{
				if (prefixes[i].length()>0)
				{
					printf("\t\t\t%2d:\t%s\n",i,prefixes[i].c_str());
				}
			}

			printf("\n");

			for (unsigned long ii=0; ii<valid_files.size(); ii++)
			{
				if (prefixes[ii].length()>0)
				{
					printf("\t\tSettings files read: \t%s\n",valid_files[ii].c_str());
				}
			}
			//uint16_t format_flags;


			//bool start_listmode;
			//bool listmode;

		}
		return(res);
	}

	string getAppPath()
	{
		char buff[PATH_MAX+1];
		char *x;

		string res="";
		res=Poco::Util::Application::instance().commandPath();
		x=realpath(res.c_str(),buff);
		if (x!=NULL)
		{
			res=buff;
		}
		else
		{
			res="";
		}
		return(res);
	}
	int ReadFile(string path, bool backtrack)
	{
		//int levels=0;
		bool done=false;
		int ret=-1;
		unsigned long ii;
		Poco::Util::JSONConfiguration *jc;

		while(!done)
		{
			Poco::Path pp(path);
			//pp=pp.absolute(Poco::Path("/"));
			pp=pp.absolute();

			std::string basename=pp.getFileName();

			Poco::File pf(pp);
			if (isDebug()>1)
			{
				//pf.
				printf(" %d parmsfile: %s ",backtrack,pf.path().c_str());
			}
			if ((pf.exists()) && (pf.canRead()) && ((pf.isFile()) || (pf.isLink())))
			{
				if (isDebug()>1)
				{
					printf("...found!\n");
				}
				//printf("OK: %s\n",pp.toString().c_str());
				done=false;
				for (ii=0; ii<valid_files.size(); ii++)
				{
					if (pf.path()==valid_files[ii])
					{
						done=true;
					}
				}
				if (!done)
				{
					done=true; // we found a valid file

					jc=new Poco::Util::JSONConfiguration();
					//Poco::FileInputStream fs(path);
					//Poco::StreamCopier::copyToString(fs,jsonin);
					//parser.reset();
					//parser.setAllowComments(true);
					//jsonobj=parser.parse(jsonin);
					if (jc!=NULL)
					{
						bool success=false;
						try
						{
							jc->load(pp.toString());
							success=true;
						}
						catch(...)
						{
							success=false;
						}
						if (success)
						{
							//configs.push_back(shared_ptr<JSONConfiguration>(jc));
							config->add(jc);
							valid_files.push_back(pp.toString());
							ret=0;
						}
						else
						{
							delete jc;
							jc=NULL;
							printf("...unable to load/parts file: %s\n",pp.toString().c_str());
						}

					}
				}

			}
			else
			{
				if (isDebug()>1)
				{
					printf("...not found\n");
				}
			}
			if (!backtrack)
			{
				done=true;
			}

			if (!done)
			{
				//string ss=pp.current();
				string ss=pp.toString();
				pp=pp.popDirectory();
				string ss1=pp.toString();

				//printf("|%s| |%s|\n",ss.c_str(),ss1.c_str());
				//assert(0);
				path=ss1;
				pp=Path(path);
				if (path=="/")
				{
					done=true;
				}
				//path=path+"/"+basename;
			}
		}
		return(ret);
	}

	bool isMerlin32(void)
	{
		bool res=false;
		if (language=="MERLIN32")
		{
			res=true;
		}
		return(res);
	}

	bool isMerlin(void)
	{
		bool res=false;
		if (language=="MERLIN")
		{
			res=true;
		}
		return(res);
	}
	bool isQASM(void)
	{
		bool res=false;
		if (language=="QASM")
		{
			res=true;
		}
		return(res);
	}

	bool isMerlinCompat()
	{
		bool res=false;
		string s=language;
		if (s=="QASM")
		{
			return(true);
		}
		bool b=s.find("MERLIN");  // any of the merlin varieties
		if (b)
		{
			res=true;
			return(res);
		}
		return(res);
	}

	bool isMerlin16(void)
	{
		bool res=false;
		if (language=="MERLIN16")
		{
			res=true;
		}
		return(res);
	}

	bool isMerlin16plus(void)
	{
		bool res=false;
		if (language=="MERLIN16PLUS")
		{
			res=true;
		}
		return(res);
	}

	void setEnvironment()
	{
		string s="";
		//s=Poco::Environment::get("QASM");
		if (!Poco::Environment::has(ENV_QASM))
		{
			s=Poco::Util::Application::instance().commandPath();
			Poco::Path pp(getAppPath());
			pp=pp.absolute(Poco::Path());
			//pp=pp.absolute(Poco::Path("/"));
			s=pp.toString();
			//printf("program: %s\n",s.c_str());
			Poco::Environment::set(ENV_QASM,s);
		}
	}
	string formatPath(string p)
	{
		string res=p;
		string s;
		Poco::Path pp(p);
		s=pp.expand(pp.toString());  // replace environment variable references
		pp=Poco::Path(s);
		if (s!="")
		{

			Poco::StringTokenizer toks(s,"/");
			if (toks.count()>0)
			{
				uint32_t n;
				bool success=false;
				try
				{
					n=Poco::NumberParser::parseUnsigned(toks[0]);
					if (n<MAX_PREFIX)
					{
						success=true;
					}
				}
				catch(const std::exception& e)
				{
					success=false;
				}
				if (success)
				{
					s=s.substr(toks[0].length(),s.length());
					s=prefixes[n]+s;
					pp=Poco::Path(s);
				}
			}

			//pp=pp.absolute(Poco::Path("/"));
			pp=pp.absolute();
			res=pp.toString();
		}
		return(res);
	}

	void setCurrent(void)
	{
		char buff[1024];
		string s,n;
		int i;

		start_mx=GetInteger("asm.start_mx",3);
		for (i=0; i<MAX_PREFIX; i++)
		{
			sprintf(buff,"general.prefix[%d].%d",i,i);
			n=buff;
			n=GetString(n,"");
			n=formatPath(n);
			prefixes[i]=n;
		}
		s=GetString("asm.cpu","M6502");
		if (s=="M6502")
		{
			cpu_mode=MODE_6502;
		}
		else if (s=="M65C02")
		{
			cpu_mode=MODE_65C02;
		}
		else if (s=="M65816")
		{
			cpu_mode=MODE_65816;
		}
		else
		{
			printf("unknown cpu_mode in settings (%s) [M6502, M65C02, M65816]\n",s.c_str());
			cpu_mode=MODE_6502;
		}

		allowDuplicate=GetBool("asm.allowduplicate",false);
	}
	void setDefaults(void)
	{
		cpu_mode=MODE_6502;
		language="QASM";
		langlevel=0;
		for (int i=0; i<MAX_PREFIX; i++)
		{
			prefixes[i]="";
		}
		start_mx=0x03;
		start_listmode=true;
		listmode=start_listmode;
		casesen=true;
		showmx=true;
		allowDuplicate=false;
		trackrep=false;
		merlinerrors=true;
		m32vars=false;

		allowA=true;
		allowLocal=false;
		allowColon=false;
		oldevaluation=true;
		linebytes=4;
		overflowbytes=6;
		usecolor=true;
	}

	void setLanguage(string lang, bool force)
	{
		//printf("request language options to %s from %s\n",lang.c_str(),language.c_str());

		string old=language;
		string pn=Poco::toUpper(lang);
		if ((old!=pn) || (force))
		{
			printf("setting language options to %s\n",pn.c_str());
			language=pn;
			setCurrent();
			if (pn=="QASM")
			{
				setQASM();
			}
		}
	}
	string convertLanguage(string lang)
	{
		string res;
		res=lang;
		res=trim(res);
		res=toUpper(res);
		if (res=="MERLIN16+")
		{
			res="MERLIN16PLUS";
		}
		if (res=="MERLIN8")
		{
			res="MERLIN";
		}

		return(res);
	}
	bool supportedLanguage(string lang)
	{
		bool res=false;
		string r=toUpper(lang);
		r=trim(r);

		r=trim(r);
		if (r=="MERLIN")
		{
			res=true;
		}
		else if (r=="MERLIN8")
		{
			res=true;
		}
		else if (r=="MERLIN16")
		{
			res=true;
		}
		else if (r=="MERLIN16PLUS")
		{
			res=true;
		}
		else if (r=="MERLIN16+")
		{
			res=true;
		}
		else if (r=="MERLIN32")
		{
			res=true;
		}
		else if (r=="QASM")
		{
			res=true;
		}

		return(res);
	}
	void setQASM()
	{

	}

	bool GetBool(string name, bool def)
	{
		bool res=def;
		try
		{
			res=config->getBool(name);

			//Dynamic::Var jresult=GetObject(name);
			//if (!jresult.isEmpty())
			//{
			//	if (jresult.isArray())
			//	{

			//	}
			//	else if (jresult.isBoolean())
			//	{
			//		res=jresult;
			//	}
			//}
		}
		catch(...)
		{
			res=def;
		}
		return(res);
	}

	string GetString(string name, string def)
	{
		string res=def;
		try
		{
			res=config->getString(name);
		}
		catch(...)
		{
			res=def;
		}
		return(res);
	}

	int32_t GetInteger(string name, int32_t def)
	{
		int32_t res=def;

#if 0
		std::vector<std::string> keys;
		config->keys(keys);
		for (unsigned int i=0; i<keys.size(); i++)
		{
			printf("key[%d]: %s\n",i,keys[i].c_str());
		}
#endif

		try
		{
			res=config->getInt(name);
		}
		catch(...)
		{
			res=def;
			//throw;
		}
		return(res);
	}


};


#undef CLASS