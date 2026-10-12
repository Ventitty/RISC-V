library IEEE;
use IEEE.std_logic_1164.all;

entity mux3_1 is
    generic (
        N : positive := 32
    );
    port (
        A   : in  std_logic_vector(N-1 downto 0);
        B   : in  std_logic_vector(N-1 downto 0);
        C   : in  std_logic_vector(N-1 downto 0);
        COM : in  std_logic_vector(1 downto 0);
        S   : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture RTL of mux3_1 is
begin
    with COM select
        S <= B when "01",
             C when "10",
             A when others;
end architecture RTL;
