library IEEE;
use IEEE.std_logic_1164.all;
use work.riscv_pkg.all;

entity instruction_decoder is
    port (
        instruction           : in  std_logic_vector(31 downto 0);
        zero_flag             : in  std_logic;
        less_than_signed      : in  std_logic;
        pc_select             : out std_logic;
        register_write_enable : out std_logic;
        immediate_format      : out std_logic_vector(2 downto 0);
        alu_operand_b_select  : out std_logic;
        alu_control           : out std_logic_vector(2 downto 0);
        memory_write_enable   : out std_logic;
        writeback_select      : out std_logic_vector(1 downto 0);
        display_write_enable  : out std_logic
    );
end entity instruction_decoder;

architecture RTL of instruction_decoder is

    type instruction_type is (I_LUI, I_ADDI, I_ADD, I_SUB, I_LW, I_SW,
                              I_BEQ, I_BNE, I_BLT, I_JAL, I_INVALID);

    signal current_instruction : instruction_type;

    alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);
    alias funct3 : std_logic_vector(2 downto 0) is instruction(14 downto 12);
    alias funct7 : std_logic_vector(6 downto 0) is instruction(31 downto 25);

begin

    identify_instruction : process (opcode, funct3, funct7)
    begin
        current_instruction <= I_INVALID;

        if opcode = OPCODE_LUI then
            current_instruction <= I_LUI;

        elsif opcode = OPCODE_JAL then
            current_instruction <= I_JAL;

        elsif opcode = OPCODE_IMMEDIATE and funct3 = FUNCT3_ADD_SUB then
            current_instruction <= I_ADDI;

        elsif opcode = OPCODE_REGISTER and funct3 = FUNCT3_ADD_SUB then
            if funct7 = FUNCT7_ADD then
                current_instruction <= I_ADD;
            elsif funct7 = FUNCT7_SUB then
                current_instruction <= I_SUB;
            end if;

        elsif opcode = OPCODE_LOAD and funct3 = FUNCT3_WORD then
            current_instruction <= I_LW;

        elsif opcode = OPCODE_STORE and funct3 = FUNCT3_WORD then
            current_instruction <= I_SW;

        elsif opcode = OPCODE_BRANCH then
            if funct3 = FUNCT3_BEQ then
                current_instruction <= I_BEQ;
            elsif funct3 = FUNCT3_BNE then
                current_instruction <= I_BNE;
            elsif funct3 = FUNCT3_BLT then
                current_instruction <= I_BLT;
            end if;
        end if;
    end process identify_instruction;

    generate_commands : process (current_instruction, zero_flag, less_than_signed)
    begin
        pc_select             <= PC_SELECT_NEXT_INSTRUCTION;
        register_write_enable <= '0';
        immediate_format      <= IMMEDIATE_FORMAT_I;
        alu_operand_b_select  <= ALU_OPERAND_B_FROM_REGISTER;
        alu_control           <= ALU_OP_ADD;
        memory_write_enable   <= '0';
        writeback_select      <= WRITEBACK_FROM_ALU;
        display_write_enable  <= '0';

        case current_instruction is

            when I_ADD =>
                register_write_enable <= '1';

            when I_SUB =>
                register_write_enable <= '1';
                alu_control           <= ALU_OP_SUB;

            when I_ADDI =>
                register_write_enable <= '1';
                alu_operand_b_select  <= ALU_OPERAND_B_FROM_IMMEDIATE;

            when I_LUI =>
                register_write_enable <= '1';
                immediate_format      <= IMMEDIATE_FORMAT_U;
                alu_operand_b_select  <= ALU_OPERAND_B_FROM_IMMEDIATE;
                alu_control           <= ALU_OP_PASS_B;

            when I_LW =>
                register_write_enable <= '1';
                alu_operand_b_select  <= ALU_OPERAND_B_FROM_IMMEDIATE;
                writeback_select      <= WRITEBACK_FROM_MEMORY;

            when I_SW =>
                immediate_format      <= IMMEDIATE_FORMAT_S;
                alu_operand_b_select  <= ALU_OPERAND_B_FROM_IMMEDIATE;
                memory_write_enable   <= '1';
                display_write_enable  <= '1';

            when I_BEQ =>
                immediate_format      <= IMMEDIATE_FORMAT_B;
                alu_control           <= ALU_OP_SUB;
                pc_select             <= zero_flag;

            when I_BNE =>
                immediate_format      <= IMMEDIATE_FORMAT_B;
                alu_control           <= ALU_OP_SUB;
                pc_select             <= not zero_flag;

            when I_BLT =>
                immediate_format      <= IMMEDIATE_FORMAT_B;
                alu_control           <= ALU_OP_SUB;
                pc_select             <= less_than_signed;

            when I_JAL =>
                pc_select             <= PC_SELECT_JUMP_TARGET;
                register_write_enable <= '1';
                immediate_format      <= IMMEDIATE_FORMAT_J;
                writeback_select      <= WRITEBACK_FROM_PC_PLUS_4;

            when I_INVALID =>
                null;

        end case;
    end process generate_commands;

end architecture RTL;
