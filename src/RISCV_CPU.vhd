library IEEE;
use IEEE.std_logic_1164.all;

entity RISCV_CPU is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        irq0          : in  std_logic;
        irq1          : in  std_logic;
        display_value : out std_logic_vector(31 downto 0)
    );
end entity;

architecture Structural of RISCV_CPU is

    signal instruction           : std_logic_vector(31 downto 0);
    signal program_counter       : std_logic_vector(31 downto 0);
    signal pc_plus_4             : std_logic_vector(31 downto 0);
    signal immediate             : std_logic_vector(31 downto 0);
    signal alu_result            : std_logic_vector(31 downto 0);
    signal rs2_data              : std_logic_vector(31 downto 0);
    signal zero_flag             : std_logic;
    signal less_than_signed      : std_logic;
    signal less_than_unsigned    : std_logic;

    signal pc_select             : std_logic;
    signal register_write_enable : std_logic;
    signal immediate_format      : std_logic_vector(2 downto 0);
    signal alu_operand_b_select  : std_logic;
    signal alu_control           : std_logic_vector(2 downto 0);
    signal memory_write_enable   : std_logic;
    signal writeback_select      : std_logic_vector(1 downto 0);

    signal irq                   : std_logic;
    signal vic_pc                : std_logic_vector(31 downto 0);
    signal irq_end               : std_logic;
    signal irq_serv              : std_logic;

begin

    fetch : entity work.instruction_fetch_unit
        port map (
            clk             => clk,
            reset           => reset,
            immediate       => immediate,
            pc_select       => pc_select,
            irq             => irq,
            vic_pc          => vic_pc,
            irq_end         => irq_end,
            instruction     => instruction,
            program_counter => program_counter,
            pc_plus_4       => pc_plus_4,
            irq_serv        => irq_serv
        );

    processing : entity work.processing_unit
        port map (
            clk                   => clk,
            reset                 => reset,
            instruction           => instruction,
            register_write_enable => register_write_enable,
            immediate_format      => immediate_format,
            alu_operand_b_select  => alu_operand_b_select,
            alu_control           => alu_control,
            memory_write_enable   => memory_write_enable,
            writeback_select      => writeback_select,
            pc_plus_4             => pc_plus_4,
            immediate             => immediate,
            alu_result            => alu_result,
            rs2_data              => rs2_data,
            zero_flag             => zero_flag,
            less_than_signed      => less_than_signed,
            less_than_unsigned    => less_than_unsigned
        );

    control : entity work.control_unit
        port map (
            clk                   => clk,
            reset                 => reset,
            instruction           => instruction,
            zero_flag             => zero_flag,
            less_than_signed      => less_than_signed,
            rs2_data              => rs2_data,
            pc_select             => pc_select,
            register_write_enable => register_write_enable,
            immediate_format      => immediate_format,
            alu_operand_b_select  => alu_operand_b_select,
            alu_control           => alu_control,
            memory_write_enable   => memory_write_enable,
            writeback_select      => writeback_select,
            display_value         => display_value,
            irq_end               => irq_end
        );

    interrupt_controller : entity work.vic
        port map (
            clk      => clk,
            reset    => reset,
            irq_serv => irq_serv,
            irq0     => irq0,
            irq1     => irq1,
            irq      => irq,
            vic_pc   => vic_pc
        );

end architecture Structural;
