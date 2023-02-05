#pragma once
#include "app.h"

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