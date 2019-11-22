#pragma once
#include "asm.h"

#define CLASS TPsuedoOp

enum
{
	P_ORG = 1,
	P_LST,
	P_SAV,
	P_DUM,
	P_DEND,
	P_DS,
	P_PUT,
	P_USE,
	P_HEX,
	P_DATA,
	P_LUP,
	P_DO,
	P_TR,
    P_ASC,
    P_ERR,
    P_MAC,
    P_CAS,

	P_MAX
};

class CLASS
{
public:
	CLASS();
	~CLASS();
	uint32_t doShift(uint32_t value, uint8_t shift);

	int ProcessOpcode(T65816Asm  &a, MerlinLine &line, TSymbol &opinfo);
	int doLST(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDUM(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDS(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doHEX(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDATA(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doLUP(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDO(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doTR(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
    int doASC(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doMAC(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);

};

#undef CLASS