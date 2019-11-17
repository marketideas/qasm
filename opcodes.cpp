#include "asm.h"
#include "psuedo.h"

#define CLASS T65816Asm

void CLASS::setOpcode(MerlinLine &line, uint8_t op)
{
	if (pass > 0)
	{
		if (cpumode < MODE_65816) // instructions are valid if we are in 65816
		{
			uint8_t m = opCodeCompatibility[op];
			if ((m > 0) && (cpumode < MODE_65C02)) // if the instruction is non-zero, and we are in 6502 base mode, error
			{
				if (line.errorcode == 0) // don't replace other errors
				{
					line.setError(errIncompatibleOpcode);
				}
			}
		}
	}
	line.outbytes.push_back(op);
}

int CLASS::doPSEUDO(MerlinLine &line, TSymbol &sym)
{
	UNUSED(sym);

	int res;

	res = psuedoops->ProcessOpcode(*this, line, sym);
	return (res);
}

int CLASS::doXC(MerlinLine &line, TSymbol &sym)
{
	UNUSED(sym);

	std::string s;
	int res = 0;

	if (cpumode < MODE_65816)
	{
		cpumode++;
	}
	if (line.operand.length() > 0)
	{
		s = Poco::toUpper(line.operand);
		if (s == "OFF")
		{
			mx = 0x03;
			cpumode = MODE_6502;
		}
	}
	return (res);
}

int CLASS::doMX(MerlinLine &line, TSymbol &sym)
{
	UNUSED(sym);

	if (cpumode < MODE_65816)
	{
		line.setError(errIncompatibleOpcode);
	}
	else
	{
		mx = (uint8_t)(line.expr_value & 0x03);
		line.linemx = mx;
	}
	return (0);
}

int CLASS::doEQU(MerlinLine &line, TSymbol &sym)
{
	UNUSED(sym);
	int res = 0;
	TSymbol *s;
	if (line.lable.length() > 0)
	{
		//printf("EQU: |%s|\n",line.operand.c_str());
		bool isvar = (line.lable[0] == ']') ? true : false;

		if ((pass == 0) && (!isvar))
		{
			res = -1;
			//printf("EQU:  |%s| %08X\n", line.lable.c_str(), line.expr_value);
			s = addSymbol(line.lable, line.expr_value, true);
			if (s != NULL)
			{
				res = 0;
			}
		}
		else if (isvar)
		{
			res = -1;
			s = addVariable(line.lable, line.operand, true);
			if (s != NULL)
			{
				res = 0;
			}
		}
	}
	return (res);
}

int CLASS::doUNK(MerlinLine &line, TSymbol &sym)
{
	int res = -1;
	UNUSED(sym);

	res = 0;
	if (pass > 0)
	{
		line.setError(errIncomplete);

		//line.outbytes.push_back(0x00);
		line.outbytect = res;
	}
	return (res);
}

// PER is a special case because it does strange address calcs
int CLASS::doPER(MerlinLine &line, TSymbol &sym)
{
	int res;
	int32_t value = 0;;
	UNUSED(sym);

	res = 0;
	if ((line.addressmode == syn_abs) || (line.addressmode == syn_imm))
	{
		res = 3;
		if (pass > 0)
		{
			// SGQ should check under/over flows
			value = line.expr_value;
			value -= line.startpc + 3;

			//printf("addr calc=%08X %08X %08X\n",line.expr_value,line.startpc+3,value);
			setOpcode(line, sym.opcode);
			line.outbytes.push_back(value & 0xFF);
			line.outbytes.push_back((value >> 8) & 0xFF);

			line.outbytect = res;
		}
	}
	if (res == 0)
	{
		line.setError(errBadAddressMode);
	}
	return (res);
}

int CLASS::doMVN(MerlinLine &line, TSymbol &sym)
{
	int res;
	uint8_t op;
	UNUSED(sym);

	if (line.addressmode == syn_bm)
	{
		res = 3;
		if (pass > 0)
		{
			if (sym.opcode == 0)
			{
				op = 0x54;    // MVN
			}
			else
			{
				op = 0x44;    // MVP
			}

			int64_t value = -1;
			int x = evaluate(line, line.operand_expr2, value);
			if (x == 0)
			{
				value &= 0xFFFFFFFF;
			}
			else
			{
				value = 0xFFFFFFFF;
				line.setError(errBadOperand);
				line.errorText = line.operand_expr2;
			}

			setOpcode(line, op);
			line.outbytes.push_back(value & 0xFF);
			line.outbytes.push_back(line.expr_value & 0xFF);

			line.outbytect = res;
		}
	}
	else
	{
		line.setError(errBadAddressMode);
		res = 0;
	}
	return (res);
}

int CLASS::doNoPattern(MerlinLine &line, TSymbol &sym)
{
	// this handles a few opcodes that don't fit mathmatically in the opcode table
	// the 'sym.opcode' table identifies what each is:
	// STZ = 1
	// TSB = 2
	// TRB = 3
	UNUSED(sym);

	int res, i;
	uint8_t err;
	uint8_t op;
	uint8_t m = line.addressmode;

	res = 1;

	op = 0x00;
	err = errBadAddressMode;

	switch (sym.opcode)
	{
		case 1:		// STZ
			res++;
			op = (m == syn_abs ? 0x64 : op);
			op = (m == syn_absx ? 0x74 : op);

			if ((op != 0) && ((line.expr_value >= 0x100) || (line.flags&FLAG_FORCEABS)))
			{
				res++;
				op = (op == 0x64) ? 0x9C : op;
				op = (op == 0x74) ? 0x9E : op;
			}
			break;
		case 2:		// TSB
			res++;
			op = (m == syn_abs ? 0x04 : op);
			if ((op != 0) && ((line.expr_value >= 0x100) || (line.flags&FLAG_FORCEABS)))
			{
				res++;
				op = 0x0C;
			}
			break;
		case 3:		// TRB
			res++;
			op = (m == syn_abs ? 0x14 : op);
			if ((op != 0) && ((line.expr_value >= 0x100) || (line.flags&FLAG_FORCEABS)))
			{
				res++;
				op = 0x1C;
			}
			break;
		default:
			op = 0;
			err = errBadOpcode;
			break;
	}

	if (op == 0x00)
	{
		res = 0;
		line.setError(err);
	}
	if ((pass > 0) && (res > 0))
	{
		setOpcode(line, op);
		for (i = 0; i < (res - 1); i++)
		{
			line.outbytes.push_back(line.expr_value >> (8 * i));
		}
		line.outbytect = res;
	}
	return (res);
}

int CLASS::doAddress(MerlinLine &line, TSymbol &sym)
{

	// this routine uses the 'opcode' specifed in the sym.opcode field.
	// it also adds the number of bytes stored in the sym.stype field after doing an evaluation
	int res, i;

	res = 1 + sym.stype;
	if (pass > 0)
	{
		//line.setError(errIncomplete);
		setOpcode(line, sym.opcode);
		for (i = 0; i < (res - 1); i++)
		{
			line.outbytes.push_back(line.expr_value >> (i * 8));
		}
		line.outbytect = res;
	}
	// if these are REP or SEP, see if we need to track
	if ((trackrep) && ((sym.opcode == 0xC2) || (sym.opcode == 0xE2)))
	{
		if (cpumode >= MODE_65816)
		{
			//printf("trackrep: %02X\n",line.expr_value&0xFF);
			// SGQ - if evaluation has errors, this must cause an error here
			// because expr_value won't be valid during pass 0 and will screw
			// up MX
			uint8_t newmx = (line.expr_value & 0x30) >> 4;
			switch (sym.opcode)
			{
				case 0xC2: // REP
					mx &= ~newmx;
					break;
				case 0xE2: // SEP
					mx |= newmx;
					break;
			}
			line.linemx = mx;
		}

	}
	return (res);
}

int CLASS::doJMP(MerlinLine &line, TSymbol &sym)
{
	int res, i;
	bool err = false;
	uint8_t op;
	uint8_t optype = sym.opcode;
	uint8_t m = line.addressmode;

	res = 3;

	op = 0;

	if (optype & 0x02) // these are SUBROUTINES
	{
		op = (m == syn_abs ? 0x20 : op);
		op = (m == syn_diix ? 0xFC : op);
		if (!(optype & 0x01)) // jsl?
		{
			res++;
			op = 0x22;
		}
	}
	else
	{
		op = (m == syn_abs ? 0x4C : op);
		op = (m == syn_di ? 0x6C : op);
		op = (m == syn_diix ? 0x7C : op);
		op = (m == syn_dil ? 0xDC : op);

		if (!(optype & 0x01)) // JML?
		{
			op = (m == syn_abs ? 0x5C : op);
		}
		if ((op == 0xDC) || (op == 0x5C))
		{
			if (cpumode < MODE_65816)
			{
				op = 0;    // can't do these without an '816
			}
			if (op == 0x5C)
			{
				res++;
			}
		}

	}

	if (op == 0)
	{
		err = true;
	}

	if (err)
	{
		res = 0;
		line.setError(errBadAddressMode);
	}

	if ((pass > 0) && (res > 0))
	{
		setOpcode(line, op);
		for (i = 0; i < (res - 1); i++)
		{
			line.outbytes.push_back((line.expr_value >> (8 * i)) & 0xFF);
		}
		line.outbytect = res;
	}
	return (res);
}

int CLASS::doBRANCH(MerlinLine & line, TSymbol & sym)
{
	int res, i;

	res = 2;

	uint8_t op = (sym.opcode << 6) & 0xC0;
	op |= 0x10; // make it a branch opcode
	if (sym.opcode & 0x80)
	{
		op |= 0x20;
	}
	if (sym.opcode & 0x40) // BRA
	{
		op = 0x80;
	}
	if (sym.opcode & 0x20) // BRL
	{
		op = 0x82;
		res++;
	}

	if ((pass > 0) && (res > 0))
	{
		int64_t o64 = line.expr_value;
		int32_t o32 = (int32_t)(o64 & 0xFFFFFFFF);
		int32_t offset = o32 - line.startpc - res;

		bool err = false;
		if (res == 2) // short branch
		{
			if ((offset < -128) || (offset > 127))
			{
				err = true;
				op=0x00; // merlin does this
			}
		}
		else if (res == 3) // long branch
		{
			if ((offset < -32768) || (offset > 32767))
			{
				err = true;
				// for BRL, merlin DOES NOT kill the opcode
				//op=0x00; // merlin does this
			}
		}
		//printf("offset %d\n", offset);

		setOpcode(line, op);
		for (i = 0; i < (res - 1); i++)
		{
			uint8_t v=(offset >> (i*8));
			v=err?0x00:v;
			line.outbytes.push_back(v);
		}
		line.outbytect = res;
		if (err)
		{
			line.setError(errBadBranch);
		}
	}
	return (res);
}

// aaabbbcc

int CLASS::doBase6502(MerlinLine & line, TSymbol & sym)
{
	int res = 1;
	int i;
	uint8_t bytelen = 1;
	uint8_t cc;
	uint8_t op, amode;
	uint16_t opflags;
	bool err = false;
	uint16_t m = line.addressmode;

	//std::string opcode = Poco::toUpper(line.opcode);

	line.opflags = opflags = sym.stype;
	op = (sym.opcode << 5) & 0xE0;
	cc = (sym.stype >> 8) & 0x03;
	amode = 0xFF;


	if ((sym.stype & OP_C0) == OP_C0)
	{
		uint8_t cc = 0;
		uint8_t bbb = 0xFF;
		bbb = (m == syn_imm ? 0 : bbb);
		bbb = (m == syn_abs ? 1 : bbb);
		bbb = (m == syn_absx ? 5 : bbb);
		//printf("expr_value=%08X\n",line.expr_value);

		if ((sym.opcode == 1) && (m == syn_imm)) //BIT special case
		{
			cc = 0x01;
			op = 0x80;
			bbb = 0x02;
		}

		else if ((bbb > 0) && ((line.expr_value >= 0x100) || (line.flags&FLAG_FORCEABS)))
		{
			bbb |= 0x02;
			bytelen++;
		}
		op |= (bbb << 2) | cc;

		if (m == syn_imm)
		{
			int add = 0;
			switch (sym.opcode)
			{
				case 7:  // CPX
				case 6:  // CPY
				case 5:  // LDY
				case 4:  // STY
					if ((mx & 0x01) == 0)
					{
						add = 1;
					}
					break;
				case 1:  // BIT
					if ((mx & 0x02) == 0)
					{
						add = 1;
					}
					break;

			}
			bytelen += add;
		}
		goto out;
	}


	if (cc == 0x01)
	{
		switch (m)
		{
			case syn_diix: amode = 0; break;
			case syn_abs: amode = 1; break;
			case syn_imm: amode = 2; break;
			case syn_diiy: amode = 4; break;
			case syn_absx: amode = 5; break;
			case syn_absy: amode = 6; break;
			default:
				err = true;
				break;
		}
	}
	else if (cc == 0x02)
	{
		switch (m)
		{
			case syn_imm: amode = 0; break;
			case syn_abs: amode = 1; break;
			case syn_implied: amode = 2; bytelen = 0; break;
			case syn_absy:
				if ((opflags & OP_STX) == OP_STX)
				{
					amode = 5;
				}
				break;
			case syn_absx: amode = 5; break; // this is actually Y addressing because X register is used
			default:
				err = true;
				break;
		}

		if ((opflags & OP_STX) == OP_STX)
		{
			if (m == syn_implied)
			{
				err = true;
			}
			if (m == syn_imm)
			{
				if ((mx & 0x01) == 0)
				{
					bytelen++;
				}
			}
			if ( ((m==syn_absx) || (m==syn_diix))  && ((sym.opcode==4) || (sym.opcode==5)))  // these are STX,LDX
			{
				err=true;
			}
			if ((m == syn_absx) || (m == syn_abs) || (m == syn_absy))
			{
				if ((line.flags & FLAG_FORCEABS) || (line.expr_value >= 0x100))
				{
					bytelen++;
					amode += 2;
				}
			}
			if (cpumode >= MODE_65C02)
			{
				if (m == syn_implied)
				{
					if ((opflags & (OP_STX | OP_SPECIAL)) == (OP_STX | OP_SPECIAL))
					{
						if (sym.opcode == 0x07) // INC
						{
							err = false;
							op = 0x1A;
							bytelen = 0;
							goto out;
						}
						if (sym.opcode == 0x06)  // DEC
						{
							err = false;
							op = 0x3A;
							bytelen = 0;
							goto out;
						}
					}


				}
			}
		}
		else
		{
			if ((m == syn_absx) || (m == syn_abs))
			{
				if ((line.flags & FLAG_FORCEABS) || (line.expr_value >= 0x100))
				{
					bytelen++;
					amode += 2;
				}
			}

		}

		if (line.flags & FLAG_FORCELONG)
		{
			err = errBadAddressMode;
			//line.setError(errBadAddressMode);
		}
		goto outop;
	}

	if (m == syn_imm)
	{
		uint8_t  mask = 0x02;
		if (cc == 0x02) // the non accumulator
		{
			mask = 0x01;
		}
		if ((mx & mask) == 0)
		{
			bytelen++;
		}
	}
	else if ((m == syn_abs) || (m == syn_absx)
	         || (m == syn_absy))
	{
		if ((((line.flags & FLAG_DP) == 0) && ((line.flags & FLAG_FORCEDP) == 0))
		        || (line.flags & FLAG_FORCEABS)
		   )
		{
			bytelen++;
			if (amode != 6)
			{
				amode += 2;
			}
		}
		if (line.flags & FLAG_FORCELONG)
		{
			// we are in 65C02/02 mode, so long addressing not supported
			err = true;
		}
	}

	if (err)	// not a 6502 address mode
	{
		if (cpumode >= MODE_65816)
		{
			cc = 0x03;
			err = false;
			switch (m)
			{
				case syn_s: amode = 0; break;
				case syn_sy: amode = 4; break;
				case syn_di: cc = 0x02; amode = 4; break;
				case syn_iyl: amode = 5; break;
				case syn_dil: amode = 1; break;
				case syn_absx: amode = 7; break;
				case syn_abs: amode = 3; break;
				default:
					//printf("bad syn_mode=%d\n", m);
					err = true;
					break;
			}
			if (!err)
			{
				if ((m == syn_abs) || (m == syn_absx))
				{
					if (line.flags & FLAG_FORCELONG)
					{
						bytelen = 3;
					}

				}
			}
		}
	}


outop:
	op |= (amode & 0x07) << 2;
	op |= cc;

out:
	if (err)
	{
		line.setError(errBadAddressMode);
		//printf("bad address mode %d\n",line.addressmode);
		op = 0x00;
		res = 0;
		bytelen = 0;
	}

	res += bytelen;
	if ((pass > 0) && (res > 0))
	{
		setOpcode(line, op);
		for (i = 0; i < (res - 1); i++)
		{
			line.outbytes.push_back(line.expr_value >> (8 * i));
		}
		line.outbytect = res;
	}

	return (res);
}

int CLASS::doEND(MerlinLine & line, TSymbol & sym)
{
	UNUSED(sym);
	UNUSED(line);

	int res = 0;

	passcomplete = true;
	return (res);
}

int CLASS::doBYTE(MerlinLine & line, TSymbol & sym)
{
	UNUSED(sym);

	int res = 1;

	if (pass > 0)
	{
		setOpcode(line, sym.opcode);
		line.outbytect = res;
	}
	return (res);
}

void CLASS::insertOpcodes(void)
{
	pushopcode("=",   0x00, OP_PSUEDO, OPHANDLER(&CLASS::doEQU));
	pushopcode("EQU", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doEQU));
	pushopcode("EXT", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ENT", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ORG", P_ORG, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DSK", P_SAV, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("SAV", P_SAV, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DS",  P_DS, OP_PSUEDO,  OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("REL", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("OBJ", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("PUT", P_PUT, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("USE", P_USE, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("VAR", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("SAV", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("TYP", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("END", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doEND));
	pushopcode("DUM", P_DUM, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DEND", P_DEND, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("AST", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("CYC", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DAT", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("EXP", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("LST", P_LST, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("LSTDO", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("PAG", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("TTL", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("SKP", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("TR",  P_TR, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ASC", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DCI", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("INV", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("FLS", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("REV", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("STR", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DA",  P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DW",  P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DDB", P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DFB", P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DB",  P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ADR", P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ADRL", P_DATA, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("HEX", P_HEX, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DS",  0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("DO",  P_DO, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ELSE", P_DO, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("IF",  P_DO, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("FIN", P_DO, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("CHK", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("ERR", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("KBD", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("LUP", P_LUP, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("--^", P_LUP, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("MX", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doMX));
	pushopcode("PAU", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("SW", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("USR", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("XC", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doXC));
	pushopcode("MAC", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("EOM", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));
	pushopcode("<<<", 0x00, OP_PSUEDO, OPHANDLER(&CLASS::doPSEUDO));


	pushopcode("ADC", 0x03, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("AND", 0x01, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("ASL", 0x00, OP_ASL | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("BCC", 0x02, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BLT", 0x02, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BCS", 0x82, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BGE", 0x82, 0, OPHANDLER(&CLASS::doBRANCH));

	pushopcode("BEQ", 0x83, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BIT", 0x01, OP_C0, OPHANDLER(&CLASS::doBase6502));
	pushopcode("BMI", 0x80, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BNE", 0x03, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BPL", 0x00, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BRA", 0x40, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BRK", 0x00, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("BRL", 0x20, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BVC", 0x01, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("BVS", 0x81, 0, OPHANDLER(&CLASS::doBRANCH));
	pushopcode("CLC", 0x18, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("CLD", 0xD8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("CLI", 0x58, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("CLV", 0xB8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("CMP", 0x06, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("COP", 0x02, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("CPX", 0x07, OP_C0 | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("CPY", 0x06, OP_C0 | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("DEC", 0x06, OP_STX | OP_SPECIAL | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("DEX", 0xCA, OP_XY, OPHANDLER(&CLASS::doBYTE));
	pushopcode("DEY", 0x88, OP_XY, OPHANDLER(&CLASS::doBYTE));
	pushopcode("EOR", 0x02, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("INC", 0x07, OP_STX | OP_A | OP_SPECIAL, OPHANDLER(&CLASS::doBase6502));
	pushopcode("INX", 0xE8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("INY", 0xC8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("JML", 0x00, 0, OPHANDLER(&CLASS::doJMP));
	pushopcode("JMP", 0x01, 0, OPHANDLER(&CLASS::doJMP));
	pushopcode("JSL", 0x02, 0, OPHANDLER(&CLASS::doJMP));
	pushopcode("JSR", 0x03, 0, OPHANDLER(&CLASS::doJMP));
	pushopcode("LDA", 0x05, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("LDX", 0x05, OP_STX | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("LDY", 0x05, OP_C0 | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("LSR", 0x02, OP_ASL | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("MVN", 0x00, 0, OPHANDLER(&CLASS::doMVN));
	pushopcode("MVP", 0x01, 0, OPHANDLER(&CLASS::doMVN));
	pushopcode("NOP", 0xEA, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("ORA", 0x00, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("PEA", 0xF4, 2, OPHANDLER(&CLASS::doAddress));
	pushopcode("PEI", 0xD4, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("PER", 0x62, 2, OPHANDLER(&CLASS::doPER));
	pushopcode("PHA", 0x48, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHB", 0x8B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHD", 0x0B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHK", 0x4B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHP", 0x08, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHX", 0xDA, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PHY", 0x5A, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLA", 0x68, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLB", 0xAB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLD", 0x2B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLP", 0x28, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLX", 0xFA, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("PLY", 0x7A, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("REP", 0xC2, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("ROL", 0x01, OP_ASL | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("ROR", 0x03, OP_ASL | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("RTI", 0x40, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("RTL", 0x6B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("RTS", 0x60, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("SBC", 0x07, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("SEC", 0x38, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("SED", 0xF8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("SEI", 0x78, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("SEP", 0xE2, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("STP", 0xDB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("STA", 0x04, OP_STD | OP_A, OPHANDLER(&CLASS::doBase6502));
	pushopcode("STX", 0x04, OP_STX | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("STY", 0x04, OP_C0 | OP_XY, OPHANDLER(&CLASS::doBase6502));
	pushopcode("STZ", 0x01, OP_A, OPHANDLER(&CLASS::doNoPattern));
	pushopcode("TAX", 0xAA, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TAY", 0xA8, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TCD", 0x5B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TAD", 0x5B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TCS", 0x1B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TAS", 0x1B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TDC", 0x7B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TDA", 0x7B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TRB", 0x03, OP_A, OPHANDLER(&CLASS::doNoPattern));
	pushopcode("TSB", 0x02, OP_A, OPHANDLER(&CLASS::doNoPattern));
	pushopcode("TSC", 0x3B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TSA", 0x3B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TSX", 0xBA, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TXA", 0x8A, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TXS", 0x9A, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TXY", 0x9B, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TYA", 0x98, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("TYX", 0xBB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("WAI", 0xCB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("WDM", 0x42, 1, OPHANDLER(&CLASS::doAddress));
	pushopcode("XBA", 0xEB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("SWA", 0xEB, 0, OPHANDLER(&CLASS::doBYTE));
	pushopcode("XCE", 0xFB, 0, OPHANDLER(&CLASS::doBYTE));
}

#undef CLASS

