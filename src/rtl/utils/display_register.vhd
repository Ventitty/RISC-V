library IEEE;
use IEEE.std_logic_1164.all;

entity display_register is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        write_enable : in  std_logic;
        input_data   : in  std_logic_vector(31 downto 0);
        output_data  : out std_logic_vector(31 downto 0)
    );
end entity display_register;

architecture RTL of display_register is
begin

    process (clk, reset)
    begin
        if reset = '1' then
            output_data <= (others => '0');
        elsif rising_edge(clk) then
            if write_enable = '1' then
                output_data <= input_data;
            end if;
        end if;
    end process;

end architecture RTL;
