#define ADD_ERROR_STRINGS
#include "asm.h"
#include "eval.h"
#include "psuedo.h"

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
	int i, l, pcol;
	int commentcol = 40;
	bool nc = false;


	l = outbytect;
	if (l > 4)
	{
		l = 4;
	}

	nc = getBool("option.nocolor", false);
	if (!nc)
	{
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
	}
	bool empty = false;
	if ((printlable == "") && (opcode == "") && (operand == ""))
	{
		empty = true;
	}
	int b = 4;

	pcol = 0;
	if (!empty)
	{
		pcol += printf("%02X/%04X:", (startpc >> 16), startpc & 0xFFFF);
	}
	else
	{
		pcol += printf("        ");
	}

	for (i = 0; i < l; i++)
	{
		pcol += printf("%02X ", outbytes[i]);
	}
	for (i = l; i < b; i++)
	{
		pcol += printf("   ");
	}

	if (showmx)
	{
		if (outbytect > 0)
		{
			pcol += printf("%%%c%c ", linemx & 02 ? '1' : '0', linemx & 01 ? '1' : '0');
		}
		else
		{
			pcol += printf("    ");
		}
	}

	if (isDebug() > 1)
	{
		pcol += printf("%02X ", addressmode & 0xFF);
	}
	pcol += printf("%6d  ", lineno + 1);

	pcol = 0; // reset pcol here because this is where source code starts

	if (empty)
	{
		if (comment.length() > 0)
		{
			if (comment[0] == ';')
			{
				while (pcol < commentcol)
				{
					pcol += printf(" ");
				}
			}
			pcol += printf("%s", comment.c_str());
		}
	}
	else
	{
		pcol += printf("%-12s %-8s %-10s ", printlable.c_str(), opcode.c_str(), operand.c_str());
		if (errorcode > 0)
		{

			while (pcol < commentcol)
			{
				pcol += printf(" ");
			}
			pcol += printf(":[Error] %s %s", errStrings[errorcode].c_str(), errorText.c_str());
		}
		else
		{
			while (pcol < commentcol)
			{
				pcol += printf(" ");
			}
			pcol += printf("%s", comment.c_str());
		}
	}
	if ((!nc) && (errorcode > 0))
	{
		SetColor(CL_NORMAL | BG_NORMAL);
	}
	printf("\n");

}

void CLASS::clear()
{
	syntax = SYNTAX_MERLIN;
	lable = "";
	printlable = "";
	opcode = "";
	opcodelower = "";
	operand = "";
	comment = "";
	operand_expr = "";
	operand_expr2 = "";
	addrtext = "";
	linemx = 0;
	bytect = 0;
	opflags = 0;
	pass0bytect = 0;
	startpc = 0;
	errorcode = 0;
	errorText = "";
	outbytect = 0;
	lineno = 0;
	outbytes.clear();
	addressmode = 0;
	expr_value = 0;
	eval_result = 0;
	flags = 0;
	outbytes.clear();
}

void CLASS::set(std::string line)
{
	int state = 0;
	int l = (int)line.length();
	int i = 0;
	int x;
	char c, delim = 0;

	clear();

	//printf("line: |%s|\n", line.c_str());
	while (i < l)
	{
		c = line[i++];
		//printf("state: %d\n",state);
		switch (state)
		{
			case 0:  // start of line state
				if ((c == ';') || (c == '*') || (c == '/'))
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
				else if (((c == '*') || (c == '/')) && (lable.length() == 0))
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
				if ((c == '\'') || (c == '"'))
				{
					delim = c;
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
			case 9:
				break;
		}
	}
	printlable = lable;
	x = (int)lable.length();
	if (x > 1)
	{
		while ((x > 1) && (lable[x - 1] == ':'))
		{
			lable = lable.substr(0, x - 1);
			x--;
		}
		//printf("linelable: |%s|\n", lable.c_str());
	}

	opcodelower = Poco::toLower(opcode);
}

#undef CLASS
#define CLASS TFileProcessor

CLASS::CLASS()
{
	errorct = 0;
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
	starttime = GetTickCount();

	syntax = SYNTAX_MERLIN;
}

void CLASS::complete(void)
{

	uint64_t n = GetTickCount();
	if (isDebug())
	{
		//cout << "Processing Time: " << n-starttime << " ms" << endl;
		printf("Processing Time: %" PRIu64 " ms\n",n-starttime);
        //printf("Processing Time: %llu ms\n", n - starttime);
	}
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
			}
			if ( (f.eof()))
			{
				res = 0;
			}
		}
	}
	else
	{
		fprintf(stderr, "File <%s> does not exist.\n\n", p.c_str());
	}

	//printf("\n\nfile read result: %d\n", res);
	return (res);
}

#undef CLASS
#define CLASS TMerlinConverter
CLASS::CLASS() : TFileProcessor()
{
}
CLASS::~CLASS()
{
}
void CLASS::init(void)
{
	std::string s;
	int ts, tabpos;
	lines.clear();

	std::string tabstr = getConfig("reformat.tabs", "8,16,32");
	tabstr = Poco::trim(tabstr);

	memset(tabs, 0x00, sizeof(tabs));

	Poco::StringTokenizer t(tabstr, ",;", 0);
	tabpos = 0;
	for (auto itr = t.begin(); itr != t.end(); ++itr)
	{
		s = Poco::trim(*itr);
		try
		{
			ts = Poco::NumberParser::parse(s);
		}
		catch (...)
		{
			ts = 0;
		}
		if ((ts >= 0) && (ts < 240))
		{
			tabs[tabpos++] = ts;
		}
	}
}

int CLASS::doline(int lineno, std::string line)
{
	MerlinLine l(line);
	lines.push_back(l);
	return 0;
}

void CLASS::process(void)
{
	uint32_t len, t, pos;

	uint32_t ct = (uint32_t)lines.size();

	for (uint32_t lineno = 0; lineno < ct; lineno++)
	{
		MerlinLine &line = lines.at(lineno);

		pos = 0;
		len = 0;
		if ((line.lable.length() == 0)
		        && (line.opcode.length() == 0)
		        && (line.operand.length() == 0))
		{
			if (line.comment.length() > 0)
			{
				char c = line.comment[0];
				if ((c == '*') || (c == '/'))
				{
					printf("%s", line.comment.c_str());
				}
				else
				{
					t = tabs[2];
					while (len < t)
					{
						len += printf(" ");
					}
					printf("%s", line.comment.c_str());
				}
			}
			printf("\n");
		}
		else
		{
			t = tabs[pos++];
			len = printf("%s ", line.printlable.c_str());
			while (len < t)
			{
				len += printf(" ");
			}

			t = tabs[pos++];
			len += printf("%s ", line.opcode.c_str());
			while (len < t)
			{
				len += printf(" ");
			}

			t = tabs[pos++];
			len += printf("%s ", line.operand.c_str());
			while (len < t)
			{
				len += printf(" ");
			}

			t = tabs[pos++];
			len += printf("%s", line.comment.c_str());
			while (len < t)
			{
				len += printf(" ");
			}
			len += printf("\n");
		}
	}
}

void CLASS::complete(void)
{
}


#undef CLASS
#define CLASS T65816Asm

CLASS::CLASS() : TFileProcessor()
{
	lines.clear();
    inDUMSection = false;
	psuedoops = new TPsuedoOp();
}

//#define OPHANDLER(ACB) std::bind(ACB, this, std::placeholders::_1, std::placeholders::_2)

CLASS::~CLASS()
{
	if (psuedoops != NULL)
	{
		delete(psuedoops);
		psuedoops = NULL;
	}
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
		//printf("replacing symbol: %s %08X\n",sym.c_str(),val);
		fnd->value = val;
		return (fnd);
	}

	//printf("addSymbol |%s|\n",sym.c_str());
	TSymbol s;
	s.name = sym;
	s.opcode = 0;
	s.namelc = Poco::toLower(sym);
	s.stype = 0;
	s.value = val;
	s.used = false;
	s.cb = NULL;
	std::pair<std::string, TSymbol> p(Poco::toUpper(sym), s);
	symbols.insert(p);
	res = findSymbol(sym);
	return (res);
}

TSymbol *CLASS::findSymbol(std::string symname)
{
	TSymbol *res = NULL;

	//printf("finding: %s\n",symname.c_str());
	auto itr = symbols.find(Poco::toUpper(symname));
	if (itr != symbols.end())
	{
		//printf("Found: %s 0x%08X\n",itr->second.name.c_str(),itr->second.value);
		res = &itr->second;

		return (res);
	}
	return (res);
}

TSymbol *CLASS::addVariable(std::string sym, std::string val, bool replace)
{
	TSymbol *res = NULL;
	TSymbol *fnd = NULL;

	//printf("addvariable\n");
	fnd = findVariable(sym);

	if ((fnd != NULL) && (!replace))
	{
		return (NULL);  // it is a duplicate
	}

	if (fnd != NULL)
	{
		//printf("replacing symbol: %s %08X\n",sym.c_str(),val);
		fnd->text = val;
		return (fnd);
	}

	TSymbol s;
	s.name = sym;
	s.opcode = 0;
	s.namelc = Poco::toLower(sym);
	s.stype = 0;
	s.value = 0;
	s.text = val;
	s.used = false;
	s.cb = NULL;
	std::pair<std::string, TSymbol> p(Poco::toUpper(sym), s);
	variables.insert(p);
	res = findVariable(sym);
	return (res);
}

TSymbol *CLASS::findVariable(std::string symname)
{
	TSymbol *res = NULL;

	//printf("finding: %s\n",symname.c_str());
	auto itr = variables.find(Poco::toUpper(symname));
	if (itr != variables.end())
	{
		//printf("Found: %s 0x%08X\n",itr->second.name.c_str(),itr->second.value);
		res = &itr->second;

		return (res);
	}
	return (res);
}

void CLASS::showVariables(void)
{
	if (variables.size() > 0)
	{
		printf("\nVariables:\n");

		for (auto itr = variables.begin(); itr != variables.end(); ++itr)
		{
			printf("%-16s %s\n", itr->first.c_str(), itr->second.text.c_str());
		}
	}
}

// set alpha to true to print table sorted by name or
// false to print by value;
void CLASS::showSymbolTable(bool alpha)
{
	std::map<std::string, uint32_t> alphamap;
	std::map<uint32_t, std::string> nummap;

	int columns = 4;
	int column = columns;

	for (auto itr = symbols.begin(); itr != symbols.end(); itr++)
	{
		TSymbol ptr = itr->second;
		alphamap.insert(pair<std::string, uint32_t>(ptr.name, ptr.value));
		nummap.insert(pair<uint32_t, std::string>(ptr.value, ptr.name));
	}

	if (alpha)
	{
		printf("\n\nSymbol table sorted alphabetically:\n\n");

		for (auto itr = alphamap.begin(); itr != alphamap.end(); ++itr)
		{
			printf("%-16s 0x%08X ", itr->first.c_str(), itr->second);
			if ( !--column )
			{
				printf("\n");
				column = columns;
			}
		}
	}
	else
	{
		printf("\n\nSymbol table sorted numerically:\n\n");
		for (auto itr = nummap.begin(); itr != nummap.end(); ++itr)
		{
			printf("0x%08X %-16s ", itr->first, itr->second.c_str());
			if ( !--column )
			{
				printf("\n");
				column = columns;
			}
		}
	}
}

int CLASS::callOpCode(std::string op, MerlinLine &line)
{
	int res = -1;
	char c;

	if (op.length() == 4) // check for 4 digit 'L' opcodes
	{
		c = op[3] & 0x7F;
		if ((c >= 'a') && (c <= 'z'))
		{
			c = c - 0x20;
		}
		switch (c)
		{
			case 'L':
				op = op.substr(0, 3);
				line.flags |= FLAG_FORCELONG; // 3 byte address
				break;
			default:  // any char but 'L' as in Merlin 16+
				if ((c != 'D') || (Poco::toUpper(op) != "DEND"))
				{
					op = op.substr(0, 3);
					line.flags |= FLAG_FORCEABS; // 2 byte address
				}
				break;
			case 'Z':
				op = op.substr(0, 3);
				line.flags |= FLAG_FORCEDP; // one byte address
				break;
		}
	}

	switch (line.expr_shift)
	{
		case '<':
			line.expr_value &= 0xFF;
			line.flags |= FLAG_DP;
			break;
		case '>':
			line.expr_value >>= 8;
			line.expr_value &= 0xFFFF;
			break;
		case '^':
			line.expr_value = (line.expr_value >> 16) & 0xFFFF;
			break;
		case '|':
			line.flags |= FLAG_FORCELONG;
			break;
	}


	auto itr = opcodes.find(Poco::toUpper(op));
	if (itr != opcodes.end())
	{
		TSymbol s = itr->second;
		if (s.cb != NULL)
		{
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

typedef struct
{
	std::string regEx;
	uint16_t addrMode;
	std::string text;
	std::string expression;
} TaddrMode;

// these are the regular expressions that determine the addressing mode
// and extract the 'expr' part of the addr-mode

// ^([_,a-z,A-Z,0-9:\]].+)\,[s,S]{1}$ // might be a better syn_s

// "^([:-~][0-Z_-~]*)$"  // this is a valid identifier
// "^([$][0-9A-Fa-f]+)$" // hex digit
// "^([%][0-1][0-1_]+[0-1])$" - binary numbera
// "^([0-9]+)$" - decimal number
// "^([:-~][^\],()]*)$" - valid expression
const TaddrMode addrRegEx[] =
{
	{ "^(?'expr'.+)\\,[s,S]{1}$", syn_s, "e,s"},    				// expr,s
	{"^[(]{1}(?'expr'.+)[,]{1}[(S|s)]{1}[)]{1}[,]{1}[(Y|y)]{1}$", syn_sy, "(e,s),y"}, // (expr,s),y
	{"^#{1}(.+)$", syn_imm, "immediate"}, 				//#expr,#^expr,#|expr,#<expr,#>expr
	{"^[(]{1}(?'expr'.+)[,]{1}[x,X]{1}\\)$", syn_diix, "(e,x)"},  			// (expr,x)
	{"^[(]{1}(?'expr'.+)[\\)]{1}[\\,][(Y|y]{1}$", syn_diiy, "(e),y"}, 	//(expr),y
	{"^[(]{1}(?'expr'.+)[\\)]{1}$", syn_di, "(e)"},					// (expr)
	{"^\\[{1}(?'expr'.+)\\]{1}[,]{1}[(Y|y)]{1}$", syn_iyl, "[e],y"},	// [expr],y
	{"^\\[(?'expr'.+)\\]$", syn_dil, "[e]"}, 						// [expr]
	{"^(?'expr'.+)[,]{1}[(X|x)]{1}$", syn_absx, "e,x"},				// expr,x
	{"^(?'expr'.+)[,]{1}[(Y|y)]{1}$", syn_absy, "e,y"},				// expr,y
	{"^(?'expr'.+)[,]{1}(?'expr2'.+)$", syn_bm, "block"},  			// block move expr,expr1
	{"^(?'expr'.+)$", syn_abs, "absolute"},  							// expr (MUST BE LAST)
	{"", 0, ""}
};

// keep this next line for awhile
//	{"^#{1}(?'shift'[<,>,^,|]?)(.+)$", syn_imm, "immediate"}, 				//#expr,#^expr,#|expr,#<expr,#>expr

//	one or more of any character except ][,();
const std::string valExpression = "^([^\\]\\[,();]+)$";

// opcode check. emitted opcodes are compared against this
// table, and if the XC status doesn't meet the requirements
// an error is thrown

// 0x00 = 6502
// 0x01 = 65C02
// 0x02 = 65816
uint8_t opCodeCompatibility[256] =
{
	0x00, 0x00, 0x02, 0x02, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x02, 0x02, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x01, 0x00, 0x00, 0x02,
	0x01, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x01, 0x02,
	0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
	0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x00, 0x02
};

void CLASS::init(void)
{
	uint8_t b = opCodeCompatibility[0];
	if (b)
	{
	}
	TFileProcessor::init();
	lines.clear();

	insertOpcodes();

}

void CLASS::initpass(void)
{
	std::string s;

	casesen = getBool("asm.casesen", true);
	listing = getBool("asm.lst", true);
	showmx = getBool("asm.showmx", false);
	trackrep = getBool("asm.trackrep", false);
	merlincompat = getBool("asm.merlincompatible", true);
	allowdup = getBool("asm.allowduplicate", true);

	skiplist = false;

	PC.origin = 0x8000;
	PC.currentpc = PC.origin;
	PC.totalbytes = 0;
	PC.orgsave = PC.origin;

	s = getConfig("asm.cpu", "M65816");
	s = Poco::trim(Poco::toUpper(s));

	cpumode = MODE_65816;
	mx = 0x00;

	if (s == "M65816")
	{
		cpumode = MODE_65816;
		mx = 0x00;
	}
	else if (s == "M65C02")
	{
		cpumode = MODE_65C02;
		mx = 0x03;
	}
	else if (s == "M6502")
	{
		cpumode = MODE_6502;
		mx = 0x03;
	}
	else
	{
		printf("Unknown CPU type in .ini\n");
	}
	relocatable = false;
	currentsym = NULL;
	lineno = 0;
	errorct = 0;
	passcomplete = false;
	dumstartaddr = 0;
	dumstart = 0;


	variables.clear(); // clear the variables for each pass
	while (!PCstack.empty())
	{
		PCstack.pop();
	}
	savepath = "";
}

void CLASS::complete(void)
{
	printf("\n\n=== Assembly Complete: %d bytes %u errors.\n", PC.totalbytes, errorct);

	if (savepath != "")
	{
		if (errorct == 0)
		{
			std::ofstream f(savepath);

			uint32_t lineno = 0;
			uint32_t l = (uint32_t)lines.size();
			while (lineno < l)
			{
				MerlinLine &line = lines.at(lineno++);
				if ((line.outbytect > 0) && ((line.flags & FLAG_INDUM) == 0))
				{
					for (uint32_t i = 0; i < line.outbytect; i++)
					{
						f.put(line.outbytes[i]);
					}
				}
			}
		}
		else
		{
			printf("\nErrors in assembly. Output not SAVED.\n\n");
		}
	}

	if (listing)
	{
		showSymbolTable(true);
		showSymbolTable(false);
		showVariables();
	}
	TFileProcessor::complete();
}

int CLASS::evaluate(MerlinLine &line, std::string expr, int64_t &value)
{
	int res = -1;
	int64_t result = 0;

	if (expr.length() > 0)
	{

		TEvaluator eval(*this);
		line.eval_result = 0;

		res = eval.evaluate(expr, result, line.expr_shift);
		if (res != 0)
		{
			if (isDebug() > 2)
			{
				int c = SetColor(CL_RED);
				cout << "eval Error=" << res << "0x" << std::hex << result << std::dec << eval.badsymbol << endl;
                //printf("eval Error=%d %08llX |%s|\n", res, result, eval.badsymbol.c_str());
				SetColor(c);
			}
		}
		if (res == 0)
		{
			uint64_t v1 = (uint64_t) result;
			value = result;
			if ((listing) && (pass > 0) && (isDebug() > 2))
			{
				cout << "EV1=0x" << std::hex << v1 << " '" << std::dec << line.expr_shift << ";" << endl;
                //printf("EV1=%08llX '%c'\n", v1, line.expr_shift);
			}
			if (v1 >= 0x10000)
			{
				line.flags |= FLAG_BIGNUM;
			}
			if (v1 < 0x100)
			{
				line.flags |= FLAG_DP;
			}
		}
	}
	else
	{
		value = 0;
		res = 0;
	}
	if (isDebug() >= 3)
	{
		cout << "Eval Result: 0x" << std::hex << value << std::dec << "(status=" << res << ")" << endl;
        //printf("Eval Result: %08llX (status=%d)\n", value, res);
	}
	return (res);
}

int CLASS::getAddrMode(MerlinLine & line)
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
	RegularExpression valEx(valExpression, 0, true);

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
				int ct = 0;
				for (uint32_t i = 0; i < groups.size(); i++)
				{
					s = groups[i];
					//printf("ct=%zu idx=%d group: |%s|\n", groups.size(), i, s.c_str());

					if (s != "")
					{
						if ((s != "^") && (s != "<") && (s != ">") && (s != "|"))
						{
							bool v = true;
							if (mode == syn_abs)
							{
								if (i > 0)
								{
									v = valEx.match(s, 0, 0);
								}
							}
							if (!v)
							{
								//printf("invalid expression |%s|\n", s.c_str());
								mode = syn_none;
							}
							else if (ct == 1)
							{
								line.operand_expr = s;
							}
							else if (ct == 2)
							{
								line.operand_expr2 = s;
							}
							ct++;
							//printf("line expression=|%s|\n", s.c_str());
						}
						else
						{
							// SGQ need to set a flag for a shift and process it after eval
						}
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

int CLASS::parseOperand(MerlinLine & line)
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
	int x;;
	char c;
	std::string op, operand;
	//uint32_t operand_eval;
	//uint16_t addrmode;

	//MerlinLine *line;
	pass = 0;
	while (pass < 2)
	{
		initpass();

		l = (uint32_t)lines.size();
		while ((lineno < l) && (!passcomplete))
		{
			MerlinLine &line = lines[lineno];

			line.eval_result = 0;
			line.lineno = lineno + 1;
			//printf("lineno: %d %d |%s|\n",lineno,l,line.operand.c_str());

			op = Poco::toLower(line.opcode);
			operand = Poco::toLower(line.operand);
			line.startpc = PC.currentpc;
			line.linemx = mx;
			line.bytect = 0;
			line.showmx = showmx;

			if ((line.lable != "") && (pass == 0))
			{
				std::string lable = Poco::trim(line.lable);
				TSymbol *sym = NULL;
				bool dupsym = false;
				c = line.lable[0];
				switch (c)
				{
					case ']':
						sym = addVariable(line.lable, "", true);
						if (sym == NULL) { dupsym = true; }
						break;
					case ':':
						break;
					default:
						sym = addSymbol(line.lable, PC.currentpc, false);
						if (sym == NULL) { dupsym = true; }
						break;
				}
				if (dupsym)
				{
					line.setError(errDupSymbol);
				}
			}
			x = parseOperand(line);
			if (x >= 0)
			{
				line.addressmode = x;
			}

			int64_t value = -1;
			x = evaluate(line, line.operand_expr, value);
			//line.eval_result=x;

			if (x == 0)
			{
				value &= 0xFFFFFFFF;
				line.expr_value = (int32_t)value;
			}
			else
			{
				line.expr_value = 0;
			}

			x = 0;
			if (op.length() > 0)
			{
				x = callOpCode(op, line);
			}

			if (x > 0)
			{
				if (!PCstack.empty()) // are we inside a DUM section?
				{
					line.flags |= FLAG_INDUM;
				}
				if ((line.eval_result != 0) && (pass > 0))
				{
					line.setError(errBadOperand);
					line.errorText = line.operand_expr;
				}
				line.bytect = x;
				PC.currentpc += x;
				PC.totalbytes += x;
			}
			if (pass == 0)
			{
				line.pass0bytect = line.bytect;
			}

			if (dumstart > 0) // starting a dummy section
			{
				PCstack.push(PC);
				PC.origin = dumstartaddr;
				PC.currentpc = PC.origin;
				dumstart = 0;
				dumstartaddr = 0;
			}
			if (dumstart < 0)
			{
				PC = PCstack.top();
				PCstack.pop();
				dumstart = 0;
				dumstartaddr = 0;
			}

			if (pass == 1)
			{
				if ((line.pass0bytect != line.bytect) && (line.errorcode == 0))
				{
					line.setError(errBadByteCount);
				}

				if (line.errorcode != 0)
				{
					errorct++;
				}
				if (((!skiplist) && (listing) && (pass == 1)) || (line.errorcode != 0))
				{
					line.print(lineno);
				}
				skiplist = false;
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

CLASS::CLASS() : TFileProcessor()
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
