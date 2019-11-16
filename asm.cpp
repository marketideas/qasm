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
	int pcol;
	uint32_t l, i;
	//int commentcol;
	static bool checked = false;
	static bool nc1 = false;
	bool nc = false;

	uint32_t b = 4; // how many bytes show on the first line

	bool merlinstyle = true;

	if (datafillct > 0)
	{
		l = datafillct;
	}
	else
	{
		l = outbytect;
	}
	if (l > b)
	{
		l = b;
	}
	if (errorcode > 0)
	{
		if (merlinstyle)
		{
			//printf("errorcode=%d\n",errorcode);
			printf("%s in line: %d", errStrings[errorcode].c_str(), lineno + 1);
			if (errorText != "")
			{
				printf("%s", errorText.c_str());
			}
			printf("\n");
		}
		flags &= (~FLAG_NOLINEPRINT);
	}

	if (flags & FLAG_NOLINEPRINT)
	{
		return;
	}
	if (!checked)
	{
		nc1 = getBool("option.nocolor", false);
		checked = true;
	}
	else
	{
		nc = nc1;
	}

	if ((!isatty(STDOUT_FILENO)) || (merlinstyle))
	{
		nc = true;
	}

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

	pcol = 0;

	bool saddr = flags & FLAG_FORCEADDRPRINT;
	saddr = (outbytect > 0) ? true : saddr;
	saddr = (printlable != "") ? true : saddr;

	if (saddr)
	{
		pcol += printf("%02X/%04X:", (startpc >> 16), startpc & 0xFFFF);
	}
	else
	{
		pcol += printf("        ");
	}

	for (i = 0; i < l; i++)
	{
		uint8_t a = datafillbyte;
		if (datafillct == 0)
		{
			a = outbytes[i];
		}

		pcol += printf("%02X ", a);
	}
	for (i = l; i < b; i++)
	{
		pcol += printf("   ");
	}

	pcol += printf("%6d  ", lineno + 1);

	if (showmx)
	{
		if ((outbytect + datafillct) > 0)
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
			else
			{
				pcol += printf("%s", comment.c_str());
			}
		}
	}
	else
	{
		pcol += printf("%-12s %-8s %-10s ", printlable.c_str(), opcode.c_str(), operand.c_str());
	}
	if ((errorcode > 0) && (!merlinstyle))
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
	//printf("\n");

	if ((!nc) && (errorcode > 0))
	{
		SetColor(CL_NORMAL | BG_NORMAL);
	}

	uint32_t obc = datafillct;
	if (obc == 0)
	{
		obc = outbytect;
	}

	uint32_t ct = 1;
	if (obc > b)
	{
		ct = 0;
		uint8_t db;
		uint32_t t = b;
		char *s = (char *)"        ";

		b = 8;

		//printf("t=%d ct=%d\n",t,outbytect);
		printf("\n");
		while (t < obc)
		{
			db = datafillbyte;
			if (datafillct == 0)
			{
				db = outbytes[t];
			}
			if (ct == 0)
			{
				printf("%s", s);
			}

			printf("%02X ", db);
			t++;
			ct++;
			if (ct >= b)
			{
				printf("\n");
				ct = 0;
			}
		}
	}
	if (ct > 0)
	{
		printf("\n");
	}

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
	commentcol = 40;
	bytect = 0;
	opflags = 0;
	pass0bytect = 0;
	startpc = 0;
	errorcode = 0;
	errorText = "";
	outbytect = 0;
	datafillct = 0;
	datafillbyte = 0;
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
	int l = line.length();
	int i = 0;
	int x;
	char c, delim;

	clear();

	delim = 0;
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
	x = lable.length();
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
	int ts, tabpos;
	std::string s;

	filenames.clear();
	starttime = GetTickCount();
	initialdir = Poco::Path::current();
	syntax = 0;
	filecount = 0;

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

void CLASS::complete(void)
{

	uint64_t n = GetTickCount();
	//if (isDebug())
	{
		//cout << "Processing Time: " << n - starttime << "ms" << endl;
		uint64_t x = n - starttime;
		uint32_t x1 = x & 0xFFFFFFFF;
		printf("Elapsed time: %u ms\n", x1);

	}
}

void CLASS::process(void)
{

}
int CLASS::doline(int lineno, std::string line)
{
	UNUSED(lineno);
	UNUSED(line);

	int res = -1;

	return (res);
}

std::string CLASS::processFilename(std::string fn, std::string curDir, int level)
{
	std::string res = fn;
	std::string s, s1;
	Path p = Poco::Path(fn);

	try
	{
		int n = p.depth();
		//LOG_DEBUG << "n=" << n << " " << fn << endl;
		if (n == 0)
		{
			res = curDir + fn;
		}
		if (n > 0)
		{
			std::string d1 = p[0];
			uint32_t v = 100;
			try
			{
				v = Poco::NumberParser::parseUnsigned(d1);
			}
			catch (...)
			{
				v = 99;
			}
			if (v < 10)
			{
				Poco::Path p1 = p.popFrontDirectory();
				s = p1.toString();
				s1 = "global.path" + Poco::NumberFormatter::format(v);
				switch (v)
				{
					case 0:
						s = initialdir + s;
						break;
					default:
						s = getConfig(s1, ".") + "/" + s;
						if (level < 5)
						{
							s = processFilename(s, curDir, level + 1);
						}
						break;
				}
				p = s;
				p.makeAbsolute();
			}
			res = p.toString();
		}
	}
	catch (Poco::Exception &e)
	{
		if (isDebug() > 2)
		{
			cout << "exception: " << e.displayText() << endl;
		}
	}
	catch (std::exception &e)
	{
		if (isDebug() > 2)
		{
			cout << e.what() << endl;
		}
	}

	p = res;
	p.makeAbsolute();
	res = p.toString();

	char buff[PATH_MAX + 1];
	memset(buff, 0x00, sizeof(buff));
	char *rp = realpath(res.c_str(), buff);
	if (rp != NULL)
	{
		//printf("realpath: %s\n", buff);
		res = rp;
	}
	p = res;
	p.makeAbsolute();
	res = p.toString();

	//LOG_DEBUG << "convert: |" << res << "|" << endl;

	return (res);
}

int CLASS::processfile(std::string p, std::string &newfilename)
{
	//Poco::File fn(p);
	int c;
	int res = -1;
	uint32_t linect;
	bool done, valid;
	std::string currentdir;
	std::string p1;
	std::string line, op;

	linect = 0;
	done = false;

	currentdir = Poco::Path::current();

	if (filecount == 0)
	{
		initialdir = currentdir;
		//printf("initialdir=%s\n",initialdir.c_str());
	}

	//printf("currentdir=%s initialdir=%s\n", currentdir.c_str(), initialdir.c_str());
	//LOG_DEBUG << "initial file name: " << p << endl;
	p = processFilename(p, (filecount == 0) ? currentdir : currentdir, 0);

	//LOG_DEBUG << "Converted filename: " << p << endl;

	Poco::Path tp(p);
	Poco::Path path = tp.makeAbsolute();
	Poco::Path parent = path.parent();
	std::string dir = parent.toString();

	try
	{

		if (filecount == 0)
		{
			// is this the first file in the compilation, or a PUT/USE?
			// if first, change CWD to location of file
			//LOG_DEBUG << "Changing directory to: " << dir << endl;
			if (chdir(dir.c_str())) {} // change directory to where the file is
		}

		p1 = path.toString();

		newfilename = p1;
		//LOG_DEBUG << "initial file name: " << p1 << endl;

		valid = true;
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
						fn = Poco::File(p1);
						valid = false;
					}
				}
			}
		}
		p1 = fn.path();
		//LOG_DEBUG << "File name: " << p1 << endl;

		int ecode = -3;
		valid = false;
		if (fn.exists())
		{
			ecode = -2;
			valid = true;
			//LOG_DEBUG << "File exists: " << p1 << endl;
			if (fn.isLink())
			{
				//LOG_DEBUG << "File is a link: " << p1 << endl;
			}
			if ((fn.isDirectory()) || (!fn.canRead()))
			{
				//LOG_DEBUG << "File is a directory: " << p1 << endl;
				valid = false;
			}
		}

		newfilename = p1;
		if (!valid)
		{
			//fprintf(stderr, "Unable to access file: %s\n", p1.c_str());

			errorct = 1;
			return (ecode);
		}

		if (valid)
		{

			if (filecount == 0)
			{
			}
			else
			{
				for (auto itr = filenames.begin(); itr != filenames.end(); ++itr)
				{
					if (*itr == p1)
					{
						return (-9);
					}
				}
			}

			filecount++;
			filenames.push_back(p1);

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
	}
	catch (...)
	{

	}
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
	lines.clear();

	syntax = SYNTAX_MERLIN;
}

int CLASS::doline(int lineno, std::string line)
{
	UNUSED(lineno);

	MerlinLine l(line);
	lines.push_back(l);
	return 0;
}

void CLASS::process(void)
{
	uint32_t len, t, pos;

	uint32_t ct = lines.size();

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

	//printf("addvariable: %s %s\n", s.name.c_str(), s.text.c_str());

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
		printf("\n");
	}
}

// set alpha to true to print table sorted by name or
// false to print by value;
void CLASS::showSymbolTable(bool alpha)
{
	if (symbols.size() > 0)
	{
		std::map<std::string, uint32_t> alphamap;
		std::map<uint32_t, std::string> nummap;

		int columns = getInt("asm.symcolumns", 3);
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
				printf("%-16s 0x%08X       ", itr->first.c_str(), itr->second);
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
				printf("0x%08X       %-16s ", itr->first, itr->second.c_str());
				if ( !--column )
				{
					printf("\n");
					column = columns;
				}
			}
		}
		if (column > 0)
		{
			printf("\n");
		}
	}
}

int CLASS::callOpCode(std::string op, MerlinLine &line)
{
	int res = -1;
	char c;
	std::string s;

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
				s = Poco::toUpper(op);
				if ((s == "ELSE") || (s == "DEND"))
				{
					break;
				}
				if (c != 'D')
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
	//std::string expression;
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

// this one looks for ]variables
const std::string varExpression = "([]]{1}[:0-9A-Z_a-z]{1}[0-9A-Z_a-z]*)";

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
	while (!LUPstack.empty())
	{
		LUPstack.pop();
	}
	while (!DOstack.empty())
	{
		DOstack.pop();
	}
	curLUP.clear();
	curDO.clear();
	savepath = "";
}

void CLASS::complete(void)
{
	if (savepath != "")
	{
		if (errorct == 0)
		{
			std::string currentdir = Poco::Path::current();

			savepath = processFilename(savepath, currentdir, 0);
			printf("saving to file: %s\n", savepath.c_str());

			std::ofstream f(savepath);

			uint32_t lineno = 0;
			uint32_t l = lines.size();
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

	printf("\n\nEnd qASM assembly, %d bytes, %u errors, %lu lines, %lu symbols.\n", PC.totalbytes, errorct, lines.size(), symbols.size());

	TFileProcessor::complete();

	if (listing)
	{
		showSymbolTable(true);
		showSymbolTable(false);
		showVariables();
	}
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
				uint32_t rr = result & 0xFFFFFFFF;
				printf("eval Error=%d %08X |%s|\n", res, rr, eval.badsymbol.c_str());
				SetColor(c);
			}
		}
		if (res == 0)
		{
			uint64_t v1 = (uint64_t) result;
			value = result;
			if ((listing) && (pass > 0) && (isDebug() > 2))
			{
				uint32_t rr = v1 & 0xFFFFFFFF;
				printf("EV1=%08X '%c'\n", rr, line.expr_shift);
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
		uint32_t rr = value & 0xFFFFFFFF;
		printf("Eval Result: %08X (status=%d)\n", rr, res);
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

int CLASS::substituteVariables(MerlinLine & line)
{
	int res = -1;
	int x;
	std::string::size_type offset, slen;
	std::string oper = line.operand;
	std::string s;
	TSymbol *sym;
	uint32_t len, off, ct;

	slen = oper.length();
	if (slen > 0)
	{
		std::vector<std::string> groups;

		offset = 0;
		RegularExpression varEx(varExpression, Poco::RegularExpression::RE_EXTRA, true);
		Poco::RegularExpression::MatchVec  mVec;

		//printf("|%s|%s|\n", varExpression.c_str(), oper.c_str());
		groups.clear();
		ct = 0;
		while (offset < slen)
		{
			try
			{
				varEx.match(oper, offset, mVec, 0);
			}
			catch (...)
			{
				offset = slen;
			}

			x = mVec.size();
			if (x > 0)
			{
				res = 0;
				off = mVec[0].offset;
				len = mVec[0].length;
				s = oper.substr(off, len);
				sym = findVariable(s);
				if (sym != NULL)
				{
					ct++;
					if (pass > 0)
					{
						//printf("%d |%s|\n", ct, s.c_str());
					}
				}
				offset += len;
			}
			else
			{
				offset = slen;
			}
		}

	}
	return (res);
}

// this function determines if code generation is turned off (IF,DO,LUP,MAC, etc
bool CLASS::codeSkipped(void)
{
	bool res = false;

	res = (curLUP.lupskip) ? true : res;
	res = (curDO.doskip) ? true : res;

	//printf("codeskip: %d\n",res);

	return (res);
}

void CLASS::process(void)
{
	uint32_t l;
	int x;;
	char c;
	char buff[256];
	MerlinLine errLine;
	std::string op, operand, ls;

	pass = 0;
	while (pass < 2)
	{
		initpass();

		l = lines.size();
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
			uint16_t cc = tabs[2];
			if (cc == 0)
			{
				cc = 40;
			}
			line.commentcol = cc;
			line.bytect = 0;
			line.showmx = showmx;

			if ((line.lable != ""))
			{
				std::string lable = Poco::trim(line.lable);
				TSymbol *sym = NULL;
				bool dupsym = false;
				c = line.lable[0];
				switch (c)
				{
					case ']':
						sprintf(buff, "$%X", PC.currentpc);
						ls = buff;
						sym = addVariable(line.lable, ls, true);
						if (sym == NULL) { dupsym = true; }
						break;
					case ':':
						break;
					default:
						if (pass == 0)
						{
							sym = addSymbol(line.lable, PC.currentpc, false);
							if (sym == NULL) { dupsym = true; }
						}
						break;
				}
				if (dupsym)
				{
					line.setError(errDupSymbol);
				}
			}
			x = substituteVariables(line);
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
				line.expr_value = value;
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

			if ((x > 0) && (codeSkipped())) // has a psuedo-op turned off code generation? (LUP, IF, etc)
			{
				x = 0;
				line.outbytect=0;
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

		// end of file reached here, do some final checks

#if 0
		if (LUPstack.size() > 0)
		{
			errLine.clear();
			errLine.setError(errUnexpectedEOF);
			errLine.print(lineno);
			pass = 2;
		}
#endif
		pass++;
	}

}

int CLASS::doline(int lineno, std::string line)
{
	int res = 0;
	int x;
	std::string op;

	UNUSED(lineno);

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
		std::string fn;
		x = processfile(l.operand, fn);
		if (x < 0)
		{
			switch (x)
			{
				case -9:
					l.setError(errDuplicateFile);
					break;
				case -3:
					l.setError(errFileNotFound);
					break;
				case -2:
					l.setError(errFileNoAccess);
					break;
				default:
					l.setError(errFileNotFound);
					break;
			}
			l.operand = fn;
			l.print(0);
			errorct++;
			res = -1;
		}
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
	UNUSED(lineno);
	UNUSED(line);

	int res = 0;

	return (res);
}

#undef CLASS
