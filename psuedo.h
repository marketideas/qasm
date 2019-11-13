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

	P_MAX
};

class CLASS
{
public:
	CLASS();
	~CLASS();
	int ProcessOpcode(T65816Asm  &a, MerlinLine &line, TSymbol &opinfo);
	int doLST(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDUM(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);
	int doDS(T65816Asm &a, MerlinLine &line, TSymbol &opinfo);



};

#undef CLASS
