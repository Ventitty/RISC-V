library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
    port (
        clk                   : in  std_logic;
        reset                 : in  std_logic;
        instruction           : in  std_logic_vector(31 downto 0);
        zero_flag             : in  std_logic;
        less_than_signed      : in  std_logic;
        rs2_data              : in  std_logic_vector(31 downto 0);
        pc_select             : out std_logic;
        register_write_enable : out std_logic;
        immediate_format      : out std_logic_vector(2 downto 0);
        alu_operand_b_select  : out std_logic;
        alu_control           : out std_logic_vector(2 downto 0);
        memory_write_enable   : out std_logic;
        writeback_select      : out std_logic_vector(1 downto 0);
        display_value         : out std_logic_vector(31 downto 0)
    );
end entity control_unit;

architecture Structural of control_unit is

    signal display_write_enable : std_logic;

begin

    decoder : entity work.instruction_decoder
        port map (
            instruction           => instruction,
            zero_flag             => zero_flag,
            less_than_signed      => less_than_signed,
            pc_select             => pc_select,
            register_write_enable => register_write_enable,
            immediate_format      => immediate_format,
            alu_operand_b_select  => alu_operand_b_select,
            alu_control           => alu_control,
            memory_write_enable   => memory_write_enable,
            writeback_select      => writeback_select,
            display_write_enable  => display_write_enable
        );

    display_value_register : entity work.display_register
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => display_write_enable,
            input_data   => rs2_data,
            output_data  => display_value
        );

end architecture Structural;
