library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sign_ext is
    generic (
        INPUT_WIDTH : positive := 12
    );
    port (
        input_value    : in  std_logic_vector(INPUT_WIDTH-1 downto 0);
        extended_value : out std_logic_vector(31 downto 0)
    );
end entity sign_ext;

architecture RTL of sign_ext is
begin
    extended_value <= std_logic_vector(resize(signed(input_value), 32));
end architecture RTL;
