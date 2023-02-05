
#include <app.h>

#undef CLASS
#define CLASS QOptions

CLASS::CLASS()
{
	jsonin="";
	jsonobj=NULL;
	parser.reset();
}

int CLASS::ReadFile(string path)
{
	int ret=-1;

	Poco::FileInputStream fs(path);
	Poco::StreamCopier::copyToString(fs,jsonin);
	jsonobj=parser.parse(jsonin);

	config.load(path);
	//config.enumerate(key,range);
	return(ret);
}

Dynamic::Var CLASS::GetObject(string name)
{
	JSON::Query q(jsonobj);
	Dynamic::Var jresult=q.find(name);
    return(jresult);
}

bool CLASS::GetBool(string name, bool def)
{
	bool res=def;
	try
	{
        Dynamic::Var jresult=GetObject(name);
		if (!jresult.isEmpty())
		{
			if (jresult.isArray())
			{

			}
			else if (jresult.isBoolean())
			{
				res=jresult;
			}
		}
	}
	catch(...)
	{
		res=def;
	}
	return(res);
}

string CLASS::GetString(string name, string def)
{
	string res=def;
	try
	{
        Dynamic::Var jresult=GetObject(name);
		if (!jresult.isEmpty())
		{
			if (jresult.isArray())
			{

			}
			else if (jresult.isString())
			{
				res=jresult.toString();
			}
		}
	}
	catch(...)
	{
		res=def;
	}
	return(res);
}


