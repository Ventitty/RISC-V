library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity button_debouncer is
    generic (
        COUNTER_BITS : positive := 18
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        noisy_input   : in  std_logic;
        stable_output : out std_logic
    );
end entity button_debouncer;

architecture RTL of button_debouncer is

    signal synchronizer_stage_1 : std_logic;
    signal synchronizer_stage_2 : std_logic;
    signal stable_value         : std_logic;
    signal stability_counter    : unsigned(COUNTER_BITS-1 downto 0);

begin

    process (clk, reset)
    begin
        if reset = '1' then
            synchronizer_stage_1 <= '0';
            synchronizer_stage_2 <= '0';
            stable_value         <= '0';
            stability_counter    <= (others => '0');
        elsif rising_edge(clk) then
            synchronizer_stage_1 <= noisy_input;
            synchronizer_stage_2 <= synchronizer_stage_1;

            if synchronizer_stage_2 = stable_value then
                stability_counter <= (others => '0');
            elsif stability_counter = (stability_counter'range => '1') then
                stable_value      <= synchronizer_stage_2;
                stability_counter <= (others => '0');
            else
                stability_counter <= stability_counter + 1;
            end if;
        end if;
    end process;

    stable_output <= stable_value;

end architecture RTL;
