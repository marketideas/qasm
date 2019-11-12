#pragma once
#include "app.h"

#define OPHANDLER(ACB) std::bind(ACB, this, std::placeholders::_1, std::placeholders::_2)

#define MODE_6502 0
#define MODE_65C02 1
#define MODE_65816 2

#define SYNTAX_MERLIN 0
#define SYNTAX_APW	  1
#define SYNTAX_ORCA	  2

#define OP_6502  0x01
#define OP_65C02 0x02
#define OP_65816 0x04
#define OP_PSUEDO 0x08
#define OP_ONEBYTE 0x10
#define OP_SPECIAL 0x20
#define OP_CLASS0 0x0000
#define OP_CLASS1 0x0100
#define OP_CLASS2 0x0200
#define OP_CLASS3 0x0300
#define OP_CLASS4 0x0400
#define OP_STD    (0x1000 | OP_CLASS1 | OP_6502)
#define OP_ASL    (0x2000 | OP_CLASS2 | OP_6502)
#define OP_STX    (0x3000 | OP_CLASS2 | OP_6502)
#define OP_C0     (0x4000 | OP_CLASS0 | OP_6502)

enum asmErrors
{
	errNone,
	errWarn,
	errIncomplete,
	errFatal,
	errBadAddressMode,
	errBadOpcode,
	errIncompatibleOpcode,
	errBadByteCount,
	errBadBranch,
	errUnimplemented,
	errForwardReference,
	errMAX
};

#ifdef ADD_ERROR_STRINGS
std::string errStrings[errMAX] = {
	"No Error",
	"Warning",
	"Unfinished Opcode",
	"Fatal",
	"Unsupported Addressing Mode",
	"Unknown Opcode",
	"Opcode not available under CPU mode",
	"Byte output differs between passes",
	"Relative branch offset too large"
	"Unimplemented Instruction",
	"Forward Reference to symbol"
};
#else
extern std::string errStrings[errMAX];
extern uint8_t opCodeCompatibility[256];

#endif

enum
{
	syn_err = -1,  	// error - not recognized
	syn_none = 0,   // should never be returned 0
	syn_implied,    // no operand               1
	syn_s, 			// expr,s                   2
	syn_sy,			// (expr,s),y               3
	syn_imm,		// #expr                    4
	syn_diix,		// (expr,x)                 5
	syn_diiy,		// (expr),y                 6
	syn_di,			// (expr)                   7
	syn_iyl,		// [expr],y                 8
	syn_dil,		// [expr]                   9
	syn_absx,		// expr,x                  10
	syn_absy,		// expr,y                  11
	syn_bm,			// block move              12
	syn_abs,		// expr                    13

	syn_MAX
};

#define FLAG_LONGADDR 0x01

class MerlinLine
{
public:

	uint8_t syntax;
	std::string lable;
	std::string opcode;
	std::string opcodelower;
	std::string operand;
	std::string operand_expr;
	std::string operand_expr2;
	std::string comment;
	std::string addrtext;
	uint32_t lineno;
	uint32_t flags;
	uint16_t opflags;
	int32_t startpc;
	uint32_t addressmode;
	int32_t expr_value;
	uint32_t errorcode;
	uint8_t inbytect;
	uint8_t inbytes[256];

	uint16_t pass0bytect;
	uint16_t bytect;
	uint16_t outbytect;
	std::vector<uint8_t> outbytes;

public:
	MerlinLine();
	MerlinLine(std::string line);
	void clear();
	void set(std::string line);
	void print(uint32_t lineno);
	void setError(uint32_t ecode);
};

class TFileProcessor
{
protected:
	uint8_t syntax;
	uint64_t starttime;
public:

	TFileProcessor();
	virtual ~TFileProcessor();
	virtual int processfile(std::string &p);
	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);
	virtual void errorOut(uint16_t code);
};

class TSymbol;
typedef int (*TOpCB)(MerlinLine &line, TSymbol &sym);
typedef std::function<int (MerlinLine &line, TSymbol &sym)> TOpCallback;

class TSymbol
{
public:
	std::string namelc;
	std::string name;
	uint32_t value;
	uint16_t stype;
	uint8_t opcode;
	TOpCallback cb;
	Poco::HashMap<std::string, TSymbol>locals;

	TSymbol()
	{
		locals.clear();
	};
};


class T65816Asm : public TFileProcessor
{
protected:
	bool passcomplete;
	bool casesen;
	bool relocatable;
	bool listing;
	bool skiplist; // used if lst is on, but LST opcode turns it off
	uint32_t errorct;
	uint32_t totalbytes;
	uint32_t lineno;
	uint32_t origin;
	uint8_t mx;
	uint8_t cpumode; // 0=6502, 1=65C02, 2=65816
	TSymbol *currentsym;
	std::vector<MerlinLine> lines;
	Poco::HashMap<std::string, TSymbol>opcodes;
	Poco::HashMap<std::string, TSymbol> macros;
	Poco::HashMap<std::string, TSymbol> symbols;
public:
	uint16_t pass;
	uint32_t currentpc;

	T65816Asm();
	virtual ~T65816Asm();

	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);
	virtual void complete(void);

	void insertOpcodes(void);
	void pushopcode(std::string op, uint8_t opcode, uint16_t flags, TOpCallback cb);

	int callOpCode(std::string op, MerlinLine &line);
	TSymbol *findSymbol(std::string sym);
	TSymbol *addSymbol(std::string sym, uint32_t val, bool replace);

	void initpass(void);
	void showSymbolTable(void);

	int evaluate(std::string expr, int64_t &value);

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

	int doEQU(MerlinLine &line, TSymbol &sym);
	int doXC(MerlinLine &line, TSymbol &sym);
	int doMX(MerlinLine &line, TSymbol &sym);

	int doBYTE(MerlinLine &line, TSymbol &sym);
	int doUNK(MerlinLine &line, TSymbol &sym);

};

class T65816Link : public TFileProcessor
{
public:
	T65816Link();
	virtual ~T65816Link();
	virtual void init(void);
	virtual int doline(int lineno, std::string line);
	virtual void process(void);

	virtual void complete(void);
};