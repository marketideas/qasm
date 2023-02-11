#ifdef CIDERPRESS
#pragma once


enum CIDER_VOLFORMAT {CP_PRODOS,CP_HFS};

#undef CLASS
#define CLASS A2Volume

class CLASS
{
protected:
	string volumeName;
	string volumePath;
	string filename;
	string fileFormat;
	string format;
	string sizeString;
public:
	CLASS()
	{
		volumeName="";
		volumePath="";
		filename="";
		fileFormat="";
		format="";
		sizeString="";
	}

	virtual ~CLASS()
	{

	}
	int CreateVolume(string OSName, string VolName, uint64_t size, CIDER_VOLFORMAT format)
	{
		return(-1);
	}

};

#undef CLASS
#define CLASS CiderPress
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