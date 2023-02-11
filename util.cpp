#define UTIL_CPP
#include "app.h"

#undef CLASS
#define CLASS QUtils

CLASS::CLASS() : appInstance(Poco::Util::Application::instance())
{
}

bool CLASS::isMerlin32(void)
{
	return(false);
}

bool CLASS::isMerlin816(void)
{
	return(true);
}

string CLASS::getAppPath()
{
	char buff[PATH_MAX+1];
	char *x;

	string res="";
	res=appInstance.commandPath();
	x=realpath(res.c_str(),buff);
	if (x!=NULL)
	{
		res=buff;
	}
	else
		res="";
	return(res);
}


