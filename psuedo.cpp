#include "psuedo.h"

#define CLASS TPsuedoOp

CLASS::CLASS()
{

}

CLASS::~CLASS()
{

}


int CLASS::doDS(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	int res = 0;
	int32_t v = line.expr_value;
	if (line.eval_result!=0)
	{
		line.setError(errForwardRef);
	}
	else if ((v < 0) || ((a.PC.currentpc + v) >= 0x10000)) // no neg, or crossing bank bound
	{
		line.setError(errOverflow);
	}
	else
	{
		res = v;

		if (a.pass>0)
		{
			for (int i=0;i<v;i++)
			{
				line.outbytes.push_back(0x00);
			}
			line.outbytect=v;
		}

	}
	return (res);
}

int CLASS::doDUM(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	int res = 0;
	bool isdend = ((opinfo.opcode == P_DEND) ? true : false);

	if (!isdend)
	{
		a.dumstart = 1;
		a.dumstartaddr = line.expr_value;
	}
	else
	{
		a.dumstart = -1;
		if (a.PCstack.size() == 0)
		{
			line.setError(errBadDUMop);
			a.dumstart = 0;
		}
	}

	return (res);
}

int CLASS::doLST(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	std::string s;
	if (a.pass > 0)
	{
		s = Poco::toUpper(Poco::trim(line.operand));
		if ((s == "") || (s == "ON") || (line.expr_value > 0))
		{
			//printf("ON\n");
			a.skiplist = true;
			a.listing = true;
		}
		else if ((s == "OFF") || (line.expr_value == 0))
		{
			//printf("OFF\n");
			a.skiplist = true;
			a.listing = false;
		}
	}
	return (0);
}

int CLASS::ProcessOpcode(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	int res = 0;

	switch (opinfo.opcode)
	{
		default:
			res = -1; // undefined p-op
			line.setError(errUnimplemented);
			break;
		case P_DS:
			res = doDS(a, line, opinfo);
			break;
		case P_PUT:
		case P_USE:
			// both of these are handled by the input file processor, just allow them to be
			// processed with no errors here
			break;
		case P_DUM:
		case P_DEND:
			res = doDUM(a, line, opinfo);
			break;
		case P_ORG:
			if (line.operand.length()>0)
			{
				a.PC.orgsave=a.PC.currentpc;
				a.PC.currentpc = line.expr_value;
				line.startpc=line.expr_value;
			}
			else
			{
				a.PC.currentpc = a.PC.orgsave;
				line.startpc=a.PC.orgsave;
			}
			break;
		case P_SAV:
			a.savepath = line.operand;
			break;
		case P_LST:
			res = doLST(a, line, opinfo);
			break;
	}
	return (res);
}
