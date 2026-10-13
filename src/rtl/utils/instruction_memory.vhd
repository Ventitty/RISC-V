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

        program(0) := x"04000093";
        program(1) := x"00000113";
        program(2) := x"06800193";
        program(3) := x"0000A503";
        program(4) := x"00A10133";
        program(5) := x"00408093";
        program(6) := x"FE30CAE3";
        program(7) := x"0020A023";
        program(8) := x"FE1FF06F";

        return program;
    end function initial_program;

    constant program_words : memory_array := initial_program;

begin

    instruction <= program_words(to_integer(unsigned(program_counter(7 downto 2))));

end architecture RTL;
