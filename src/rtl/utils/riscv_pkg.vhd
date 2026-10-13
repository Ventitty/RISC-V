library IEEE;
use IEEE.std_logic_1164.all;

package riscv_pkg is

    constant ALU_OP_ADD               : std_logic_vector(2 downto 0) := "000";
    constant ALU_OP_SUB               : std_logic_vector(2 downto 0) := "001";
    constant ALU_OP_AND               : std_logic_vector(2 downto 0) := "010";
    constant ALU_OP_OR                : std_logic_vector(2 downto 0) := "011";
    constant ALU_OP_XOR               : std_logic_vector(2 downto 0) := "100";
    constant ALU_OP_SET_LESS_THAN     : std_logic_vector(2 downto 0) := "101";
    constant ALU_OP_SET_LESS_THAN_UNS : std_logic_vector(2 downto 0) := "110";
    constant ALU_OP_PASS_B            : std_logic_vector(2 downto 0) := "111";

    constant IMMEDIATE_FORMAT_I : std_logic_vector(2 downto 0) := "000";
    constant IMMEDIATE_FORMAT_S : std_logic_vector(2 downto 0) := "001";
    constant IMMEDIATE_FORMAT_B : std_logic_vector(2 downto 0) := "010";
    constant IMMEDIATE_FORMAT_U : std_logic_vector(2 downto 0) := "011";
    constant IMMEDIATE_FORMAT_J : std_logic_vector(2 downto 0) := "100";

    constant WRITEBACK_FROM_ALU       : std_logic_vector(1 downto 0) := "00";
    constant WRITEBACK_FROM_MEMORY    : std_logic_vector(1 downto 0) := "01";
    constant WRITEBACK_FROM_PC_PLUS_4 : std_logic_vector(1 downto 0) := "10";

    constant ALU_OPERAND_B_FROM_REGISTER  : std_logic := '0';
    constant ALU_OPERAND_B_FROM_IMMEDIATE : std_logic := '1';

    constant PC_SELECT_NEXT_INSTRUCTION : std_logic := '0';
    constant PC_SELECT_JUMP_TARGET      : std_logic := '1';

    constant OPCODE_LUI       : std_logic_vector(6 downto 0) := "0110111";
    constant OPCODE_JAL       : std_logic_vector(6 downto 0) := "1101111";
    constant OPCODE_BRANCH    : std_logic_vector(6 downto 0) := "1100011";
    constant OPCODE_LOAD      : std_logic_vector(6 downto 0) := "0000011";
    constant OPCODE_STORE     : std_logic_vector(6 downto 0) := "0100011";
    constant OPCODE_IMMEDIATE : std_logic_vector(6 downto 0) := "0010011";
    constant OPCODE_REGISTER  : std_logic_vector(6 downto 0) := "0110011";

    constant FUNCT3_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_WORD    : std_logic_vector(2 downto 0) := "010";
    constant FUNCT3_BEQ     : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_BNE     : std_logic_vector(2 downto 0) := "001";
    constant FUNCT3_BLT     : std_logic_vector(2 downto 0) := "100";

    constant FUNCT7_ADD : std_logic_vector(6 downto 0) := "0000000";
    constant FUNCT7_SUB : std_logic_vector(6 downto 0) := "0100000";

end package riscv_pkg;
