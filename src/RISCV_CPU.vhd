library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
entity RISCV_CPU is
 Port ( clk : in STD_LOGIC;
 rst_n : in STD_LOGIC;
 led : out STD_LOGIC);
end entity;
architecture Behavioral of RISCV_CPU is
signal count : unsigned(24 downto 0);
begin
led <= count(24);
process(clk, rst_n)
begin
if rst_n = '0' then
 count <= (others => '0');
elsif rising_edge(clk) then
 count <= count +1;
end if;
end process;
end architecture;