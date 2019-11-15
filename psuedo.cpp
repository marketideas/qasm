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
	if (line.eval_result != 0)
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

		if (a.pass > 0)
		{
			for (int32_t i = 0; i < v; i++)
			{
				line.outbytes.push_back(0x00);
			}
			line.outbytect = v;
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
	if (a.pass > 0)
	{
		std::string s = Poco::toUpper(Poco::trim(line.operand));
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

int CLASS::doHEX(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	int res = 0;
	std::vector<std::string> values;
	values.clear();

	std::string os = Poco::toUpper(Poco::trim(line.operand));
	std::string vs = "0123456789ABCDEF";
	std::string hex = "";

	for ( uint32_t i = 0; i < os.length(); ++i )
	{
		char c = os[i];

		// Check for a comma if needed, and continue to next char if found
		if ( hex.length() == 0 && c == ',' )
		{
			continue;
		}

		if ( vs.find(c) == std::string::npos )
		{
			line.setError(errBadOperand);
			return -1;
		}

		// Got a good char, append to hex string and see if we've got a byte
		hex.append(1, c);
		if ( hex.length() == 2 )
		{
			// Got 2 chars (1 byte), so store in values array
			values.push_back(hex);
			hex.clear();
		}
	}

	// We can't have an odd character dangling around!
	if ( hex.size() != 0 )
	{
		line.setError(errOverflow);
		return -1;
	}

	int byteCnt = (int)values.size();
	a.PC.currentpc += byteCnt;

	if (a.pass > 0)
	{
		for ( uint32_t i = 0; i < values.size(); ++i )
		{
			std::string s = "$";
			s.append(values[i]);
			int64_t v;
			if ( 0 == a.evaluate(line, s, v) )
			{
				line.outbytes.push_back((uint8_t)v);
			}
		}
		line.outbytect = byteCnt;
	}
	else
	{
		line.pass0bytect = byteCnt;
	}
	return res;
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
			if (line.operand.length() > 0)
			{
				a.PC.orgsave = a.PC.currentpc;
				a.PC.currentpc = line.expr_value;
				line.startpc = line.expr_value;
			}
			else
			{
				a.PC.currentpc = a.PC.orgsave;
				line.startpc = a.PC.orgsave;
			}
			break;

		case P_SAV:
			a.savepath = line.operand;
			break;

		case P_LST:
			res = doLST(a, line, opinfo);
			break;

		case p_HEX:
			res = doHEX(a, line, opinfo);
			break;
	}
	return (res);
}
