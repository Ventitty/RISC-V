library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fpga is
    generic (
        RESET_ACTIVE_LOW      : boolean := true;
        SEGMENTS_ACTIVE_LOW   : boolean := true;
        CLOCK_DIVIDE_EXPONENT : natural := 1;
        IRQ0_ACTIVE_LOW       : boolean := true;
        IRQ1_ACTIVE_LOW       : boolean := false;
        DEBOUNCE_COUNTER_BITS : positive := 18
    );
    port (
        board_clock  : in  std_logic;
        reset_button : in  std_logic;
        irq0_button  : in  std_logic;
        irq1_switch  : in  std_logic;
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
    signal irq0_raw        : std_logic;
    signal irq1_raw        : std_logic;
    signal irq0_clean      : std_logic;
    signal irq1_clean      : std_logic;

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

    irq0_raw <= not irq0_button when IRQ0_ACTIVE_LOW else irq0_button;
    irq1_raw <= not irq1_switch when IRQ1_ACTIVE_LOW else irq1_switch;

    irq0_debouncer : entity work.button_debouncer
        generic map (COUNTER_BITS => DEBOUNCE_COUNTER_BITS)
        port map (
            clk           => processor_clock,
            reset         => reset,
            noisy_input   => irq0_raw,
            stable_output => irq0_clean
        );

    irq1_debouncer : entity work.button_debouncer
        generic map (COUNTER_BITS => DEBOUNCE_COUNTER_BITS)
        port map (
            clk           => processor_clock,
            reset         => reset,
            noisy_input   => irq1_raw,
            stable_output => irq1_clean
        );

    processor : entity work.RISCV_CPU
        port map (
            clk           => processor_clock,
            reset         => reset,
            irq0          => irq0_clean,
            irq1          => irq1_clean,
            display_value => display_value
        );

    digit_0 : entity work.seven_seg
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(3 downto 0), segments => hex_0);

    digit_1 : entity work.seven_seg
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(7 downto 4), segments => hex_1);

    digit_2 : entity work.seven_seg
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(11 downto 8), segments => hex_2);

    digit_3 : entity work.seven_seg
        generic map (SEGMENTS_ACTIVE_LOW => SEGMENTS_ACTIVE_LOW)
        port map (hex_digit => display_value(15 downto 12), segments => hex_3);

end architecture Structural;
