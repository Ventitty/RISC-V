library IEEE;
use IEEE.std_logic_1164.all;

entity mux2_1 is
    generic (
        N : positive := 32
    );
    port (
        A   : in  std_logic_vector(N-1 downto 0);
        B   : in  std_logic_vector(N-1 downto 0);
        COM : in  std_logic;
        S   : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture RTL of mux2_1 is
begin
    S <= B when COM = '1' else A;
end architecture RTL;
