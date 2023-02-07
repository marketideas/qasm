#pragma once
#include "qasm.h"

using namespace Poco;

#define MAX_PREFIX 32

#define MODE_6502 0
#define MODE_65C02 1
#define MODE_65816 2

#define SYNTAX_MERLIN 	0x01
#define SYNTAX_MERLIN32 0x02
#define SYNTAX_APW	    0x04
#define SYNTAX_MPW		0x08
#define SYNTAX_ORCA	    0x10
#define SYNTAX_CC65		0x20
#define SYNTAX_LISA		0x40
#define SYNTAX_QASM	    (0x80 | SYNTAX_MERLIN)

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

public:
	Poco::JSON::Parser parser;
	string jsonin;
	Dynamic::Var jsonobj=NULL;
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

	myLayeredConfiguration config;

	bool usecolor;

	CLASS()
	{
		setDefaults();
		setLanguage("QASM");
	}
	~CLASS()
	{

	}

	void clear()
	{
		//configs.clear();
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
		string l=Poco::toUpper(lang);
		if (l=="")
		{
			l=Poco::toUpper(language);
		}
		if (l!="")
		{
			setLanguage(l);
			setCurrent();
			printf("Defaults for language (%s)\n",language.c_str());
			printf("\tLanguage:\t\t\t\t\t%s\n",language.c_str());
			printf("\t\tlanguageLevel:\t\t\t\t%d\n",langlevel);
			printf("\t\tcpu_mode:\t\t\t\t%d\n",cpu_mode);
			printf("\t\tstart_mx:\t\t\t\t%d\n",start_mx);
			printf("\t\tPrefixes:\n");

			for (int i=0; i<MAX_PREFIX; i++)
			{
				if (prefixes[i].length()>0)
				{
					printf("\t\t\t%02d:\t\t\t%s\n",i,prefixes[i].c_str());
				}
			}


			//uint16_t format_flags;


			//bool start_listmode;
			//bool listmode;

		}
		return(res);
	}

	int ReadFile(string path)
	{
		int ret=-1;
		Poco::Util::JSONConfiguration *jc;

		Poco::Path pp(path);
		//pp=pp.expand();
		Poco::File pf(pp);
		if (isDebug()>1)
		{
			printf("parmsfile: %s\n",pp.toString().c_str());
		}
		if ((pf.exists()) && (pf.canRead()) && ((pf.isFile()) || (pf.isLink())))
		{
			//printf("OK: %s\n",pp.toString().c_str());

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
					config.add(jc);
					ret=0;
				}
				else
				{
					printf("unable to load/parts file: %s\n",pp.toString().c_str());
				}
			}
		}
		return(ret);
	}

	bool isMerlin32(void)
	{
		return(true);
	}

	bool isMerlin(void)
	{
		return(false);
	}

	void setCurrent(void)
	{
		start_mx=GetInteger("asm.start_mx",3);
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

	void setLanguage(string lang)
	{
		//printf("request language options to %s from %s\n",lang.c_str(),language.c_str());

		string old=language;
		string pn=Poco::toUpper(lang);
		if (old!=pn)
		{
			//printf("setting language options to %s\n",pn.c_str());
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
			//config
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
		config.keys(keys);
		for (unsigned int i=0;i<keys.size();i++)
		{
			printf("key[%d]: %s\n",i,keys[i].c_str());
		}
#endif

		try
		{
			res=config.getInt(name);
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