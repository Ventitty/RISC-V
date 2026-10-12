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

end package riscv_pkg;
