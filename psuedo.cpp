#include "psuedo.h"
#include "eval.h"

#define CLASS TPsuedoOp

CLASS::CLASS()
{

}

CLASS::~CLASS()
{

}


int CLASS::doDO(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	TEvaluator eval(a);

	int64_t eval_result = 0;
	uint8_t shift;
	uint32_t result32;
	int res = 0;
	int err = 0;

	std::string op = Poco::toUpper(line.opcode);
	std::string oper = line.operand_expr;
	result32 = 0xFFFFFFFF;

	if (op == "IF")
	{
		if (oper == "")
		{
			err = errIllegalCharOperand;
		}
		goto out;
	}
	if (op == "DO")
	{

		a.DOstack.push(a.curDO);

		if (oper == "")
		{
			err = errIllegalCharOperand;
			a.curDO.doskip = false;
			goto out;
		}

		shift = 0;
		eval_result = 0;
		int x = eval.evaluate(line.operand_expr, eval_result, shift);

		if (x < 0)
		{
			a.curDO.doskip = false;
			err = errBadLabel;
			if (a.pass == 0)
			{
				err = errForwardRef;
			}
			goto out;
		}

		result32 = eval_result & 0xFFFFFFFF;
		a.curDO.doskip = (result32 != 0) ? false : true;

		goto out;
	}

	if (op == "ELSE")
	{
		if (a.DOstack.size() > 0)
		{
			//line.flags |= FLAG_NOLINEPRINT;
			a.curDO.doskip = !a.curDO.doskip;
		}
		else
		{
			err = errUnexpectedOp;
		}
		goto out;
	}

	if (op == "FIN")
	{
		//line.flags |= FLAG_NOLINEPRINT;

		if (a.DOstack.size() > 0)
		{
			a.curDO = a.DOstack.top();
			a.DOstack.pop();
		}
		else
		{
			// kind of a silent error here, just make sure we reinitialize
			err = errUnexpectedOp;
			a.curDO.doskip = false;
		}
		goto out;
	}

out:
	//printf("DO eval: %08X %s\n", result32, a.curDO.doskip ? "true" : "false");

	if (err > 0)
	{
		line.setError(err);
	}
	return (res);
}

int CLASS::doLUP(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	TEvaluator eval(a);

	int64_t eval_result = 0;
	uint8_t shift;
	int lidx, len;
	int res = 0;
	int err = 0;

	std::string op = Poco::toUpper(line.opcode);

	if (op == "LUP")
	{
		line.flags |= FLAG_NOLINEPRINT;
		len = line.lineno - 1; // MerlinLine line numbers are +1 from actual array idx
		if (len >= 0)
		{

			shift = 0;
			eval_result = 0;
			int x = eval.evaluate(line.operand_expr, eval_result, shift);

			a.LUPstack.push(a.curLUP);

			a.curLUP.lupoffset = len;
			a.curLUP.lupct = eval_result & 0xFFFF; // evaluate here
			a.curLUP.luprunning++;

			if ((x < 0) || (eval_result <= 0) || (eval_result > 0x8000))
			{
				// merlin just ignores LUP if the value is out of range
				a.curLUP.lupct = 0;
				a.curLUP.lupskip = true;
			}
		}
		else
		{
			err = errUnexpectedOp;
		}
	}

	if (op == "--^")
	{
		line.flags |= FLAG_NOLINEPRINT;

		if (a.curLUP.luprunning > 0)
		{
			lidx = line.lineno - 1;
			len = lidx - a.curLUP.lupoffset - 1;

			if (a.curLUP.lupct > 0)
			{
				a.curLUP.lupct--;
				if (a.curLUP.lupct != 0)
				{
					a.lineno = a.curLUP.lupoffset;
					goto out;
				}
			}
			// kind of a silent error here, just make sure we reinitialize
			a.curLUP.luprunning = 0;
			a.curLUP.lupct = 0;
			a.curLUP.lupskip = false;

			//printf("start=%d end=%d len=%d\n", a.curLUP.lupoffset, lidx, len);
			if (a.LUPstack.size() > 0)
			{
				a.curLUP = a.LUPstack.top();
				a.LUPstack.pop();
			}
			else
			{
				err = errUnexpectedOp;
			}
		}
		else
		{
			a.curLUP.lupskip = false;
			// SGQ - found a '--^' without a LUP, should we just ignore?
			//err = errUnexpectedOp;
		}
	}

out:
	if (err > 0)
	{
		line.setError(err);
	}
	return (res);
}

constexpr unsigned int strhash(const char *str, int h = 0)
{
	return !str[h] ? 5381 : (strhash(str, h + 1) * 33) ^ str[h];
}

int CLASS::doDATA(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);
	TEvaluator eval(a);

	int i;
	int outct = 0;
	int wordsize = 2;
	int endian = 0;
	std::string oper = line.operand;
	std::string op = Poco::toUpper(Poco::trim(line.opcode));

	//printf("DFB TOK1 : |%s|\n", oper.c_str());

	Poco::StringTokenizer tok(oper, ",", Poco::StringTokenizer::TOK_TRIM |
	                          Poco::StringTokenizer::TOK_IGNORE_EMPTY);


	const char *ptr = (const char *)op.c_str();
	switch (strhash(ptr) )
	{
		case strhash((const char *)"DA"):
		case strhash((const char *)"DW"):
			wordsize = 2;
			break;
		case strhash((const char *)"DDB"):
			wordsize = 2;
			endian = 1;
			break;
		case strhash((const char *)"DFB"):
		case strhash((const char *)"DB"):
			wordsize = 1;
			break;
		case strhash((const char *)"ADR"):
			wordsize = 3;
			break;
		case strhash((const char *)"ADRL"):
			wordsize = 4;
			break;
		default:
			wordsize = 0;
			break;
	}

	for (auto itr = tok.begin(); itr != tok.end(); ++itr)
	{
		//evaluate each of these strings, check for errors on pass 2

		std::string expr = *itr;

		//printf("DFB TOK : |%s|\n", expr.c_str());

		int64_t eval_result = 0;
		uint8_t shift;
		int r;
		uint8_t b;

		if (expr.length() > 0)
		{
			if (expr[0] == '#')
			{
				expr[0] = ' ';
				expr = Poco::trim(expr);
			}
			shift = 0;
			eval_result = 0;
			//printf("DFB EVAL: |%s|\n", expr.c_str());
			r = eval.evaluate(expr, eval_result, shift);
			if (r < 0)
			{
				//printf("error\n");
				if (a.pass > 0)
				{
					line.setError(errBadEvaluation);
				}
			}
			if (shift == '>')
			{
				eval_result = (eval_result) & 0xFF;
			}
			if (shift == '<')
			{
				eval_result = (eval_result >> 8) & 0xFF;
			}
			else if ((shift == '^') || (shift == '|'))
			{
				eval_result = (eval_result >> 16) & 0xFF;
			}
		}

		outct += wordsize;
		if (a.pass > 0)
		{
			if (!endian) // little endian
			{
				for (i = 0; i < wordsize; i++)
				{
					b = (eval_result >> (8 * i)) & 0xFF;
					line.outbytes.push_back(b);
					//printf("%02X\n",b);
				}
			}
			else
			{
				// big endian
				for (i = 0; i < wordsize; i++)
				{
					b = (eval_result >> ((wordsize - 1 - i) * 8)) & 0xFF;
					line.outbytes.push_back(b);
					//printf("%02X\n",b);
				}

			}
		}
	}
	line.outbytect = outct;
	return (outct);
}

int CLASS::doDS(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

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

		line.datafillbyte = line.eval_result & 0xFF;
		line.datafillct = v;

	}
	return (res);
}

int CLASS::doDUM(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

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
	UNUSED(opinfo);

	std::string s;
	if (a.pass > 0)
	{
		s = Poco::toUpper(Poco::trim(line.operand_expr));
		if (s == "")
		{
			a.listing = true;
			a.skiplist = true;
		}
		else if (s == "RTN")
		{
			if (a.LSTstack.size())
			{
				a.listing = a.LSTstack.top();
				a.LSTstack.pop();
			}
		}
		else if ((s == "ON") || (line.expr_value > 0))
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

int CLASS::doTR(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	std::string s;
	if (a.pass > 0)
	{
		s = Poco::toUpper(Poco::trim(line.operand_expr));
		if (s == "ADR")
		{
			a.truncdata |= 0x03;
		}
		else if ((s == "ON") || (line.expr_value > 0))
		{
			a.truncdata |= 0x01;;
		}
		else if ((s == "OFF") || (line.expr_value == 0))
		{
			a.truncdata = 0x00;
		}
	}
	return (0);
}

char hexVal( char c )
{
    char v = -1;

    if ((c >= '0') && (c <= '9'))
    {
        v = c - '0';
    }
    else if ((c >= 'a') && (c <= 'f'))
    {
        v = c - 'a' + 10;
    }
    else if ((c >= 'A') && (c <= 'F'))
    {
        v = c - 'A' + 10;
    }

    return v;
}

int CLASS::doHEX(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

    std::string os = Poco::trim(line.operand);

	uint32_t bytect = 0;
	uint8_t b = 0;
	uint8_t ct = 0;

	for ( uint32_t i = 0; i < os.length(); ++i )
	{
		char c = os[i];

		if (c == ',')
		{
			continue;
		}
        char hv = hexVal(c);
		if( hv < 0 )
		{
			line.setError(errIllegalCharOperand);
			bytect = 0;
			goto out;
		}

		// Got a good char, append to hex string and see if we've got a byte
		switch (ct)
		{
			case 0:
				b = (hv << 4);
				break;
			case 1:
				b |= hv;
				break;
		}
		ct = (ct + 1) & 0x01;
		if (!ct)
		{
			if (a.pass > 0)
			{
				line.outbytes.push_back(b);
			}
			b = 0;
			bytect++;
		}
	}

	if (ct & 0x01) // we got an odd number of nibbles
	{
		line.setError(errBadOperand);
		bytect = 0;
	}
out:
	line.outbytect = bytect;
	return bytect;
}

int CLASS::doASC(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

    std::string os = line.operand;

	uint32_t bytect = 0;
	uint8_t b = 0;
	uint8_t ct = 0;
    char delimiter = 0;
    uint32_t ss = 0;

	for ( uint32_t i = 0; i < os.length(); ++i )
	{
        char c = os[i];

        // are we inside a delimited string?
        if( delimiter )
        {
            if( c == delimiter )
            {
                bytect += (i - ss);

                if( a.pass > 0 )
                {
                    for( ; ss < i; ++ss )
                    {
                        c = os[ss];
                        if( delimiter >= '\'' )
                            c |= 0x80;
                        line.outbytes.push_back(c);
                    }
                }
                
                delimiter = 0;
                ss = 0;
                continue;
            }
        }
        else
        {
            // No, check for seperator characters
            if( c == ',' || c == ' ' )
            {
                continue;
            }

            // Is this a hex char?
            char hv = hexVal(c);
            if( hv < 0 )
            {
                // if not a hex value, then consider the character to be the string delimiter
                delimiter = c;
                ss = i + 1;
                continue;
            }

            // Got a hex char, append to hex string and see if we've got a byte
            switch (ct)
            {
                case 0:
                    b = (hv << 4);
                    break;
                case 1:
                    b |= hv;
                    break;
            }
            ct = (ct + 1) & 0x01;
            if (!ct)
            {
                if (a.pass > 0)
                {
                    line.outbytes.push_back(b);
                }
                b = 0;
                bytect++;
            }
        }
	}

    if( delimiter || (ct & 0x01) ) // error w/unterminated string or we got an odd number of nibbles in hex value
	{
		line.setError(errBadOperand);
		bytect = 0;
	}

	line.outbytect = bytect;
	return bytect;

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
			line.flags |= FLAG_FORCEADDRPRINT;

			break;
		case P_ORG:
			if (line.operand_expr.length() > 0)
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
			line.flags |= FLAG_FORCEADDRPRINT;
			break;
		case P_SAV:
			a.savepath = a.processFilename(line.operand, Poco::Path::current(), 0);
			break;
		case P_LST:
			res = doLST(a, line, opinfo);
			break;
		case P_HEX:
			res = doHEX(a, line, opinfo);
			break;
		case P_DATA:
			res = doDATA(a, line, opinfo);
			break;
		case P_LUP:
			res = doLUP(a, line, opinfo);
			break;
		case P_DO:
			res = doDO(a, line, opinfo);
			break;
		case P_TR:
			res = doTR(a, line, opinfo);
			break;
        case P_ASC:
            res = doASC(a, line, opinfo);
            break;
	}
	return (res);
}
