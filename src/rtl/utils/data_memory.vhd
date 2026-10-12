library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity data_memory is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        write_data   : in  std_logic_vector(31 downto 0);
        read_data    : out std_logic_vector(31 downto 0);
        word_address : in  std_logic_vector(5 downto 0);
        write_enable : in  std_logic
    );
end entity data_memory;

architecture RTL of data_memory is

    type memory_array is array (0 to 63) of std_logic_vector(31 downto 0);

    function initial_memory_content return memory_array is
        variable content : memory_array;
    begin
        for word_index in 0 to 63 loop
            content(word_index) := (others => '0');
        end loop;
        for word_index in 16 to 25 loop
            content(word_index) := std_logic_vector(to_unsigned(word_index - 15, 32));
        end loop;
        return content;
    end function initial_memory_content;

    signal memory_words : memory_array := initial_memory_content;

begin

    write_word : process (clk, reset)
    begin
        if reset = '1' then
            memory_words <= initial_memory_content;
        elsif rising_edge(clk) then
            if write_enable = '1' then
                memory_words(to_integer(unsigned(word_address))) <= write_data;
            end if;
        end if;
    end process write_word;

    read_data <= memory_words(to_integer(unsigned(word_address)));

end architecture RTL;
