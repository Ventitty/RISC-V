library IEEE;
use IEEE.std_logic_1164.all;

entity processing_unit is
    port (
        clk                   : in  std_logic;
        reset                 : in  std_logic;
        instruction           : in  std_logic_vector(31 downto 0);
        register_write_enable : in  std_logic;
        immediate_format      : in  std_logic_vector(2 downto 0);
        alu_operand_b_select  : in  std_logic;
        alu_control           : in  std_logic_vector(2 downto 0);
        memory_write_enable   : in  std_logic;
        writeback_select      : in  std_logic_vector(1 downto 0);
        pc_plus_4             : in  std_logic_vector(31 downto 0);
        immediate             : out std_logic_vector(31 downto 0);
        alu_result            : out std_logic_vector(31 downto 0);
        rs2_data              : out std_logic_vector(31 downto 0);
        zero_flag             : out std_logic;
        less_than_signed      : out std_logic;
        less_than_unsigned    : out std_logic
    );
end entity processing_unit;

architecture Structural of processing_unit is

    alias rs1_address : std_logic_vector(4 downto 0) is instruction(19 downto 15);
    alias rs2_address : std_logic_vector(4 downto 0) is instruction(24 downto 20);
    alias rd_address  : std_logic_vector(4 downto 0) is instruction(11 downto 7);

    signal rs1_value          : std_logic_vector(31 downto 0);
    signal rs2_value          : std_logic_vector(31 downto 0);
    signal writeback_data     : std_logic_vector(31 downto 0);
    signal extended_immediate : std_logic_vector(31 downto 0);
    signal alu_operand_b      : std_logic_vector(31 downto 0);
    signal operation_result   : std_logic_vector(31 downto 0);
    signal memory_read_data   : std_logic_vector(31 downto 0);

begin

    register_file : entity work.registers
        port map (
            CLK           => clk,
            RST           => reset,
            write_data    => writeback_data,
            RA            => rs1_address,
            RB            => rs2_address,
            write_address => rd_address,
            write_enable  => register_write_enable,
            A             => rs1_value,
            B             => rs2_value
        );

    immediate_generator : entity work.imm_gen
        port map (
            instruction      => instruction,
            immediate_format => immediate_format,
            immediate        => extended_immediate
        );

    alu_operand_b_mux : entity work.mux2_1
        generic map (N => 32)
        port map (
            A   => rs2_value,
            B   => extended_immediate,
            COM => alu_operand_b_select,
            S   => alu_operand_b
        );

    arithmetic_logic_unit : entity work.alu
        port map (
            alu_control        => alu_control,
            operand_a          => rs1_value,
            operand_b          => alu_operand_b,
            result             => operation_result,
            zero_flag          => zero_flag,
            less_than_signed   => less_than_signed,
            less_than_unsigned => less_than_unsigned
        );

    data_memory_block : entity work.data_memory
        port map (
            clk          => clk,
            reset        => reset,
            write_data   => rs2_value,
            read_data    => memory_read_data,
            word_address => operation_result(7 downto 2),
            write_enable => memory_write_enable
        );

    writeback_mux : entity work.mux3_1
        generic map (N => 32)
        port map (
            A   => operation_result,
            B   => memory_read_data,
            C   => pc_plus_4,
            COM => writeback_select,
            S   => writeback_data
        );

    immediate  <= extended_immediate;
    alu_result <= operation_result;
    rs2_data   <= rs2_value;

end architecture Structural;
