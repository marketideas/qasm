#include "psuedo.h"
#include "eval.h"

#define CLASS TPsuedoOp

CLASS::CLASS()
{

}

CLASS::~CLASS()
{

}


uint32_t CLASS::doShift(uint32_t value, uint8_t shift)
{
	if (shift == '<')
	{
		value = (value) & 0xFFFFFF;
	}
	if (shift == '>')
	{
		value = (value >> 8) & 0xFFFFFF;
	}
	else if ((shift == '^') || (shift == '|'))
	{
		value = (value >> 16) & 0xFFFFFF;
	}
	return (value);
}

int CLASS::doDO(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	TEvaluator eval(a);
	eval.allowMX = true; // allow the built in MX symbol

	int64_t eval_value = 0;
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
		eval_value = 0;
		int x = eval.evaluate(line.operand_expr, eval_value, shift);

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

		result32 = eval_value & 0xFFFFFFFF;
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

int CLASS::doMAC(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	int res = 0;
	int err = 0;

	std::string op = Poco::toUpper(line.opcode);
	if (op == "MAC")
	{
		if (a.expand_macrostack.size() > 0)
		{
			line.flags |= FLAG_NOLINEPRINT;
			goto out;
		}
		if (line.lable.length() == 0)
		{
			err = errBadLabel;
			goto out;
		}
		a.macrostack.push(a.currentmacro);
		a.currentmacro.clear();

		a.currentmacro.name = line.lable;
		a.currentmacro.lcname = Poco::toLower(line.lable);
		a.currentmacro.start = line.lineno;
		a.currentmacro.running = true;

		if (!a.casesen)
		{
			a.currentmacro.name = Poco::toUpper(a.currentmacro.name);
		}

		if (a.pass == 0)
		{
		}
		else
		{
			// don't need to do anything on pass > 0
		}
		//printf("macro stack size=%zu\n",a.macrostack.size());
	}
	else if (op == ">>>")
	{
		// don't do anything here, let the macro call handler stuff do ths (asm.cpp)
	}
	else // it is EOM or <<<
	{
		while (a.macrostack.size() > 0)
		{
			a.currentmacro.end = line.lineno - 1;
			a.currentmacro.len = 0;
			if (a.currentmacro.end >= a.currentmacro.start)
			{
				a.currentmacro.len = a.currentmacro.end - a.currentmacro.start;
				//printf("macro len=%d\n",a.currentmacro.len);
			}
			a.currentmacro.running = false;

			std::pair<std::string, TMacro> p(a.currentmacro.name, a.currentmacro);
			//printf("macro insert %s\n",a.currentmacro.name.c_str());
			a.macros.insert(p);

			a.currentmacro = a.macrostack.top();
			a.macrostack.pop();
		}
#if 0
		else
		{
			err = errUnexpectedOp;
			goto out;
		}
#endif
	}
out:
	if (err)
	{
		line.setError(err);
	}
	return (res);
}

int CLASS::doLUP(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	TEvaluator eval(a);

	int64_t eval_value = 0;
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
			eval_value = 0;
			int x = eval.evaluate(line.operand_expr, eval_value, shift);

			a.LUPstack.push(a.curLUP);

			if (a.expand_macrostack.size() > 0)
			{
				a.curLUP.lupoffset = a.expand_macro.currentline;
			}
			else
			{
				a.curLUP.lupoffset = len;
			}
			a.curLUP.lupct = eval_value & 0xFFFF; // evaluate here
			a.curLUP.luprunning++;

			if ((x < 0) || (eval_value <= 0) || (eval_value > 0x8000))
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
					if (a.expand_macrostack.size() > 0)
					{
						a.expand_macro.currentline = a.curLUP.lupoffset;
					}
					else
					{
						a.lineno = a.curLUP.lupoffset;
					}
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


	line.eval_result = 0; // since this is an data  p-op, clear the global 'bad operand' flag

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

		int64_t eval_value = 0;
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
			eval_value = 0;
			//printf("DFB EVAL: |%s|\n", expr.c_str());
			r = eval.evaluate(expr, eval_value, shift);
			if (r < 0)
			{
				//printf("error %d\n",r);
				if (a.pass > 0)
				{
					line.setError(errBadEvaluation);
				}
			}
			eval_value = (uint64_t)doShift((uint32_t)eval_value, shift);
		}

		outct += wordsize;
		if (a.pass > 0)
		{
			if (!endian) // little endian
			{
				for (i = 0; i < wordsize; i++)
				{
					b = (eval_value >> (8 * i)) & 0xFF;
					line.outbytes.push_back(b);
					//printf("%02X\n",b);
				}
			}
			else
			{
				// big endian
				for (i = 0; i < wordsize; i++)
				{
					b = (eval_value >> ((wordsize - 1 - i) * 8)) & 0xFF;
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

	TEvaluator eval(a);

	int64_t eval_value = 0;
	uint8_t shift;

	line.eval_result = 0; // since this is an data  p-op, clear the global 'bad operand' flag
	line.flags |= FLAG_FORCEADDRPRINT;
	std::string s;
	Poco::StringTokenizer tok(line.operand, ",", Poco::StringTokenizer::TOK_TRIM |
	                          Poco::StringTokenizer::TOK_IGNORE_EMPTY);

	int32_t datact = 0;
	uint8_t fill = 0x0;
	bool pagefill = false;
	int32_t v = 0;


	int ct = 0;
	for (auto itr = tok.begin(); itr != tok.end(); ++itr)
	{
		s = *itr;
		if (ct == 0)
		{
			if (s == "\\")
			{
				pagefill = true;
			}
			else
			{

				shift = 0;
				eval_value = 0;
				int x = eval.evaluate(s, eval_value, shift);
				if (x < 0)
				{
					line.setError(errBadOperand);
					goto out;
				}
				eval_value = (uint64_t)doShift((uint32_t)eval_value, shift);
				datact = eval_value & 0xFFFF;
				if (datact < 0)
				{
					line.setError(errBadOperand);
					goto out;
				}
			}
		}
		else if (ct == 1)
		{

			shift = 0;
			eval_value = 0;
			int x = eval.evaluate(s, eval_value, shift);
			if (x < 0)
			{
				line.setError(errBadOperand);
				goto out;
			}
			eval_value = (uint64_t)doShift((uint32_t)eval_value, shift);
			fill = eval_value & 0xFF;
		}
		else if (ct > 1)
		{
			line.setError(errBadOperand);
		}
		ct++;
	}

	line.datafillbyte =  fill;
	v = datact;
	if (pagefill)
	{
		v = line.startpc & 0xFF;
		v = 0x100 - v;
	}
	line.datafillct = (uint16_t)v & 0xFFFF;
	res = line.datafillct;

out:
	//printf("res=%d %04X\n",res,res);
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

	line.eval_result = 0; // since this is an data  p-op, clear the global 'bad operand' flag

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
		if ( hv < 0 )
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

// the handler for STR,STRL,REV,FLS,INV,DCI,ASC
int CLASS::doASC(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	UNUSED(opinfo);

	std::string os = line.operand;
	std::string op = Poco::toUpper(line.opcode);

	uint8_t firstdelim = 0;
	uint32_t bytect = 0;
	uint8_t b = 0;
	uint8_t b1;
	uint8_t ct = 0;
	uint8_t delimiter = 0;
	uint32_t ss = 0;
    uint32_t lastdelimidx = 0;

	std::vector<uint8_t> bytes;

	line.eval_result = 0; // since this is an ASCII p-op, clear the global 'bad operand' flag
	for ( uint32_t i = 0; i < os.length(); ++i )
	{
		uint8_t c = os[i];

		// are we inside a delimited string?
		if ( delimiter )
		{
			if ( c == delimiter )
			{
				bytect += (i - ss);

				if ( a.pass > 0 )
				{
					for ( ; ss < i; ++ss )
					{
						c = os[ss];
						if ( delimiter >= '\'' )
						{
							c &= 0x7F;
						}
						else
						{
							c |= 0x80;
						}

						bytes.push_back(c);
                        lastdelimidx = (uint32_t)(bytes.size() - 1);
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
			if ( c == ',' || c == ' ' )
			{
				continue;
			}

			// Is this a hex char?
			char hv = hexVal(c);
			if ( hv < 0 )
			{
				// if not a hex value, then consider the character to be the string delimiter
				delimiter = c;
				if( ! firstdelim )
				{
					firstdelim = c;
				}
				else if (delimiter != firstdelim)
				{
					line.setError(errIllegalCharOperand);
				}
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
					bytes.push_back(b);
				}
				b = 0;
				bytect++;
			}
		}
	}

	if ( delimiter || (ct & 0x01) ) // error w/unterminated string or we got an odd number of nibbles in hex value
	{
		line.setError(errBadOperand);
		bytect = 0;
	}
	else  // now figure out what psuedo op we are and transfer the data to outbytect
	{
		uint32_t i;
		bool reverse = false;
		bool dci = false;
		uint8_t andval = 0xFF;
		uint8_t orval = 0x00;
		uint8_t addlen = 0;
		uint32_t truebytect = (uint32_t)bytes.size();
		const char *ptr = (const char *)op.c_str();
		//printf("bytect=%d bytes.size()=%zu\n",bytect,bytes.size());
		switch (strhash(ptr) )
		{
			case strhash((const char *)"STRL"):
				addlen = 2;
				break;
			case strhash((const char *)"STR"):
				addlen = 1;
				break;
			case strhash((const char *)"REV"):
				reverse = true;
				break;
			case strhash((const char *)"FLS"):
				andval = (uint8_t)~0xC0;
				orval = (uint8_t)0x40;
				break;
			case strhash((const char *)"INV"):
				andval = (uint8_t)~0xC0;
				orval = 0x00;
				break;
			case strhash((const char *)"DCI"):
				dci = true;
				break;
			case strhash((const char *)"ASC"):
				break;
			default:
				line.setError(errBadOpcode);
				bytect = 0;
				addlen = 0;
				break;
		}
		if (a.pass > 0)
		{
			for (i = 0; i < addlen; i++)  // if a string, push length
			{
				line.outbytes.push_back((truebytect >> (i * 8)) & 0xFF);
			}
			for (i = 0; i < truebytect; i++)
			{
				if (reverse)
				{
					b = bytes[bytect - i - 1];
				}
				else
				{
					b = bytes[i];
				}

                b1 = b & 0x7F;
				if ((andval != 0xFF) || (orval != 0x00))
				{
					b = b1;
				}

				if ((b1 < 0x60))
				{
					b &= andval; // strip whatever bits needed to flash or invert
					b |= orval;
				}

				if (dci && (i == lastdelimidx))
				{
                    //lr - Merlin only toggles the high bit of string chars, not hex values
                    // 8D,'Hello',8D,'there',8D becomes 8D 48 65 6C 6C 6F 8D 74 68 65 72 E5
                    //
                    // The DCI instruction is documented to work like this on page 108
                    // (regardless of how this effects the desired lda, (bpl/bmi) functionality)
                    //
                    // I am now checking the delimiter character to determine hi/lo toggle (reversed)
                    // and am tracking the index to the last delimited character put into 'bytes'.
                    // This produces the same results as Merlin 16+ in my testing.
                    if ( firstdelim >= '\'' )
					{
						b |= 0x80;
					}
					else
					{
						b &= 0x7F;
					}
				}
				line.outbytes.push_back(b);
			}
		}
		bytect = bytect + addlen;

	}
	//printf("XXX bytect=%d bytes.size()=%zu\n",bytect,bytes.size());

	line.outbytect = bytect;
	return bytect;

}

int CLASS::ProcessOpcode(T65816Asm &a, MerlinLine &line, TSymbol &opinfo)
{
	int res = 0;
	std::string s;

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

#if 0
			// Merlin32 seems to have a bug where ORG seems like it can only be 16 bits
			if ((line.syntax & SYNTAX_MERLIN32) == SYNTAX_MERLIN32)
			{
				// so clear the bank word in all variables
				a.PC.orgsave &= 0xFFFF;
				a.PC.currentpc &= 0xFFFF;
				line.startpc &= 0xFFFF;
			}
#endif

			line.flags |= FLAG_FORCEADDRPRINT;
			break;
		case P_SAV:
			a.savepath = a.processFilename(line.operand, Poco::Path::current(), 0);
			break;
		case P_CAS:
			s = Poco::toUpper(line.operand);
			if (s == "SE")
			{
				a.casesen = true;
			}
			if (s=="IN")
			{
				a.casesen=false;
			}
			res = 0;
			break;
		case P_MAC:
			res = doMAC(a, line, opinfo);
			break;
		case P_ERR:
			if (a.pass > 0)
			{
				if ((line.expr_value != 0) || (line.eval_result < 0))
				{
					line.setError(errErrOpcode);
					//a.passcomplete=true; // terminate assembly
				}
			}
			res = 0;
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
