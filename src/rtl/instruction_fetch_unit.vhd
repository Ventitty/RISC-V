library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_fetch_unit is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        immediate       : in  std_logic_vector(31 downto 0);
        pc_select       : in  std_logic;
        instruction     : out std_logic_vector(31 downto 0);
        program_counter : out std_logic_vector(31 downto 0);
        pc_plus_4       : out std_logic_vector(31 downto 0)
    );
end entity instruction_fetch_unit;

architecture Structural of instruction_fetch_unit is

    signal current_address    : std_logic_vector(31 downto 0);
    signal next_address       : std_logic_vector(31 downto 0);
    signal sequential_address : std_logic_vector(31 downto 0);
    signal jump_address       : std_logic_vector(31 downto 0);

begin

    program_counter_register : entity work.PSR_register
        port map (
            clk          => clk,
            reset        => reset,
            next_address => next_address,
            address      => current_address
        );

    program_memory : entity work.instruction_memory
        port map (
            program_counter => current_address,
            instruction     => instruction
        );

    sequential_address <= std_logic_vector(unsigned(current_address) + 4);
    jump_address       <= std_logic_vector(unsigned(current_address) + unsigned(immediate));

    next_address_mux : entity work.mux2_1
        generic map (N => 32)
        port map (
            A   => sequential_address,
            B   => jump_address,
            COM => pc_select,
            S   => next_address
        );

    program_counter <= current_address;
    pc_plus_4       <= sequential_address;

end architecture Structural;
