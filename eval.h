#pragma once

// Shunting-yard Algorithm
// http://en.wikipedia.org/wiki/Shunting-yard_algorithm
//
// https://ideone.com/kn4FUu
//
#include "asm.h"
#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <deque>
#include <stdio.h>
#include <math.h>

#define CLASS TEvaluator

class T65816Asm;

class Token
{
public:
    enum evalErr {
        noError = 0,
        unknownSymbolErr = -1,
        forwardRef = -2,
        operatorErr = -3,
        syntaxErr = -4,
        parenErr = -5,
        overflowErr = -6,
        divideErr = -7,
        badParamErr = -8,
        numberErr = -9,
        maxError
    };

    enum Type
    {
        Unknown = 0,
        Number,
        Symbol,
        Operator,
        LeftParen,
        RightParen,
    };

    Token(Type t, const std::string& s, int prec = -1, bool ra = false)
        : type { t }, str ( s ), precedence { prec }, rightAssociative { ra }
    {}

    Type type;
    std::string str;
    int precedence;
    bool rightAssociative;
};

class CLASS
{
protected:
    T65816Asm &assembler;
    int evalerror;
    void setError(int ecode);
public:
    CLASS(T65816Asm &_asm);
    ~CLASS();
    std::string badsymbol;
    std::deque<Token> shuntingYard(const std::deque<Token>& tokens);
    std::deque<Token> exprToTokens(const std::string& expr);
    int parseNumber(std::string n, int64_t &val);
    int evaluate(std::string &expr, int64_t &res);

};

//std::ostream& operator<<(std::ostream& os, const Token& token)
//{
//    os << token.str;
//    return os;
//}


// Debug output
template<class T, class U>
void debugReport(const Token& token, const T& queue, const U& stack, const std::string& comment = "")
{
    std::ostringstream ossQueue;
    for (const auto& t : queue)
    {
        ossQueue << " " << t;
    }

    std::ostringstream ossStack;
    for (const auto& t : stack)
    {
        ossStack << " " << t;
    }

    printf("|%-3s|%-32s|%10s| %s\n"
           , token.str.c_str()
           , ossQueue.str().c_str()
           , ossStack.str().c_str()
           , comment.c_str()
          );
}

#undef CLASS
