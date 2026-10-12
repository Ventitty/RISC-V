library IEEE;
use IEEE.std_logic_1164.all;
use work.riscv_pkg.all;

entity imm_gen is
    port (
        instruction      : in  std_logic_vector(31 downto 0);
        immediate_format : in  std_logic_vector(2 downto 0);
        immediate        : out std_logic_vector(31 downto 0)
    );
end entity imm_gen;

architecture RTL of imm_gen is
    signal i_type_bits : std_logic_vector(11 downto 0);
    signal s_type_bits : std_logic_vector(11 downto 0);
    signal b_type_bits : std_logic_vector(12 downto 0);
    signal j_type_bits : std_logic_vector(20 downto 0);

    signal i_type_immediate : std_logic_vector(31 downto 0);
    signal s_type_immediate : std_logic_vector(31 downto 0);
    signal b_type_immediate : std_logic_vector(31 downto 0);
    signal u_type_immediate : std_logic_vector(31 downto 0);
    signal j_type_immediate : std_logic_vector(31 downto 0);
begin

    i_type_bits <= instruction(31 downto 20);
    s_type_bits <= instruction(31 downto 25) & instruction(11 downto 7);
    b_type_bits <= instruction(31) & instruction(7) & instruction(30 downto 25)
                   & instruction(11 downto 8) & '0';
    j_type_bits <= instruction(31) & instruction(19 downto 12) & instruction(20)
                   & instruction(30 downto 21) & '0';

    extend_i_type : entity work.sign_ext
        generic map (INPUT_WIDTH => 12)
        port map (input_value => i_type_bits, extended_value => i_type_immediate);

    extend_s_type : entity work.sign_ext
        generic map (INPUT_WIDTH => 12)
        port map (input_value => s_type_bits, extended_value => s_type_immediate);

    extend_b_type : entity work.sign_ext
        generic map (INPUT_WIDTH => 13)
        port map (input_value => b_type_bits, extended_value => b_type_immediate);

    extend_j_type : entity work.sign_ext
        generic map (INPUT_WIDTH => 21)
        port map (input_value => j_type_bits, extended_value => j_type_immediate);

    u_type_immediate <= instruction(31 downto 12) & x"000";

    immediate <= i_type_immediate when immediate_format = IMMEDIATE_FORMAT_I else
                 s_type_immediate when immediate_format = IMMEDIATE_FORMAT_S else
                 b_type_immediate when immediate_format = IMMEDIATE_FORMAT_B else
                 u_type_immediate when immediate_format = IMMEDIATE_FORMAT_U else
                 j_type_immediate when immediate_format = IMMEDIATE_FORMAT_J else
                 (others => '0');

end architecture RTL;
