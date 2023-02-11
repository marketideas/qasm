
#pragma once

#include "qasm.h"
//
//extern ConfigOptions qoptions;

#define OPHANDLER(ACB) std::bind(ACB, this, std::placeholders::_1, std::placeholders::_2)


#define FLAG_FORCELONG 0x01
#define FLAG_FORCEABS  0x02
#define FLAG_FORCEDP   0x04
#define FLAG_DP		   0x08
#define FLAG_BIGNUM    0x10
#define FLAG_INDUM     0x20
#define FLAG_FORCEIMPLIED 0x40

#define FLAG_FORCEADDRPRINT 0x0100
#define FLAG_NOLINEPRINT 0x0200

#define OP_A       0x0001
#define OP_XY      0x0002
#define OP_PSUEDO  0x0004
#define OP_SPECIAL 0x0008

// these bits are actually the CC (last 2 bits) of opcode addressing
#define OP_CLASS0  0x0000
#define OP_CLASS1  0x0100
#define OP_CLASS2  0x0200
#define OP_CLASS3  0x0300
// these ORd bits specify specific classes of opcodes and subgroups
#define OP_STD     (0x1000 | OP_CLASS1)
#define OP_ASL     (0x2000 | OP_CLASS2)
#define OP_C0      (0x4000 | OP_CLASS0)
#define OP_STX     (0x8000 | OP_ASL|OP_CLASS2)

enum asmErrors
{
	errNone,
	errWarn,
	errDebug,
	errIncomplete,
	errUnimplemented,
	errFatal,
	errBadAddressMode,
	errBadOpcode,
	errIncompatibleOpcode,
	errBadByteCount,
	errBadBranch,
	errForwardRef,
	errNoRedefinition,
	errDupSymbol,
	errBadDUMop,
	errOverflow,
	errRecursiveOp,
	errOpcodeNotStarted,
	errDuplicateFile,
	errFileNotFound,
	errFileNoAccess,
	errBadEvaluation,
	errIllegalCharOperand,
	errBadCharacter,
	errUnexpectedOp,
	errUnexpectedEOF,
	errBadLUPOperand,
	errBadLabel,
	errBadOperand,
	errErrOpcode,
	errMAX
};

#ifdef ADD_ERROR_STRINGS
const std::string errStrings[errMAX + 1] =
{
	"No Error",
	"Warning",
	"Debug Error",
	"Unfinished Opcode",
	"Unimplemented Instruction",
	"Fatal",
	"Unsupported Addressing Mode",
	"Bad opcode",
	"Opcode not available under CPU mode",
	"Byte output differs between passes",
	"Bad branch",
	"Forward Reference to symbol",
	"Unable to redefine symbol",
	"Duplicate Symbol",
	"Invalid use of DUM/DEND",
	"Overflow detected",
	"Recursive Operand",
	"Opcode without start",
	"File already included",
	"File not found",
	"File no access",
	"Unable to evaluate",
	"Illegal char in operand",
	"Unexpected character in input",
	"Unexpected opcode",
	"Unexpected End of File",
	"LUP value must be 0 < VAL <= $8000",
	"Unknown label",
	"Bad operand",
	"Break",

	""
};
#else
extern const std::string errStrings[errMAX];
extern uint8_t opCodeCompatibility[256];

#endif



class TOriginSection
{
// SGQ - if you do something unusual here, be aware of copy constructor
// may be needed
public:
	uint32_t origin;
	uint32_t currentpc;
	uint32_t totalbytes;
	uint32_t orgsave;
// leave this code here in case we ever need a copy/assignment constructor
#if 0
	TOriginSection(const TOriginSection &old)
	{
		origin = old.origin;
		currentpc = old.currentpc;
		orgsave = old.orgsave;
		totalbytes = old.totalbytes;
	};

	TOriginSection& operator=(const TOriginSection &other)
	{
		origin = other.origin;
		currentpc = other.currentpc;
		totalbytes = other.totalbytes;
		orgsave = other.orgsave;
		return (*this);
	};

	TOriginSection()
	{
		origin = 0;
		currentpc = 0;
		totalbytes = 0;
		orgsave = 0;
	};
	~TOriginSection()
	{
	}
#endif
};

class shiftStruct
{
public:
	string shiftString;
	string origString;
	uint32_t flags;
	uint32_t amode;
	uint8_t shiftchar;
	uint8_t shiftamount;
	bool immediate;
	bool iserror;

	shiftStruct(string in) : shiftStruct()
	{
		origString=in;
		parse();
	}

	shiftStruct()
	{
		shiftString="";
		origString="";
		flags=0;
		shiftchar=0;
		immediate=false;
		iserror=true;
		shiftamount=0;
		amode=syn_none;
	}

	~shiftStruct()
	{

	}
	int parse()
	{
		int res=0;
		string oper;
		flags=0;
		shiftchar=0;
		shiftamount=0;
		iserror=false;
		amode=syn_none;

		oper=trim(origString);
		shiftString=oper;

		bool supportbar=false;
		bool modified=false;

		int l=oper.length();
		if (l==0)
		{
			return(res);
		}

		shiftchar=oper[0];
		if (shiftchar=='#')
		{
			shiftchar=0;
			immediate=true;
			if (l>1)
			{
				shiftchar=oper[1];
			}
		}
		if (shiftchar=='^')
		{
			if (qoptions.isMerlin())
			{
				iserror=true;
				amode=syn_err;
				return(res);
				//shiftchar=0x00; // merlin8 does not support the bank addr
			}
		}
		if (shiftchar=='|')
		{
			if (qoptions.isMerlinCompat())
			{
				if ((qoptions.isMerlin() || qoptions.isMerlin16())) // merlin8 and merlin16 do not support the bar
				{
					//line.setError(errIllegalCharOperand);
					amode=syn_err;
					iserror=true;
					return(res);
				}
				else
				{
					supportbar=true;
				}
			}
		}

		if ((shiftchar=='^') || (shiftchar=='<') || (shiftchar=='>') || (supportbar && (shiftchar=='|')))
		{
			modified=true;
		}
		else
		{
			shiftchar=0; // erase anything that is not one of those above
		}

		if (modified)
		{
			//line.shiftchar=shiftchar;
			if (oper[0]=='#')
			{
				oper=oper.substr(2);
				oper="#"+oper;
				l=oper.length();
			}
			else if (shiftchar!=0)
			{
				oper=oper.substr(1);
				l=oper.length();
			}
			shiftString=oper;
			if (isDebug()>1)
			{
				//printf("old: |%s| new: |%s|\n",origString.c_str(),shiftString.c_str());
			}
		}

		if (supportbar && shiftchar=='|')
		{
			if (qoptions.isMerlin32())
			{
				// regular Merlin16/16+ seems to accept this character, but does NOT force long (bank) addressing
				flags|=FLAG_FORCELONG;
			}
			//shiftchar=0; // don't process this as a shift because we only needed to set a flag to force long addressing
		}
		return(res);
	}
};

class MerlinLine
{
public:

	//uint32_t syntax;
	ConfigOptions *qoptions;
	std::string wholetext;
	std::string lable;
	std::string printlable;
	std::string printoperand;
	std::string strippedoperand;
	std::string opcode;
	std::string opcodelower;
	std::string orig_operand;
	std::string operand;
	std::string operand_expr;
	std::string operand_expr2;
	std::string comment;
	std::string addrtext;
	char shiftchar;
	uint8_t linemx;
	uint8_t tabs[16];
	bool showmx;
	bool merlinerrors;
	uint8_t truncdata;
	uint32_t lineno;
	uint32_t flags;
	uint16_t opflags;
	int32_t startpc;
	uint32_t addressmode;
	uint32_t expr_value;
	//uint8_t expr_shift;  // after an eval, this byte will reflect any shift code on expr (|^<>)
	int32_t eval_result; // this is the error code from the evaluate routing (0 or neg)
	uint32_t errorcode;
	std::string errorText;

	uint16_t pass0bytect;
	uint16_t bytect;
	uint16_t datafillct;
	uint8_t  datafillbyte;
	uint16_t outbytect;
	std::vector<uint8_t> outbytes;

public:
	MerlinLine(ConfigOptions &opt);
	MerlinLine(std::string line, ConfigOptions &opt);
	void clear();
	void set(std::string line);
	void print(uint32_t lineno);
	void setError(uint32_t ecode);
};

class TFileProcessor
{
protected:
	int win_columns;
	int win_rows;
	std::string initialdir;
	std::vector<std::string> filenames;
	//uint32_t syntax;
	uint64_t starttime;
	uint8_t tabs[16];

	uint32_t filecount; // how many files have been read in (because of included files from source

public:
	ConfigOptions &qoptions;
	uint32_t errorct;
	std::string filename;
	uint32_t format_flags;

	TFileProcessor(ConfigOptions &opt);
	virtual ~TFileProcessor();
	virtual std::string processFilename(std::string p, std::string currentdir, int level);
	virtual int processfile(std::string p, std::string &newfilename);
	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);
	virtual void errorOut(uint16_t code);
	virtual void setLanguage(string lang,bool force);
};


#define CONVERT_NONE 0x00
#define CONVERT_LF 0x01
#define CONVERT_CRLF 0x02
#define CONVERT_COMPRESS 0x04
#define CONVERT_HIGH 0x08
#define CONVERT_TABS 0x10
#define CONVERT_MERLIN (CONVERT_HIGH|CONVERT_COMPRESS)
#define CONVERT_LINUX (CONVERT_LF)
#define CONVERT_WINDOWS (CONVERT_CRLF)
#define CONVERT_APW (CONVERT_NONE)
#define CONVERT_MPW (CONVERT_NONE)
#define CONVERT_TEST (CONVERT_COMPRESS|CONVERT_LF)


#if 1
class TMerlinConverter : public TFileProcessor
{
protected:
	std::vector<MerlinLine> lines;

public:
	TMerlinConverter(ConfigOptions &opt);
	virtual ~TMerlinConverter();
	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);
};
#endif

class TLUPstruct
{
public:
	TLUPstruct()
	{
		clear();
	}
	void clear(void)
	{
		lupct = 0;
		lupoffset = 0;
		luprunning = 0;
		lupskip = false;
	}
	uint16_t lupct;
	bool lupskip;
	uint32_t lupoffset;
	uint16_t luprunning;
};

class TDOstruct
{
public:
	TDOstruct()
	{
		clear();
	}
	void clear(void)
	{
		doskip = false;
		value = 0;
	}
	uint32_t value;
	bool doskip;
};

class TSymbol;
typedef int (*TOpCB)(MerlinLine &line, TSymbol &sym);
typedef std::function<int (MerlinLine &line, TSymbol &sym)> TOpCallback;

class TSymbol
{
public:
	std::string namelc;
	std::string name;
	//std::string text;
	std::string var_text;
	uint32_t value;
	uint16_t stype;
	uint8_t opcode;
	bool used;
	TOpCallback cb;
	Poco::HashMap<std::string, TSymbol>locals;

	TSymbol()
	{
		clear();
	};
	void clear(void)
	{
		value = 0;
		used = false;
		//text = "";
		var_text = "";
		name = "";
		namelc = "";
		stype = 0;
		opcode = 0;
		locals.clear();
	}
};

//typedef Poco::HashMap<std::string, TSymbol> variable_t;

class TVariable
{
public:
	uint32_t id;
	Poco::HashMap<std::string, TSymbol> vars;
	TVariable()
	{
		// SGQ - must fix this so it is guaranteed unique for each one
		id=rand();
	}
};

class TMacro
{
public:
	std::string name;
	std::string lcname;
	TVariable  variables;
	std::vector<MerlinLine> lines;
	uint32_t start, end, currentline, len;
	uint32_t sourceline;
	bool running;

	TMacro()
	{
		clear();
	}
	void clear(void)
	{
		name = "";
		lcname = "";
		variables.vars.clear();
		lines.clear();
		sourceline = 0;
		currentline = 0;
		len = 0;
		start = 0;
		end = 0;
		running = false;
	}
};

class TPsuedoOp;

class T65816Asm : public TFileProcessor
{
protected:

public:
	std::vector<uint8_t> outputbytes;

	// options
	bool casesen;
	bool showmx;
	bool trackrep;
	bool merlinerrors;
	bool allowdup;
	uint8_t mx;
	uint8_t cpumode; // 0=6502, 1=65C02, 2=65816

	bool passcomplete;
	bool relocatable;
	int dumstart; // must be signed
	uint32_t dumstartaddr;
	bool skiplist; // used if lst is on, but LST opcode turns it off
	uint32_t lineno;
	bool lastcarry;

	std::string savepath;
	TSymbol *currentsym;
	TSymbol topSymbol;

	std::string currentsymstr;
	std::vector<MerlinLine> lines;
	Poco::HashMap<std::string, TMacro> macros;
	Poco::HashMap<std::string, TSymbol> opcodes;
	Poco::HashMap<std::string, TSymbol> symbols;
	TVariable variables;

	TOriginSection PC;
	TLUPstruct curLUP;
	TDOstruct curDO;
	TMacro currentmacro;
	TMacro expand_macro;
	bool listing;
	uint8_t truncdata; 	// for the TR opcode

	std::stack<TOriginSection> PCstack;
	std::stack<TLUPstruct> LUPstack;
	std::stack<TDOstruct> DOstack;
	std::stack<bool> LSTstack;
	std::stack<TMacro> macrostack;
	std::stack<TMacro> expand_macrostack;

	TPsuedoOp *psuedoops;

	uint16_t pass;

	T65816Asm(ConfigOptions &opt);
	virtual ~T65816Asm();

	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);

	void insertOpcodes(void);
	void pushopcode(std::string op, uint8_t opcode, uint16_t flags, TOpCallback cb);

	int callOpCode(std::string op, MerlinLine &line);
	TMacro *findMacro(std::string sym);

	TSymbol *findSymbol(std::string sym);
	TSymbol *addSymbol(std::string sym, uint32_t val, bool replace);
	TSymbol *findVariable(std::string sym, TVariable &vars);
	TSymbol *addVariable(std::string sym, std::string val, TVariable &vars, bool replace);


	void initpass(void);
	void showSymbolTable(bool alpha);
	void showMacros(bool alpha);

	void showVariables(TVariable &vars);
	int evaluate(MerlinLine &line, std::string expr, int64_t &value);

	int substituteVariables(MerlinLine & line, std::string &outop);

	bool codeSkipped(void);
	bool doOFF(void);


	int parseOperand(MerlinLine &line);
	int  getAddrMode(MerlinLine &line);
	void setOpcode(MerlinLine &line, uint8_t op);


	int doPSEUDO(MerlinLine &line, TSymbol &sym);
	int doEND(MerlinLine &line, TSymbol &sym);
	int doBase6502(MerlinLine &line, TSymbol &sym);
	int doBRANCH(MerlinLine &line, TSymbol &sym);
	int doJMP(MerlinLine &line, TSymbol &sym);
	int doAddress(MerlinLine &line, TSymbol &sym);
	int doNoPattern(MerlinLine &line, TSymbol &sym);
	int doMVN(MerlinLine &line, TSymbol &sym);
	int doPER(MerlinLine &line, TSymbol &sym);
	int doBRK(MerlinLine & line, TSymbol & sym);

	int doEQU(MerlinLine &line, TSymbol &sym);
	int doXC(MerlinLine &line, TSymbol &sym);
	int doMX(MerlinLine &line, TSymbol &sym);

	int doBYTE(MerlinLine &line, TSymbol &sym);
	int doUNK(MerlinLine &line, TSymbol &sym);

};

class T65816Link : public TFileProcessor
{
public:
	T65816Link(ConfigOptions &opt);
	virtual ~T65816Link();
	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);

	virtual void complete(void);
};