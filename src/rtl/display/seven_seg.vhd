library IEEE;
use IEEE.std_logic_1164.all;

entity seven_seg is
    generic (
        SEGMENTS_ACTIVE_LOW : boolean := true
    );
    port (
        hex_digit : in  std_logic_vector(3 downto 0);
        segments  : out std_logic_vector(6 downto 0)
    );
end entity;

architecture RTL of seven_seg is

    signal lit_segments : std_logic_vector(6 downto 0);

begin

    with hex_digit select
        lit_segments <= "0111111" when "0000",
                        "0000110" when "0001",
                        "1011011" when "0010",
                        "1001111" when "0011",
                        "1100110" when "0100",
                        "1101101" when "0101",
                        "1111101" when "0110",
                        "0000111" when "0111",
                        "1111111" when "1000",
                        "1101111" when "1001",
                        "1110111" when "1010",
                        "1111100" when "1011",
                        "0111001" when "1100",
                        "1011110" when "1101",
                        "1111001" when "1110",
                        "1110001" when "1111",
                        "0000000" when others;

    segments <= not lit_segments when SEGMENTS_ACTIVE_LOW else lit_segments;

end architecture RTL;
