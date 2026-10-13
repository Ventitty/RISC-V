library IEEE;
use IEEE.std_logic_1164.all;

entity PSR_register is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        next_address : in  std_logic_vector(31 downto 0);
        address      : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of PSR_register is
begin

    process (clk, reset)
    begin
        if reset = '1' then
            address <= (others => '0');
        elsif rising_edge(clk) then
            address <= next_address;
        end if;
    end process;

end architecture RTL;
