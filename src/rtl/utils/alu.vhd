library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.riscv_pkg.all;

entity alu is
    port (
        alu_control        : in  std_logic_vector(2 downto 0);
        operand_a          : in  std_logic_vector(31 downto 0);
        operand_b          : in  std_logic_vector(31 downto 0);
        result             : out std_logic_vector(31 downto 0);
        zero_flag          : out std_logic;
        less_than_signed   : out std_logic;
        less_than_unsigned : out std_logic
    );
end entity alu;

architecture RTL of alu is
    signal a_less_than_b_signed   : std_logic;
    signal a_less_than_b_unsigned : std_logic;
    signal operation_result       : std_logic_vector(31 downto 0);
begin

    a_less_than_b_signed   <= '1' when signed(operand_a)   < signed(operand_b)   else '0';
    a_less_than_b_unsigned <= '1' when unsigned(operand_a) < unsigned(operand_b) else '0';

    compute_operation : process (alu_control, operand_a, operand_b,
                                 a_less_than_b_signed, a_less_than_b_unsigned)
    begin
        case alu_control is
            when ALU_OP_ADD =>
                operation_result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
            when ALU_OP_SUB =>
                operation_result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));
            when ALU_OP_AND =>
                operation_result <= operand_a and operand_b;
            when ALU_OP_OR =>
                operation_result <= operand_a or operand_b;
            when ALU_OP_XOR =>
                operation_result <= operand_a xor operand_b;
            when ALU_OP_SET_LESS_THAN =>
                operation_result <= (31 downto 1 => '0') & a_less_than_b_signed;
            when ALU_OP_SET_LESS_THAN_UNS =>
                operation_result <= (31 downto 1 => '0') & a_less_than_b_unsigned;
            when ALU_OP_PASS_B =>
                operation_result <= operand_b;
            when others =>
                operation_result <= (others => '0');
        end case;
    end process compute_operation;

    result             <= operation_result;
    zero_flag          <= '1' when operation_result = x"00000000" else '0';
    less_than_signed   <= a_less_than_b_signed;
    less_than_unsigned <= a_less_than_b_unsigned;

end architecture RTL;
