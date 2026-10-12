library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity registers is
    port (
        CLK           : in  std_logic;
        RST           : in  std_logic;
        write_data    : in  std_logic_vector(31 downto 0);
        RA            : in  std_logic_vector(4 downto 0);
        RB            : in  std_logic_vector(4 downto 0);
        write_address : in  std_logic_vector(4 downto 0);
        write_enable  : in  std_logic;
        A             : out std_logic_vector(31 downto 0);
        B             : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of registers is

    type register_array is array(31 downto 0) of std_logic_vector(31 downto 0);

    function init_register_values return register_array is
        variable values : register_array;
    begin
        for register_index in 30 downto 0 loop
            values(register_index) := (others => '0');
        end loop;

        values(31) := x"00000030";

        return values;
    end function init_register_values;

    signal registers_list : register_array := init_register_values;
    constant REGISTER_ZERO_ADDRESS : std_logic_vector(4 downto 0) := "00000";
begin
    process (CLK, RST)
    begin
        if RST = '1' then
            registers_list <= init_register_values;
        elsif rising_edge(CLK) then
            if write_enable = '1' and write_address /= REGISTER_ZERO_ADDRESS then
                registers_list(to_integer(unsigned(write_address))) <= write_data;
            end if;
        end if;
    end process;

    A <= (others => '0') when RA = REGISTER_ZERO_ADDRESS
         else registers_list(to_integer(unsigned(RA)));

    B <= (others => '0') when RB = REGISTER_ZERO_ADDRESS
         else registers_list(to_integer(unsigned(RB)));

end architecture RTL;
