#define ADD_ERROR_STRINGS
#include "asm.h"
#include "eval.h"

#define CLASS MerlinLine


CLASS::CLASS()
{
	clear();
}

CLASS::CLASS(std::string line)
{
	clear();
	set(line);
}


void CLASS::setError(uint32_t ecode)
{
	errorcode = ecode;
}

void CLASS::print(uint32_t lineno)
{
	int i, l;


	l = outbytect;
	if (l > 4)
	{
		l = 4;
	}

	//if ((opflags&OP_STD)!=OP_STD)
	if ((opcodelower != "inc") && (opcodelower != "ldx") && (opcodelower != "stx"))
	{
		//return;
	}
	if (errorcode > 0)
	{
		if (errorcode >= errFatal)
		{
			SetColor(CL_WHITE | CL_BOLD | BG_RED);
		}
		else
		{
			SetColor(CL_YELLOW | CL_BOLD | BG_NORMAL);
		}
	}
	else
	{
		SetColor(CL_WHITE | CL_BOLD | BG_NORMAL);
	}
	bool empty = false;
	if ((lable == "") && (opcode == "") && (operand == ""))
	{
		empty = true;
	}
	int b = 4;

	printf("%02X ", addressmode);
	printf("%6d", lineno + 1);
	if (!empty)
	{
		printf(" %06X:", startpc);
	}
	else
	{
		printf("        ");
	}

	for (i = 0; i < l; i++)
	{
		printf("%02X ", outbytes[i]);
	}
	for (i = l; i < b; i++)
	{
		printf("   ");
	}

	if (empty)
	{
		printf("%s", comment.c_str());
	}
	else
	{
		printf("%-12s %-8s %-10s ", lable.c_str(), opcode.c_str(), operand.c_str());
		if (errorcode > 0)
		{
			printf(":[Error] %s", errStrings[errorcode].c_str());
		}
		else
		{
			printf("%s", comment.c_str());
		}
	}
	if (errorcode > 0)
	{
		SetColor(CL_NORMAL | BG_NORMAL);
	}
	printf("\n");

}

void CLASS::clear()
{
	syntax = SYNTAX_MERLIN;
	lable = "";
	opcode = "";
	opcodelower = "";
	operand = "";
	comment = "";
	operand_expr = "";
	addrtext = "";
	bytect = 0;
	opflags = 0;
	pass0bytect = 0;
	startpc = 0;
	errorcode = 0;
	inbytect = 0;
	outbytect = 0;
	outbytes.clear();
	addressmode = 0;
	expr_value = 0;
	flags = 0;
	outbytes.clear();
}

void CLASS::set(std::string line)
{
	int state = 0;
	int l = line.length();
	int i = 0;
	char c,delim;

	clear();

	//printf("line: |%s|\n", line.c_str());
	while (i < l)
	{
		c = line[i++];
		//printf("state: %d\n",state);
		switch (state)
		{
			case 0:  // start of line state
				if ((c == ';') || (c == '*'))
				{
					comment += c;
					state = 7;
				}
				else if (c > ' ')
				{
					lable += c;
					state = 1;
				}
				else
				{
					state = 2;
				};
				break;
			case 1:   // read in entire lable until whitespace
				if (c > ' ')
				{
					lable += c;
				}
				else
				{
					state = 2;
				}
				break;
			case 2:  // read whitespace between label and opcode
				if (c == ';')
				{
					comment += c;
					state = 7;
				}
				else if (c > ' ')
				{
					opcode += c;
					state = 3;
				}
				break;
			case 3:
				if (c > ' ')
				{
					opcode += c;
				}
				else
				{
					state = 4;
				}
				break;
			case 4:  // read whitespace between opcode and operand
				if (c == ';')
				{
					comment += c;
					state = 7;
				}
				else if (c > ' ')
				{
					operand += c;
					if (c == '\'')
					{
						state = 8;
					}
					else
					{
						state = 5;
					}
				}
				break;
			case 5:
				if ((c == '\'') || (c=='"'))
				{
					delim=c;
					operand += c;
					state = 8;
				}
				else if (c > ' ')
				{
					operand += c;
				}
				else
				{
					state = 6;
				}
				break;
			case 6:
				if (c > ' ')
				{
					comment += c;
					state = 7;
				}
				break;
			case 7:
				comment += c;
				break;
			case 8:
				if (c == delim)
				{
					operand += c;
					state = 5;
				}
				else
				{
					operand += c;
				}
				break;
		}
	}
	opcodelower = Poco::toLower(opcode);
}

#undef CLASS
#define CLASS TFileProcessor

CLASS::CLASS()
{
}

CLASS::~CLASS()
{
}

void CLASS::errorOut(uint16_t code)
{
	printf("error: %d\n", code);
}

void CLASS::init(void)
{
	syntax = SYNTAX_MERLIN;
}

void CLASS::complete(void)
{
}

void CLASS::process(void)
{

}
int CLASS::doline(int lineno, std::string line)
{
	int res = -1;

	return (res);
}

int CLASS::processfile(std::string &p)
{
	//Poco::File fn(p);
	int c;
	int res = -1;
	uint32_t linect;
	bool done, valid;
	std::string p1;
	std::string line, op;

	linect = 0;
	done = false;

	Poco::Path tp(p);
	Poco::Path path = tp.makeAbsolute();

	valid = true;
	p1 = tp.toString();
	Poco::File fn(p1);
	if (!fn.exists())
	{
		fn = Poco::File(p1 + ".s");
		if (!fn.exists())
		{
			fn = Poco::File(p1 + ".S");
			if (!fn.exists())
			{
				fn = Poco::File(p1 + ".mac");
				if (!fn.exists())
				{
					valid = false;
				}
			}
		}
	}
	p1 = fn.path();

	if (valid)
	{
		std::ifstream f(p1);
		if (f.is_open())
		{
			//printf("file is open\n");
			line = "";

			while ((!done) && (f.good()) && (!f.eof()))
			{
				c = f.get();
				if (c == 0x8D) // merlin line ending
				{
					c = 0x0A;  // convert to linux
				}
				if (c == 0x8A) // possible merlin line ending
				{
					c = 0x00; // ignore
				}
				c &= 0x7F;
#if 0
				//printf("%02X ",c&0x7F);

				printf("%c", c);
#else
				int x;
				switch (c)
				{
					case 0x0D:
						break;
					case 0x09:
						line += " ";
						break;
					case 0x0A:
						linect++;
						x = doline(linect, line);
						if (x < 0)
						{
							done = true;
						}
						line = "";
						break;
					default:
						if ((c >= ' ') && (c < 0x7F))
						{
							line += c;
						}
						else
						{
							//printf("garbage %08X\n",c);
						}
						break;
				}
#endif
			}
			if ( (f.eof()))
			{
				res = 0;
			}
		}
	}
	else
	{
		printf("file %s does not exist\n", p.c_str());
	}

	//printf("\n\nfile read result: %d\n", res);
	return (res);
}

#undef CLASS

#define CLASS T65816Asm

CLASS::CLASS()
{
	lines.clear();
}

#define OPHANDLER(ACB) std::bind(ACB, this, std::placeholders::_1, std::placeholders::_2)

CLASS::~CLASS()
{
}

void CLASS::pushopcode(std::string op, uint8_t opcode, uint16_t flags, TOpCallback cb)
{
	TSymbol sym;

	sym.name = op;
	sym.opcode = opcode;
	sym.namelc = Poco::toLower(op);
	sym.stype = flags;
	sym.value = 0;
	sym.cb = cb;
	std::pair<std::string, TSymbol> p(Poco::toUpper(op), sym);

	opcodes.insert(p);
}


TSymbol *CLASS::findSymbol(std::string symname)
{
	TSymbol *res = NULL;

	auto itr = symbols.find(Poco::toUpper(symname));
	if (itr != symbols.end())
	{
		res = &itr->second;

		return (res);
	}
	return (res);
}

TSymbol *CLASS::addSymbol(std::string sym, uint32_t val, bool replace)
{
	TSymbol *res = NULL;
	TSymbol *fnd = NULL;

	fnd = findSymbol(sym);

	if ((fnd != NULL) && (!replace))
	{
		return (NULL);  // it is a duplicate
	}

	if (fnd != NULL)
	{
		fnd->value = val;
		return (fnd);
	}

	TSymbol s;
	s.name = sym;
	s.opcode = 0;
	s.namelc = Poco::toLower(sym);
	s.stype = 0;
	s.value = val;
	s.cb = NULL;
	std::pair<std::string, TSymbol> p(Poco::toUpper(sym), s);
	symbols.insert(p);
	res = findSymbol(sym);
	return (res);
}

void CLASS::showSymbolTable(void)
{
//	Poco::HashTable::Iterator itr;
	for (auto itr = symbols.begin(); itr != symbols.end(); itr++)
	{
		TSymbol ptr = itr->second;
		printf("Sym: %-24s 0x%08X\n", ptr.name.c_str(), ptr.value);
	}
}

int CLASS::callOpCode(std::string op, MerlinLine &line)
{
	int res = -1;
	char c;

	if (op.length() == 4) // check for 4 digit 'L' opcodes
	{
		c = op[3];
		if ((c >= 'a') || (c <= 'z'))
		{
			c = c - 0x20;
		}
		if (c == 'L')
		{
			op = op.substr(0, 3);
			line.flags |= FLAG_LONGADDR;
		}

	}
	//Poco::HashMap<std::string, TSymbol>::ConstIterator ptr;

	auto itr = opcodes.find(Poco::toUpper(op));
	if (itr != opcodes.end())
	{
		TSymbol s = itr->second;
		if (s.cb != NULL)
		{
			if (s.stype & OP_ONEBYTE)
			{
				line.inbytes[0] = (s.opcode);
				line.inbytect = 1;
			}
			res = s.cb(line, s);
			if (res == -1)
			{
				res = -2;
			}
		}
	}
	else
	{
		line.setError(errBadOpcode);
	}
	return (res);
}

//imp = <no operand>
//imm = #$00
//sr = $00,S
//dp = $00
//dpx = $00,X
//dpy = $00,Y
//idp = ($00)
//idx = ($00,X)
//idy = ($00),Y
//idl = [$00]
//idly = [$00],Y
//isy = ($00,S),Y
//abs = $0000
//abx = $0000,X
//aby = $0000,Y
//abl = $000000
//alx = $000000,X
//ind = ($0000)
//iax = ($0000,X)
//ial = [$000000]
//rel = $0000 (8 bits PC-relative)
//rell = $0000 (16 bits PC-relative)
//bm = $00,$00


typedef struct
{
	std::string regEx;
	uint16_t addrMode;
	std::string text;
	std::string expression;
} TaddrMode;

TaddrMode addrRegEx[] =
{
	{ "^(?'expr'.+)\\,[s,S]{1}$", syn_s, "e,s"},    				// expr,s
	{"^[(]{1}(?'expr'.+)[,]{1}[(S|s)]{1}[)]{1}[,]{1}[(Y|y)]{1}$", syn_sy, "(e,s),y"}, // (expr,s),y
	{"^#{1}(?'shift'[<,>,^,|]?)(.+)$", syn_imm, "immediate"}, 				//#expr,#^expr,#|expr,#<expr,#>expr
	{"^[(]{1}(?'expr'.+)[,]{1}[x,X]{1}\\)$", syn_diix, "(e,x)"},  			// (expr,x)
	{"^[(]{1}(?'expr'.+)[\\)]{1}[\\,][(Y|y]{1}$", syn_diiy, "(e),y"}, 	//(expr),y
	{"^[(]{1}(?'expr'.+)[\\)]{1}$", syn_di, "(e)"},					// (expr)
	{"^\\[{1}(?'expr'.+)\\]{1}[,]{1}[(Y|y)]{1}$", syn_iyl, "[e],x"},	// [expr],y
	{"^\\[(?'expr'.+)\\]$", syn_dil, "[e]"}, 						// [expr]
	{"^(?'expr'.+)[,]{1}[(X|x)]{1}$", syn_absx, "e,x"},				// expr,x
	{"^(?'expr'.+)[,]{1}[(Y|y)]{1}$", syn_absy, "e,y"},				// expr,y
	{"^(?'expr'.+)[,]{1}(?'expr2'.+)$", syn_bm, "block"},  			// block move expr,expr1
	{"^(?'expr'.+)$", syn_abs, "absolute"},  							// expr (MUST BE LAST)
	{"", 0, ""}
};

// opcodes that are only 65C02 (27) - also in 65816

// 0x01 = 6502
// 0x02 = 65C02
// 0x03 = 65816
uint8_t opCodeCompatibility[256] = {
	0x00,0x00,0x02,0x02,0x01,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x01,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,
	0x00,0x00,0x02,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,
	0x00,0x00,0x02,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02,
	0x00,0x00,0x02,0x02,0x01,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x01,0x00,0x00,0x02,
	0x01,0x00,0x02,0x02,0x00,0x00,0x00,0x02,0x00,0x01,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x01,0x00,0x01,0x02,
	0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x02,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02,
	0x00,0x00,0x02,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,
	0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02,0x00,0x00,0x01,0x02,0x02,0x00,0x00,0x02
};

void CLASS::init(void)
{
	TFileProcessor::init();
	lines.clear();

	insertOpcodes();

}

void CLASS::initpass(void)
{
	casesen = true;
	relocatable = false;
	listing = true;

	origin = 0;
	currentpc = 0;
	cpumode = MODE_65816;
	mx = 0x00;
	currentsym = NULL;
	totalbytes = 0;
	lineno = 0;
	passcomplete = false;
}

void CLASS::complete(void)
{
	printf("=== Assembly Complete: %d bytes\n", totalbytes);

	if (listing)
	{
		showSymbolTable();
	}
}

int CLASS::evaluate(std::string expr, int64_t &value)
{
	int res = -1;
	int64_t result = 0;

	if (expr.length() > 0)
	{

		TEvaluator eval(*this);

		res = eval.evaluate(expr, result);
		//printf("res=%d %08lX\n",res,result);
		if (res == 0)
		{
			value = result;
		}
	}
	else
	{
		value = 0;
		res = 0;
	}
	return res;
}

int CLASS::getAddrMode(MerlinLine &line)
{
	int  res = -1;
	uint16_t mode = syn_none;
	int idx, x;
	std::string s, oper;
	std::vector<std::string> groups;

	oper = line.operand;

	if ((line.opcode.length() == 0) || (line.operand.length() == 0))
	{
		return (syn_implied);
	}

	idx = 0;
	while (mode == syn_none)
	{
		s = addrRegEx[idx].regEx;
		if (s == "")
		{
			mode = syn_err;
		}
		else
		{
			RegularExpression regex(s, 0, true);
			groups.clear();
			x = 0;
			try
			{
				x = regex.split(oper, 0, groups, 0);
			}
			catch (...)
			{
				x = 0;
			}
			if (x > 0)
			{
				mode = addrRegEx[idx].addrMode;
				line.addrtext = addrRegEx[idx].text;
				//cout << "mode: " << line.addrtext << endl;
				for (uint32_t i = 0; i < groups.size(); i++)
				{
					s = groups[i];
					if ((s != "^") && (s != "<") && (s != ">") && (s != "|"))
					{
						line.operand_expr = s;
						//printf("line expression=|%s|\n", s.c_str());
					}
					else
					{
						// SGQ need to set a flag for a shift and process it after eval
					}
				}
			}
		}
		idx++;
	}

	if (mode == syn_none)
	{
		mode = syn_err;
	}
	res = mode;
	//printf("syn_mode=%d\n", mode);
	return (res);
}

int CLASS::parseOperand(MerlinLine &line)
{

	int res = -1;

	line.operand_expr = "";
	int  m = getAddrMode(line);
	if (m >= 0)
	{
		res = m;
	}
	else
	{
		//errorOut(errBadAddressMode);
	}
	return (res);
}

void CLASS::process(void)
{
	uint32_t l;
	int x;
	char c;
	std::string op, operand;
	//uint32_t operand_eval;
	//uint16_t addrmode;

	MerlinLine *line;
	pass = 0;
	while (pass < 2)
	{
		initpass();

		l = lines.size();
		while ((lineno < l) && (!passcomplete))
		{
			line = &lines[lineno];

			//printf("lineno: %d %d |%s|\n",lineno,l,line->operand.c_str());

			op = Poco::toLower(line->opcode);
			operand = Poco::toLower(line->operand);
			line->startpc = currentpc;
			line->bytect = 0;

			if ((line->lable != "") && (pass == 0))
			{
				c = line->lable[0];
				switch (c)
				{
					case ']':
						break;
					case ':':
						break;
					default:
						addSymbol(line->lable, currentpc, false);
						break;
				}
			}
			x = parseOperand(*line);
			if (x >= 0)
			{
				line->addressmode = x;
			}
			int64_t value = -1;
			x=-1;
			x = evaluate(line->operand_expr, value);
			if (x == 0)
			{
				value &= 0xFFFFFFFF;
				//printf("OPERAND VALUE=%08X\n",value);
				line->expr_value = value;
			}
			else
			{
				line->expr_value = 0xFFFFFFFF;
			}

			x = 0;
			if (op.length() > 0)
			{
				x = callOpCode(op, *line);
			}
			if (x > 0)
			{
				line->bytect = x;
				currentpc += x;
				totalbytes += x;
			}
			if (pass == 0)
			{
				line->pass0bytect = line->bytect;
			}


			if (pass == 1)
			{
				if ((line->pass0bytect != line->bytect) && (line->errorcode == 0))
				{
					line->setError(errBadByteCount);
				}

				bool skip = false;
				if (op == "lst")
				{
					if ((operand == "") || (operand == "on"))
					{
						listing = true;
					}
					else
					{
						skip = true;
						listing = false;
					}
				}
				if ((!skip) && (listing) && (pass == 1))
				{
					line->print(lineno);
				}
			}
			lineno++;
		}
		pass++;
	}

}

int CLASS::doline(int lineno, std::string line)
{
	int res = 0;
	std::string op;

	MerlinLine l(line);

	op = Poco::toLower(l.opcode);
	if (op == "merlin")
	{
		syntax = SYNTAX_MERLIN;
	}
	else if (op == "orca")
	{
		syntax = SYNTAX_ORCA;
	}
	l.syntax = syntax;
	lines.push_back(l);

	if ((op == "use") || (op == "put"))
	{
		//printf("processing % s\n",l.operand.c_str());
		processfile(l.operand);
	}

	return (res);
}

#undef CLASS

#define CLASS T65816Link

CLASS::CLASS()
{
}

CLASS::~CLASS()
{
}

void CLASS::init(void)
{
	TFileProcessor::init();
}

void CLASS::process(void)
{

}
void CLASS::complete(void)
{
}

int CLASS::doline(int lineno, std::string line)
{
	int res = 0;

	return (res);
}

#undef CLASS
