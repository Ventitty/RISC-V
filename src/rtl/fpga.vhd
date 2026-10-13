library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fpga is
    generic (
        RESET_ACTIVE_LOW      : boolean := true;
        SEGMENTS_ACTIVE_LOW   : boolean := true;
        CLOCK_DIVIDE_EXPONENT : natural := 1
    );
    port (
        board_clock  : in  std_logic;
        reset_button : in  std_logic;
        hex_0        : out std_logic_vector(6 downto 0);
        hex_1        : out std_logic_vector(6 downto 0);
        hex_2        : out std_logic_vector(6 downto 0);
        hex_3        : out std_logic_vector(6 downto 0)
    );
end entity;

architecture Structural of fpga is

    signal reset           : std_logic;
    signal processor_clock : std_logic;
    signal display_value   : std_logic_vector(31 downto 0);

begin

    reset <= not reset_button when RESET_ACTIVE_LOW else reset_button;

    direct_clock : if CLOCK_DIVIDE_EXPONENT = 0 generate
        processor_clock <= board_clock;
    end generate direct_clock;

    divided_clock : if CLOCK_DIVIDE_EXPONENT > 0 generate
        signal clock_counter : unsigned(CLOCK_DIVIDE_EXPONENT-1 downto 0) := (others => '0');
    begin
        process (board_clock)
        begin
            if rising_edge(board_clock) then
                clock_counter <= clock_counter + 1;
            end if;
        end process;

        processor_clock <= clock_counter(CLOCK_DIVIDE_EXPONENT-1);
    end generate divided_clock;

    processor : entity work.riscv_core
        port map (
            clk           => processor_clock,
            reset         => reset,
            display_value => display_value
        );

    digit_0 : entity work.seven_segment_decoder
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(3 downto 0), segments => hex_0);

    digit_1 : entity work.seven_segment_decoder
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(7 downto 4), segments => hex_1);

    digit_2 : entity work.seven_segment_decoder
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(11 downto 8), segments => hex_2);

    digit_3 : entity work.seven_segment_decoder
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(15 downto 12), segments => hex_3);

end architecture Structural;
