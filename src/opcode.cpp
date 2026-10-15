#include "intern.hpp"

#include <array>
#include <cstring>

namespace qasm {

struct Enc {
    const char *name;
    AddrMode am;
    uint8_t opc;
    uint8_t cpu;
};

static const Enc ENC[] = {
    /* ADC */
    {"ADC", AM_IMM, 0x69, CPU_6502}, {"ADC", AM_DP, 0x65, CPU_6502},
    {"ADC", AM_DPX, 0x75, CPU_6502}, {"ADC", AM_INDX, 0x61, CPU_6502},
    {"ADC", AM_INDY, 0x71, CPU_6502}, {"ADC", AM_ABS, 0x6D, CPU_6502},
    {"ADC", AM_ABSX, 0x7D, CPU_6502}, {"ADC", AM_ABSY, 0x79, CPU_6502},
    {"ADC", AM_IND, 0x72, CPU_65C02}, {"ADC", AM_LONG, 0x6F, CPU_65816},
    {"ADC", AM_LONGX, 0x7F, CPU_65816}, {"ADC", AM_SR, 0x63, CPU_65816},
    {"ADC", AM_SRIY, 0x73, CPU_65816}, {"ADC", AM_INDL, 0x67, CPU_65816},
    {"ADC", AM_INDLY, 0x77, CPU_65816},
    /* AND */
    {"AND", AM_IMM, 0x29, CPU_6502}, {"AND", AM_DP, 0x25, CPU_6502},
    {"AND", AM_DPX, 0x35, CPU_6502}, {"AND", AM_INDX, 0x21, CPU_6502},
    {"AND", AM_INDY, 0x31, CPU_6502}, {"AND", AM_ABS, 0x2D, CPU_6502},
    {"AND", AM_ABSX, 0x3D, CPU_6502}, {"AND", AM_ABSY, 0x39, CPU_6502},
    {"AND", AM_IND, 0x32, CPU_65C02}, {"AND", AM_LONG, 0x2F, CPU_65816},
    {"AND", AM_LONGX, 0x3F, CPU_65816}, {"AND", AM_SR, 0x23, CPU_65816},
    {"AND", AM_SRIY, 0x33, CPU_65816}, {"AND", AM_INDL, 0x27, CPU_65816},
    {"AND", AM_INDLY, 0x37, CPU_65816},
    /* ASL */
    {"ASL", AM_IMP, 0x0A, CPU_6502}, {"ASL", AM_DP, 0x06, CPU_6502},
    {"ASL", AM_DPX, 0x16, CPU_6502}, {"ASL", AM_ABS, 0x0E, CPU_6502},
    {"ASL", AM_ABSX, 0x1E, CPU_6502},
    /* BIT */
    {"BIT", AM_DP, 0x24, CPU_6502}, {"BIT", AM_ABS, 0x2C, CPU_6502},
    {"BIT", AM_DPX, 0x34, CPU_65C02}, {"BIT", AM_ABSX, 0x3C, CPU_65C02},
    {"BIT", AM_IMM, 0x89, CPU_65C02},
    /* CMP */
    {"CMP", AM_IMM, 0xC9, CPU_6502}, {"CMP", AM_DP, 0xC5, CPU_6502},
    {"CMP", AM_DPX, 0xD5, CPU_6502}, {"CMP", AM_INDX, 0xC1, CPU_6502},
    {"CMP", AM_INDY, 0xD1, CPU_6502}, {"CMP", AM_ABS, 0xCD, CPU_6502},
    {"CMP", AM_ABSX, 0xDD, CPU_6502}, {"CMP", AM_ABSY, 0xD9, CPU_6502},
    {"CMP", AM_IND, 0xD2, CPU_65C02}, {"CMP", AM_LONG, 0xCF, CPU_65816},
    {"CMP", AM_LONGX, 0xDF, CPU_65816}, {"CMP", AM_SR, 0xC3, CPU_65816},
    {"CMP", AM_SRIY, 0xD3, CPU_65816}, {"CMP", AM_INDL, 0xC7, CPU_65816},
    {"CMP", AM_INDLY, 0xD7, CPU_65816},
    /* CPX/CPY */
    {"CPX", AM_IMM, 0xE0, CPU_6502}, {"CPX", AM_DP, 0xE4, CPU_6502},
    {"CPX", AM_ABS, 0xEC, CPU_6502},
    {"CPY", AM_IMM, 0xC0, CPU_6502}, {"CPY", AM_DP, 0xC4, CPU_6502},
    {"CPY", AM_ABS, 0xCC, CPU_6502},
    /* DEC */
    {"DEC", AM_IMP, 0x3A, CPU_65C02}, {"DEC", AM_DP, 0xC6, CPU_6502},
    {"DEC", AM_DPX, 0xD6, CPU_6502}, {"DEC", AM_ABS, 0xCE, CPU_6502},
    {"DEC", AM_ABSX, 0xDE, CPU_6502},
    /* EOR */
    {"EOR", AM_IMM, 0x49, CPU_6502}, {"EOR", AM_DP, 0x45, CPU_6502},
    {"EOR", AM_DPX, 0x55, CPU_6502}, {"EOR", AM_INDX, 0x41, CPU_6502},
    {"EOR", AM_INDY, 0x51, CPU_6502}, {"EOR", AM_ABS, 0x4D, CPU_6502},
    {"EOR", AM_ABSX, 0x5D, CPU_6502}, {"EOR", AM_ABSY, 0x59, CPU_6502},
    {"EOR", AM_IND, 0x52, CPU_65C02}, {"EOR", AM_LONG, 0x4F, CPU_65816},
    {"EOR", AM_LONGX, 0x5F, CPU_65816}, {"EOR", AM_SR, 0x43, CPU_65816},
    {"EOR", AM_SRIY, 0x53, CPU_65816}, {"EOR", AM_INDL, 0x47, CPU_65816},
    {"EOR", AM_INDLY, 0x57, CPU_65816},
    /* INC */
    {"INC", AM_IMP, 0x1A, CPU_65C02}, {"INC", AM_DP, 0xE6, CPU_6502},
    {"INC", AM_DPX, 0xF6, CPU_6502}, {"INC", AM_ABS, 0xEE, CPU_6502},
    {"INC", AM_ABSX, 0xFE, CPU_6502},
    /* JMP / JML */
    {"JMP", AM_ABS, 0x4C, CPU_6502}, {"JMP", AM_ABSIND, 0x6C, CPU_6502},
    {"JMP", AM_ABSINDX, 0x7C, CPU_65C02}, {"JMP", AM_LONG, 0x5C, CPU_65816},
    {"JMP", AM_ABSINDL, 0xDC, CPU_65816},
    {"JML", AM_LONG, 0x5C, CPU_65816}, {"JML", AM_ABSINDL, 0xDC, CPU_65816},
    /* JSR / JSL */
    {"JSR", AM_ABS, 0x20, CPU_6502}, {"JSR", AM_ABSINDX, 0xFC, CPU_65816},
    {"JSR", AM_LONG, 0x22, CPU_65816},
    {"JSL", AM_LONG, 0x22, CPU_65816},
    /* LDA */
    {"LDA", AM_IMM, 0xA9, CPU_6502}, {"LDA", AM_DP, 0xA5, CPU_6502},
    {"LDA", AM_DPX, 0xB5, CPU_6502}, {"LDA", AM_INDX, 0xA1, CPU_6502},
    {"LDA", AM_INDY, 0xB1, CPU_6502}, {"LDA", AM_ABS, 0xAD, CPU_6502},
    {"LDA", AM_ABSX, 0xBD, CPU_6502}, {"LDA", AM_ABSY, 0xB9, CPU_6502},
    {"LDA", AM_IND, 0xB2, CPU_65C02}, {"LDA", AM_LONG, 0xAF, CPU_65816},
    {"LDA", AM_LONGX, 0xBF, CPU_65816}, {"LDA", AM_SR, 0xA3, CPU_65816},
    {"LDA", AM_SRIY, 0xB3, CPU_65816}, {"LDA", AM_INDL, 0xA7, CPU_65816},
    {"LDA", AM_INDLY, 0xB7, CPU_65816},
    /* LDX */
    {"LDX", AM_IMM, 0xA2, CPU_6502}, {"LDX", AM_DP, 0xA6, CPU_6502},
    {"LDX", AM_DPY, 0xB6, CPU_6502}, {"LDX", AM_ABS, 0xAE, CPU_6502},
    {"LDX", AM_ABSY, 0xBE, CPU_6502},
    /* LDY */
    {"LDY", AM_IMM, 0xA0, CPU_6502}, {"LDY", AM_DP, 0xA4, CPU_6502},
    {"LDY", AM_DPX, 0xB4, CPU_6502}, {"LDY", AM_ABS, 0xAC, CPU_6502},
    {"LDY", AM_ABSX, 0xBC, CPU_6502},
    /* LSR */
    {"LSR", AM_IMP, 0x4A, CPU_6502}, {"LSR", AM_DP, 0x46, CPU_6502},
    {"LSR", AM_DPX, 0x56, CPU_6502}, {"LSR", AM_ABS, 0x4E, CPU_6502},
    {"LSR", AM_ABSX, 0x5E, CPU_6502},
    /* ORA */
    {"ORA", AM_IMM, 0x09, CPU_6502}, {"ORA", AM_DP, 0x05, CPU_6502},
    {"ORA", AM_DPX, 0x15, CPU_6502}, {"ORA", AM_INDX, 0x01, CPU_6502},
    {"ORA", AM_INDY, 0x11, CPU_6502}, {"ORA", AM_ABS, 0x0D, CPU_6502},
    {"ORA", AM_ABSX, 0x1D, CPU_6502}, {"ORA", AM_ABSY, 0x19, CPU_6502},
    {"ORA", AM_IND, 0x12, CPU_65C02}, {"ORA", AM_LONG, 0x0F, CPU_65816},
    {"ORA", AM_LONGX, 0x1F, CPU_65816}, {"ORA", AM_SR, 0x03, CPU_65816},
    {"ORA", AM_SRIY, 0x13, CPU_65816}, {"ORA", AM_INDL, 0x07, CPU_65816},
    {"ORA", AM_INDLY, 0x17, CPU_65816},
    /* ROL / ROR */
    {"ROL", AM_IMP, 0x2A, CPU_6502}, {"ROL", AM_DP, 0x26, CPU_6502},
    {"ROL", AM_DPX, 0x36, CPU_6502}, {"ROL", AM_ABS, 0x2E, CPU_6502},
    {"ROL", AM_ABSX, 0x3E, CPU_6502},
    {"ROR", AM_IMP, 0x6A, CPU_6502}, {"ROR", AM_DP, 0x66, CPU_6502},
    {"ROR", AM_DPX, 0x76, CPU_6502}, {"ROR", AM_ABS, 0x6E, CPU_6502},
    {"ROR", AM_ABSX, 0x7E, CPU_6502},
    /* SBC */
    {"SBC", AM_IMM, 0xE9, CPU_6502}, {"SBC", AM_DP, 0xE5, CPU_6502},
    {"SBC", AM_DPX, 0xF5, CPU_6502}, {"SBC", AM_INDX, 0xE1, CPU_6502},
    {"SBC", AM_INDY, 0xF1, CPU_6502}, {"SBC", AM_ABS, 0xED, CPU_6502},
    {"SBC", AM_ABSX, 0xFD, CPU_6502}, {"SBC", AM_ABSY, 0xF9, CPU_6502},
    {"SBC", AM_IND, 0xF2, CPU_65C02}, {"SBC", AM_LONG, 0xEF, CPU_65816},
    {"SBC", AM_LONGX, 0xFF, CPU_65816}, {"SBC", AM_SR, 0xE3, CPU_65816},
    {"SBC", AM_SRIY, 0xF3, CPU_65816}, {"SBC", AM_INDL, 0xE7, CPU_65816},
    {"SBC", AM_INDLY, 0xF7, CPU_65816},
    /* STA */
    {"STA", AM_DP, 0x85, CPU_6502}, {"STA", AM_DPX, 0x95, CPU_6502},
    {"STA", AM_INDX, 0x81, CPU_6502}, {"STA", AM_INDY, 0x91, CPU_6502},
    {"STA", AM_ABS, 0x8D, CPU_6502}, {"STA", AM_ABSX, 0x9D, CPU_6502},
    {"STA", AM_ABSY, 0x99, CPU_6502}, {"STA", AM_IND, 0x92, CPU_65C02},
    {"STA", AM_LONG, 0x8F, CPU_65816}, {"STA", AM_LONGX, 0x9F, CPU_65816},
    {"STA", AM_SR, 0x83, CPU_65816}, {"STA", AM_SRIY, 0x93, CPU_65816},
    {"STA", AM_INDL, 0x87, CPU_65816}, {"STA", AM_INDLY, 0x97, CPU_65816},
    /* STX / STY / STZ */
    {"STX", AM_DP, 0x86, CPU_6502}, {"STX", AM_DPY, 0x96, CPU_6502},
    {"STX", AM_ABS, 0x8E, CPU_6502},
    {"STY", AM_DP, 0x84, CPU_6502}, {"STY", AM_DPX, 0x94, CPU_6502},
    {"STY", AM_ABS, 0x8C, CPU_6502},
    {"STZ", AM_DP, 0x64, CPU_65C02}, {"STZ", AM_DPX, 0x74, CPU_65C02},
    {"STZ", AM_ABS, 0x9C, CPU_65C02}, {"STZ", AM_ABSX, 0x9E, CPU_65C02},
    /* TRB / TSB */
    {"TRB", AM_DP, 0x14, CPU_65C02}, {"TRB", AM_ABS, 0x1C, CPU_65C02},
    {"TSB", AM_DP, 0x04, CPU_65C02}, {"TSB", AM_ABS, 0x0C, CPU_65C02},
    /* branches */
    {"BPL", AM_REL, 0x10, CPU_6502}, {"BMI", AM_REL, 0x30, CPU_6502},
    {"BVC", AM_REL, 0x50, CPU_6502}, {"BVS", AM_REL, 0x70, CPU_6502},
    {"BCC", AM_REL, 0x90, CPU_6502}, {"BCS", AM_REL, 0xB0, CPU_6502},
    {"BNE", AM_REL, 0xD0, CPU_6502}, {"BEQ", AM_REL, 0xF0, CPU_6502},
    {"BLT", AM_REL, 0x90, CPU_6502}, {"BGE", AM_REL, 0xB0, CPU_6502},
    {"BRA", AM_REL, 0x80, CPU_65C02}, {"BRL", AM_RELL, 0x82, CPU_65816},
    /* stack / implied */
    {"BRK", AM_IMP, 0x00, CPU_6502}, {"BRK", AM_IMM8, 0x00, CPU_6502},
    {"RTI", AM_IMP, 0x40, CPU_6502}, {"RTS", AM_IMP, 0x60, CPU_6502},
    {"PHP", AM_IMP, 0x08, CPU_6502}, {"CLC", AM_IMP, 0x18, CPU_6502},
    {"PLP", AM_IMP, 0x28, CPU_6502}, {"SEC", AM_IMP, 0x38, CPU_6502},
    {"PHA", AM_IMP, 0x48, CPU_6502}, {"CLI", AM_IMP, 0x58, CPU_6502},
    {"PLA", AM_IMP, 0x68, CPU_6502}, {"SEI", AM_IMP, 0x78, CPU_6502},
    {"DEY", AM_IMP, 0x88, CPU_6502}, {"TYA", AM_IMP, 0x98, CPU_6502},
    {"TAY", AM_IMP, 0xA8, CPU_6502}, {"CLV", AM_IMP, 0xB8, CPU_6502},
    {"INY", AM_IMP, 0xC8, CPU_6502}, {"CLD", AM_IMP, 0xD8, CPU_6502},
    {"INX", AM_IMP, 0xE8, CPU_6502}, {"SED", AM_IMP, 0xF8, CPU_6502},
    {"TXA", AM_IMP, 0x8A, CPU_6502}, {"TXS", AM_IMP, 0x9A, CPU_6502},
    {"TAX", AM_IMP, 0xAA, CPU_6502}, {"TSX", AM_IMP, 0xBA, CPU_6502},
    {"DEX", AM_IMP, 0xCA, CPU_6502}, {"NOP", AM_IMP, 0xEA, CPU_6502},
    {"PHY", AM_IMP, 0x5A, CPU_65C02}, {"PLY", AM_IMP, 0x7A, CPU_65C02},
    {"PHX", AM_IMP, 0xDA, CPU_65C02}, {"PLX", AM_IMP, 0xFA, CPU_65C02},
    /* 65816 implied / stack */
    {"PHD", AM_IMP, 0x0B, CPU_65816}, {"PLD", AM_IMP, 0x2B, CPU_65816},
    {"PHK", AM_IMP, 0x4B, CPU_65816}, {"RTL", AM_IMP, 0x6B, CPU_65816},
    {"PHB", AM_IMP, 0x8B, CPU_65816}, {"PLB", AM_IMP, 0xAB, CPU_65816},
    {"WAI", AM_IMP, 0xCB, CPU_65816}, {"STP", AM_IMP, 0xDB, CPU_65816},
    {"XBA", AM_IMP, 0xEB, CPU_65816}, {"SWA", AM_IMP, 0xEB, CPU_65816},
    {"XCE", AM_IMP, 0xFB, CPU_65816},
    {"TCS", AM_IMP, 0x1B, CPU_65816}, {"TAS", AM_IMP, 0x1B, CPU_65816},
    {"TSC", AM_IMP, 0x3B, CPU_65816}, {"TSA", AM_IMP, 0x3B, CPU_65816},
    {"TCD", AM_IMP, 0x5B, CPU_65816}, {"TAD", AM_IMP, 0x5B, CPU_65816},
    {"TDC", AM_IMP, 0x7B, CPU_65816}, {"TDA", AM_IMP, 0x7B, CPU_65816},
    {"TXY", AM_IMP, 0x9B, CPU_65816}, {"TYX", AM_IMP, 0xBB, CPU_65816},
    {"COP", AM_IMM8, 0x02, CPU_65816}, {"WDM", AM_IMM8, 0x42, CPU_65816},
    {"WDM", AM_IMP, 0x42, CPU_65816},
    /* stack ops with operand */
    {"PEA", AM_IMM16, 0xF4, CPU_65816}, {"PEA", AM_ABS, 0xF4, CPU_65816},
    {"PEI", AM_IND, 0xD4, CPU_65816}, {"PEI", AM_DP, 0xD4, CPU_65816},
    {"PER", AM_RELL, 0x62, CPU_65816},
    /* block */
    {"MVN", AM_BLK, 0x54, CPU_65816}, {"MVP", AM_BLK, 0x44, CPU_65816},
    /* REP / SEP */
    {"REP", AM_IMM, 0xC2, CPU_65816}, {"REP", AM_IMM8, 0xC2, CPU_65816},
    {"SEP", AM_IMM, 0xE2, CPU_65816}, {"SEP", AM_IMM8, 0xE2, CPU_65816},
};

static const Enc *find_enc(const std::string &name, AddrMode am, int cpu)
{
    for (size_t i = 0; i < sizeof(ENC) / sizeof(ENC[0]); i++) {
        if (icmp(ENC[i].name, name.c_str()) == 0 && ENC[i].am == am && ENC[i].cpu <= cpu)
            return &ENC[i];
    }
    return nullptr;
}

std::string opcode_canonical(const std::string &name, int &force_out, bool &long_mn)
{
    force_out = FORCE_NONE;
    long_mn = false;
    std::string tmp = name;
    while (!tmp.empty() && (tmp.back() == ':' || tmp.back() == '\\')) {
        force_out = FORCE_ABS;
        tmp.pop_back();
    }
    if (tmp.size() > 1 && (tmp.back() == 'Z' || tmp.back() == 'z' ||
                           tmp.back() == 'D' || tmp.back() == 'd')) {
        std::string base = tmp.substr(0, tmp.size() - 1);
        if (find_enc(base, AM_DP, CPU_65816) || find_enc(base, AM_DP, CPU_6502)) {
            force_out = FORCE_DP;
            tmp = base;
        }
    }
    if (tmp.size() > 1 && (tmp.back() == 'L' || tmp.back() == 'l')) {
        std::string base = tmp.substr(0, tmp.size() - 1);
        if (icmp(base, "LDA") == 0 || icmp(base, "STA") == 0 ||
            icmp(base, "ADC") == 0 || icmp(base, "SBC") == 0 ||
            icmp(base, "AND") == 0 || icmp(base, "ORA") == 0 ||
            icmp(base, "EOR") == 0 || icmp(base, "CMP") == 0 ||
            icmp(base, "JMP") == 0) {
            long_mn = true;
            tmp = base;
        }
    }
    return tmp;
}

int opcode_encode(const std::string &cname, AddrMode am, int cpu, uint8_t &opc)
{
    const Enc *e = find_enc(cname, am, cpu);
    if (!e) return -1;
    opc = e->opc;
    return 0;
}

bool opcode_supports(const std::string &cname, AddrMode am, int cpu)
{
    return find_enc(cname, am, cpu) != nullptr;
}

bool is_branch(const std::string &cname)
{
    static const char *b[] = {
        "BPL", "BMI", "BVC", "BVS", "BCC", "BCS", "BNE", "BEQ",
        "BLT", "BGE", "BRA", "BRL", nullptr
    };
    for (int i = 0; b[i]; i++)
        if (icmp(cname, b[i]) == 0) return true;
    return icmp(cname, "PER") == 0;
}

bool is_branch_long(const std::string &cname)
{
    return icmp(cname, "BRL") == 0 || icmp(cname, "PER") == 0;
}

bool is_alu_acc(const std::string &cname)
{
    return icmp(cname, "ASL") == 0 || icmp(cname, "LSR") == 0 ||
           icmp(cname, "ROL") == 0 || icmp(cname, "ROR") == 0 ||
           icmp(cname, "INC") == 0 || icmp(cname, "DEC") == 0;
}

int imm_width_reg(const std::string &cname)
{
    if (icmp(cname, "SEP") == 0 || icmp(cname, "REP") == 0 ||
        icmp(cname, "COP") == 0 || icmp(cname, "WDM") == 0 ||
        icmp(cname, "BRK") == 0)
        return 8;
    if (icmp(cname, "PEA") == 0) return 16;
    if (icmp(cname, "LDX") == 0 || icmp(cname, "LDY") == 0 ||
        icmp(cname, "CPX") == 0 || icmp(cname, "CPY") == 0)
        return 1;
    return 0;
}

} // namespace qasm
