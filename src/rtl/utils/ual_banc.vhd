-- =============================================================================
-- ual_banc.vhd — Partie 1.1.2 — Assemblage UAL + banc de registres
--
-- Le résultat de l'UAL est rebouclé sur l'entrée d'écriture du banc :
--   x[write_address] <= x[read_address_a] (op) x[read_address_b]
-- Les deux données lues et le résultat sont exposés pour la vérification.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity ual_banc is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        read_address_a   : in  std_logic_vector(4 downto 0);
        read_address_b   : in  std_logic_vector(4 downto 0);
        write_address    : in  std_logic_vector(4 downto 0);
        write_enable     : in  std_logic;
        alu_control      : in  std_logic_vector(2 downto 0);
        read_data_a      : out std_logic_vector(31 downto 0);
        read_data_b      : out std_logic_vector(31 downto 0);
        alu_result       : out std_logic_vector(31 downto 0);
        zero_flag        : out std_logic;
        less_than_signed : out std_logic
    );
end entity ual_banc;

architecture Structural of ual_banc is
    signal register_data_a : std_logic_vector(31 downto 0);
    signal register_data_b : std_logic_vector(31 downto 0);
    signal operation_result : std_logic_vector(31 downto 0);
begin

    register_file : entity work.regfile
        port map (
            clk            => clk,
            reset          => reset,
            write_data     => operation_result,
            read_address_a => read_address_a,
            read_address_b => read_address_b,
            write_address  => write_address,
            write_enable   => write_enable,
            read_data_a    => register_data_a,
            read_data_b    => register_data_b
        );

    arithmetic_logic_unit : entity work.alu
        port map (
            alu_control        => alu_control,
            operand_a          => register_data_a,
            operand_b          => register_data_b,
            result             => operation_result,
            zero_flag          => zero_flag,
            less_than_signed   => less_than_signed,
            less_than_unsigned => open
        );

    read_data_a <= register_data_a;
    read_data_b <= register_data_b;
    alu_result  <= operation_result;

end architecture Structural;
