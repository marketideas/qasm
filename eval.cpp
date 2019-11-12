#include "asm.h"
#include "eval.h"
#include <string.h>
#include <stdio.h>

#define CLASS TEvaluator

#define DEF_VAL 0

std::ostream& operator<<(std::ostream& os, const Token& token)
{
    os << token.str;
    return os;
}

CLASS::CLASS(T65816Asm &_asm) : assembler(_asm)
{
}

CLASS::~CLASS()
{
}

std::deque<Token> CLASS::exprToTokens(const std::string& expr)
{
    std::deque<Token> tokens;
    int state = 0;
    char c;
    char delim;
    std::string ident, asc;

    std::string ops = "+-*//^!.&()";
    std::string c1;
    char *tokptr;
    char *tptr;
    bool numexpect;
    Token::Type t;

    numexpect = true;
    for (const auto* p = expr.c_str(); *p; ++p)
    {
        c = *p;
        c1 = c;
        tptr = (char *)c1.c_str();
        tokptr = strpbrk(tptr, (const char *)ops.c_str());
        // printf("state=%d %c %p\n", state, c,tokptr);

        switch (state)
        {
            default:
                printf("bad token state\n");
                state = 0;
                break;
            case 11:
                if ((c < ' ') || (c == delim))
                {
                    // SGQ - convert ascii to a number here
                    asc = "0";
                    //printf("ident=|%s|\n",ident.c_str());
                    if (ident.length() > 0)
                    {
                        // SGQ - convert ascii to a number here
                    }
                    t = Token::Type::Number;
                    int pr = 1;            // precedence
                    bool ra = false;        // rightAssociative
                    tokens.push_back(Token
                    {
                        t, asc, pr, ra
                    });
                    ident = "";
                    state = 0;
                    if (c != delim)
                    {
                        p--;
                    }
                }
                else
                {
                    ident += c;
                }
                break;
            case 10:
            case 20:
                if ((c <= ' ') || (tokptr != NULL))
                {
                    if (ident.length() > 0)
                    {
                        if (state == 20)
                        {
                            t = Token::Type::Symbol;
                        }
                        else
                        {
                            t = Token::Type::Number;
                        }
                        int pr = 1;            // precedence
                        bool ra = false;        // rightAssociative
                        tokens.push_back(Token
                        {
                            t, ident, pr, ra
                        });
                        ident = "";
                    }
                    state = 0;
                    p--;
                }
                else
                {
                    ident += c;
                }
                break;
            case 0:
                if ((c == '$') && (numexpect))
                {
                    state = 10;
                    ident += c;
                    numexpect = false;

                }
                else if ((c == '*') && (numexpect))
                {
                    numexpect = false;
                    state = 20;
                    ident += c;
                }
                else if ((c == '%') && (numexpect))
                {
                    state = 10;
                    ident += c;
                    numexpect = false;

                }
                else if ((c == '\'') && (numexpect))
                {
                    delim = c;
                    state = 11;
                    numexpect = false;
                }
                else if ((c == '"') && (numexpect))
                {
                    delim = c;
                    state = 11;
                    numexpect = false;
                }
                else if (((c == '-') || (c == '+')) && (numexpect))
                {
                    state = 10;
                    ident += c;
                }
                else if (isdigit(c))
                {
                    state = 10;
                    ident += c;
                    numexpect = false;

                }
                else if ((c >= 'a') && (c <= 'z'))
                {
                    state = 20;
                    ident += c;
                    numexpect = false;

                }
                else if ((c >= 'A') && (c <= 'Z'))
                {
                    state = 20;
                    ident += c;
                    numexpect = false;
                }
                else if ((tokptr != NULL) && (!numexpect))
                {
                    t = Token::Type::Unknown;
                    int pr = -1;            // precedence
                    bool ra = false;        // rightAssociative
                    switch (c)
                    {
                        default:                                    break;
                        case '(':   t = Token::Type::LeftParen;     break;
                        case ')':   t = Token::Type::RightParen;    break;
                        case '!':   t = Token::Type::Operator;      pr = 5; break;
                        case '.':   t = Token::Type::Operator;      pr = 5; break;
                        case '&':   t = Token::Type::Operator;      pr = 5; break;
                        case '^':   t = Token::Type::Operator;      pr = 4; ra = true;  break;
                        case '*':   t = Token::Type::Operator;      pr = 3; break;
                        case '/':   t = Token::Type::Operator;      pr = 3; break;
                        case '+':   t = Token::Type::Operator;      pr = 2; break;
                        case '-':   t = Token::Type::Operator;      pr = 2; break;

                    }
                    tokens.push_back(Token
                    {
                        t, std::string(1, c), pr, ra
                    });
                    numexpect = true;
                }
        }
    }

    return tokens;
}


std::deque<Token> CLASS::shuntingYard(const std::deque<Token>& tokens)
{
    std::deque<Token> queue;
    std::vector<Token> stack;
    TSymbol *sym;
    char buff[128];

    // While there are tokens to be read:
    for (auto token : tokens)
    {
        // Read a token
        switch (token.type)
        {
            case Token::Type::Symbol:
                token.type = Token::Type::Number;
                if (token.str == "*")
                {
                    sprintf(buff, "%u", assembler.currentpc);
                    token.str = buff;
                }
                else
                {
                    //printf("symbol find |%s|\n",token.str.c_str());

                    sym = assembler.findSymbol(token.str);
                    if (sym != NULL)
                    {
                        sym->used = true;
                        //printf("symbol found\n");
                        sprintf(buff, "%d", sym->value);
                        token.str = buff;
                    }
                    else
                    {
                        setError(Token::unknownSymbolErr);
                        badsymbol = token.str;
                        token.str = "0";
                    }
                }
                queue.push_back(token);
                break;
            case Token::Type::Number:
                // If the token is a number, then add it to the output queue
                queue.push_back(token);
                break;

            case Token::Type::Operator:
            {
                // If the token is operator, o1, then:
                const auto o1 = token;

                // while there is an operator token,
                while (!stack.empty())
                {
                    // o2, at the top of stack, and
                    const auto o2 = stack.back();

                    // either o1 is left-associative and its precedence is
                    // *less than or equal* to that of o2,
                    // or o1 if right associative, and has precedence
                    // *less than* that of o2,
                    if (
                        (! o1.rightAssociative && o1.precedence <= o2.precedence)
                        ||  (  o1.rightAssociative && o1.precedence <  o2.precedence)
                    )
                    {
                        // then pop o2 off the stack,
                        stack.pop_back();
                        // onto the output queue;
                        queue.push_back(o2);

                        continue;
                    }

                    // @@ otherwise, exit.
                    break;
                }

                // push o1 onto the stack.
                stack.push_back(o1);
            }
            break;

            case Token::Type::LeftParen:
                // If token is left parenthesis, then push it onto the stack
                stack.push_back(token);
                break;

            case Token::Type::RightParen:
                // If token is right parenthesis:
            {
                bool match = false;
                while (! stack.empty())
                {
                    // Until the token at the top of the stack
                    // is a left parenthesis,
                    const auto tos = stack.back();
                    if (tos.type != Token::Type::LeftParen)
                    {
                        // pop operators off the stack
                        stack.pop_back();
                        // onto the output queue.
                        queue.push_back(tos);
                    }

                    // Pop the left parenthesis from the stack,
                    // but not onto the output queue.
                    stack.pop_back();
                    match = true;
                    break;
                }

                if (!match && stack.empty())
                {
                    // If the stack runs out without finding a left parenthesis,
                    // then there are mismatched parentheses.
                    printf("RightParen error (%s)\n", token.str.c_str());
                    setError(Token::operatorErr);
                    return queue;
                }
            }
            break;

            default:
                setError(Token::syntaxErr);

                printf("error (%s)\n", token.str.c_str());
                return queue;
                break;
        }

        //debugReport(token, queue, stack);
    }

    // When there are no more tokens to read:
    //   While there are still operator tokens in the stack:
    while (! stack.empty())
    {
        // If the operator token on the top of the stack is a parenthesis,
        // then there are mismatched parentheses.
        if (stack.back().type == Token::Type::LeftParen)
        {
            setError(Token::parenErr);
            //printf("Mismatched parentheses error\n");
            return queue;
        }

        // Pop the operator onto the output queue.
        queue.push_back(std::move(stack.back()));
        stack.pop_back();
    }

    //debugReport(Token { Token::Type::Unknown, "End" }, queue, stack);

    //Exit.
    return queue;
}

int CLASS::parseNumber(std::string n, int64_t &val)
{
    int res = DEF_VAL;
    int state = 0;
    char c;
    std::string s;
    uint32_t i, l;
    bool valid = false;
    bool err = false;
    bool neg = false;
    int base = 10;
    int64_t tval = 0;
    val = 0;



    i = 0;
    l = n.length();
    s = "";
    for (i = 0; i < l; i++)
    {
        c = n[i];
        switch (state)
        {
            case 0:
                if (c == '$')
                {
                    state = 10;
                }
                else if (c == '%')
                {
                    state = 20;
                }
                else if ((c == '-') && (!valid))
                {
                    neg = !neg;
                }
                else if (isdigit(c))
                {
                    s += c;
                    valid = true;
                    state = 1;
                    tval = c - '0';
                }
                else
                {
                    state = 99;
                }
                break;
            case 1:
                if (isdigit(c))
                {
                    s += c;
                    tval *= 10;
                    tval += c - '0';
                }
                else
                {
                    state = 99;
                }
                break;
            case 10:

                base = 16;
                if ((c >= 'a') && (c <= 'f'))
                {
                    c = c - 0x20; // make it uppercase
                    s += c;
                    tval <<= 4;
                    tval |= (c - 'A') + 10;
                    valid = true;
                }
                else if ((c >= 'A') && (c <= 'F'))
                {
                    s += c;
                    tval <<= 4;
                    tval |= (c - 'A') + 10;
                    valid = true;

                }
                else if ((c >= '0') && (c <= '9'))
                {
                    s += c;
                    tval <<= 4;;
                    tval += c - '0';
                    valid = true;
                }
                else { state = 99; }
                break;
            case 20:
                base = 2;
                if ((c >= '0') && (c <= '1'))
                {
                    s += c;
                    tval <<= 1;
                    if (c == '1')
                    {
                        tval |= 1;
                    }
                    valid = true;
                }
                else if (c == '_')
                {
                    // allow these in binary
                }
                else { state = 99; }
                break;

            case 99:
                setError(Token::syntaxErr);

                // if you get into this state there is an error
                break;
        }
    }

    if (tval > (int64_t)0xFFFFFFFF)
    {
        setError(Token::overflowErr);
    }


    if ((state == 99) || (err))
    {
        val = DEF_VAL;
    }

    if ((valid) && (!err))
    {
        if (neg)
        {
            tval = -tval;
        }
        val = tval;
        res = 0;
    }
    return (res);
}

void CLASS::setError(int ecode)
{
    if ((evalerror == Token::noError) || (ecode == Token::noError))
    {
        evalerror = ecode;
    }
    if (evalerror == Token::noError)
    {
        badsymbol = "";
    }
}

int CLASS::evaluate(std::string & e, int64_t &res)
{
    // const std::string expr = "3+4*2/(1-5)^2^3"; // Wikipedia's example
    // const std::string expr = "20-30/3+4*2^3";

    res = DEF_VAL;
    setError(Token::noError);

    int u;
    int64_t val;
    std::string expr = Poco::trim(e);
    expr += " "; // add a space at end to make parsing easier

    //printf("expression: |%s|\n",expr.c_str());

    const auto tokens = exprToTokens(expr);
    auto queue = shuntingYard(tokens);
    std::vector<int64_t> stack;

    // printf("\nCalculation\n");
    //printf("|%-3s|%-32s|%-10s|\n", "Tkn", "Queue", "Stack");

    while (! queue.empty())
    {
        //std::string op;

        const auto token = queue.front();
        queue.pop_front();
        switch (token.type)
        {
            case Token::Type::Symbol:
                stack.push_back(std::stoi((char *)"0"));
                //op = "Push " + token.str;
                //printf("shouldn't get this kind of token\n");
                break;
            case Token::Type::Number:
                val = 0;
                u = parseNumber(token.str, val);
                if (u < 0)
                {
                    setError(Token::numberErr);
                    val = DEF_VAL;
                }
                stack.push_back(val);
                //op = "Push " + token.str;
                break;

            case Token::Type::Operator:
            {

                auto rhs = DEF_VAL;
                auto lhs = DEF_VAL;

                bool v = true;
                if (stack.size() > 0)
                {
                    rhs = stack.back();
                    stack.pop_back();
                }
                else
                {
                    v = false;
                }
                if (stack.size() > 0)
                {
                    lhs = stack.back();
                    stack.pop_back();
                }
                else
                {
                    v = false;
                }

                if (!v)
                {
                    setError(Token::badParamErr);
                    //printf("not enough parameters for the operator\n");
                }

                switch (token.str[0])
                {
                    default:
                        setError(Token::operatorErr);
                        //printf("Operator error [%s]\n", token.str.c_str());
                        return (-1);
                        break;
                    case '^':
                        stack.push_back(static_cast<int>(pow(lhs, rhs)));
                        break;
                    case '*':
                        stack.push_back(lhs * rhs);
                        break;
                    case '/':
                        if (rhs != 0)
                        {
                            stack.push_back(lhs / rhs);
                        }
                        else
                        {
                            stack.push_back(0);
                        }
                        break;
                    case '+':
                        stack.push_back(lhs + rhs);
                        break;
                    case '-':
                        stack.push_back(lhs - rhs);
                        break;
                    case '!':
                        stack.push_back(lhs ^ rhs);
                        break;
                    case '&':
                        stack.push_back(lhs & rhs);
                        break;
                    break; case '.':
                        stack.push_back(lhs | rhs);
                        break;
                }
            }
            break;

            default:
                //printf("Token error\n");
                setError(Token::syntaxErr);
                goto out;
        }
    }

out:
    int64_t v = DEF_VAL;
    if (stack.size() > 0)
    {
        v = stack.back();
    }
    else
    {
        setError(Token::syntaxErr);
    }
    res = v;
    return (evalerror);
}
