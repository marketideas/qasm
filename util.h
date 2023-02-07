#pragma once
#include <palPoco.h>

class QUtils
{
protected:
    Poco::Util::Application &appInstance;
public:
    QUtils();
	bool isMerlin32(void);
	bool isMerlin816(void);
	string getAppPath();
};

#ifdef UTIL_CPP
QUtils *utils=NULL;
#else
extern QUtils *utils;
#endif
