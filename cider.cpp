#ifdef CIDERPRESS

#include "app.h"

#undef CLASS
#define CLASS CiderPress

using namespace DiskImgLib;
using DiskImgLib::DiskImg;

void dbgMessage(const char *file, int line, const char *msg)
{
  if (isDebug()>0)
  {
	  printf("DEBUG: %s\n",msg);
  }
}

CLASS::CLASS(ConfigOptions &opt): TFileProcessor(opt)
{
	if (!Global::GetAppInitCalled())
	{
		DiskImgLib::Global::SetDebugMsgHandler(dbgMessage);
		DiskImgLib::Global::AppInit();
	}
}

CLASS::~CLASS()
{
  
}

int CLASS::RunScript(string path)
{
	int res=-1;



	return(res);
}

int CLASS::CreateVolume(string OSName, string VolName, uint64_t size, CIDER_VOLFORMAT format)
{
	int interr=-1;
	DIError err;
	DiskImg *img=new DiskImg();
	if (format==CP_PRODOS)
	{

		err=img->CreateImage(OSName.c_str(),VolName.c_str(),
		                     DiskImg::kOuterFormatNone,
		                     DiskImg::kFileFormat2MG,
		                     DiskImg::kPhysicalFormatSectors,
		                     NULL,
		                     DiskImg::kSectorOrderProDOS,
		                     DiskImg::kFormatGenericProDOSOrd,
		                     size/256,
		                     false
		                    );
		printf("create error: %d\n",err);
		if (err== kDIErrNone )
		{
			interr=0;
		}
	}
	return (interr);
}

int CLASS::doline(int lineno, std::string line)
{
    printf("%05d: %s\n",lineno,line.c_str());
    return(0);
}
void CLASS::process(void)
{

}
void CLASS::complete(void)
{

}

#undef CLASS

#endif