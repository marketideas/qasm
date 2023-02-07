#pragma once
#include "qasm.h"

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


#undef CLASS
#define CLASS ConfigOptions
class CLASS
{
protected:
	vector<shared_ptr<JSONConfiguration>> configs;

public:
	Poco::JSON::Parser parser;
	string jsonin;
	Dynamic::Var jsonobj=NULL;
	uint16_t format_flags;

	uint16_t cpu_mode;
	string product;
	uint16_t productlevel;
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

	//Poco::Util::LayeredConfiguration config;

	bool usecolor;

	CLASS()
	{
		setDefaults();
		setProduct("QASM");
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
		if (getBool("option.color",false))
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
		res=getBool("option.quiet",false);
		if (isDebug()>0)
		{
			res=false;
		}
		return(res);
	}
	bool isList(void)
	{
		bool res;
		res=getBool("option.list",false);
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

	void printCurrentOptions(void)
	{
		printf("Current Options:");
		printf("  product: %s\n",product.c_str());
		//printf("  start_mx: \%%02d\n",start_mx);
	}

	bool isMerlin32(void)
	{
		return(true);
	}

	bool isMerlin(void)
	{
		return(false);
	}

	void setDefaults(void)
	{
		cpu_mode=MODE_6502;
		product="QASM";
		productlevel=0;
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

	void setProduct(string productName)
	{
		string old=productName;
		string pn=Poco::toUpper(productName);
		if (old!=pn)
		{
			printf("setting product options to %s\n",pn.c_str());
			productName=pn;
			if (pn=="QASM")
			{
				setQASM();
			}
		}
	}
	void setQASM()
	{

	}
};


#undef CLASS
#define CLASS QOptions

class CLASS
{
public:
	Poco::Util::JSONConfiguration config;
	Poco::JSON::Parser parser;
	string jsonin;
	Dynamic::Var jsonobj=NULL;
	CLASS();
	int ReadFile(string path);
	Dynamic::Var GetObject(string name);

	bool GetBool(string name, bool def=false);
	string GetString(string name, string def="");
};

#undef CLASS