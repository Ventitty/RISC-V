library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory is
    port (
        program_counter : in  std_logic_vector(31 downto 0);
        instruction     : out std_logic_vector(31 downto 0)
    );
end entity instruction_memory;

architecture RTL of instruction_memory is

    type memory_array is array (0 to 63) of std_logic_vector(31 downto 0);

    function initial_program return memory_array is
        variable program : memory_array;
    begin
        for word_index in 0 to 63 loop
            program(word_index) := (others => '0');
        end loop;

        program(0) := x"00000093";
        program(1) := x"00100113";
        program(2) := x"01700193";
        program(3) := x"00208233";
        program(4) := x"00010093";
        program(5) := x"00020113";
        program(6) := x"FFF18193";
        program(7) := x"FE0198E3";
        program(8) := x"06202823";
        program(9) := x"07002383";
        program(10) := x"0000B2B7";
        program(11) := x"52028293";
        program(12) := x"00100593";
        program(13) := x"40538333";
        program(14) := x"00030463";
        program(15) := x"0340006F";
        program(16) := x"00200593";
        program(17) := x"FFF00513";
        program(18) := x"00054463";
        program(19) := x"0240006F";
        program(20) := x"00300593";
        program(21) := x"0072CE63";
        program(22) := x"00400593";
        program(23) := x"004004EF";
        program(24) := x"06000613";
        program(25) := x"00C49663";
        program(26) := x"06202A23";
        program(27) := x"0000006F";
        program(28) := x"0000E6B7";
        program(29) := x"00B686B3";
        program(30) := x"06D02C23";
        program(31) := x"FF1FF06F";

        return program;
    end function initial_program;

    constant program_words : memory_array := initial_program;

begin

    instruction <= program_words(to_integer(unsigned(program_counter(7 downto 2))));

end architecture RTL;