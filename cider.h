#ifdef CIDERPRESS
#pragma once

#include "asm.h"
#include "eval.h"
#include "psuedo.h"
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include "DiskImg.h"

#define CLASS CiderPress

enum CIDER_VOLFORMAT {CP_PRODOS,CP_HFS};
class CLASS : public TFileProcessor
{
protected:
	std::vector<MerlinLine> lines;
public:
	CLASS(ConfigOptions &opt);
	virtual ~CLASS();
	int CreateVolume(string OSName, string VolName, uint64_t size, CIDER_VOLFORMAT format);
	int RunScript(string path);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);
};

#undef CLASS
#endif