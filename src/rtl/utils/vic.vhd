library IEEE;
use IEEE.std_logic_1164.all;

entity vic is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        irq_serv : in  std_logic;
        irq0     : in  std_logic;
        irq1     : in  std_logic;
        irq      : out std_logic;
        vic_pc   : out std_logic_vector(31 downto 0)
    );
end entity vic;

architecture RTL of vic is

    constant IRQ0_HANDLER_ADDRESS : std_logic_vector(31 downto 0) := x"00000024";
    constant IRQ1_HANDLER_ADDRESS : std_logic_vector(31 downto 0) := x"00000054";

    signal irq0_previous : std_logic;
    signal irq1_previous : std_logic;
    signal irq0_memo     : std_logic;
    signal irq1_memo     : std_logic;

begin

    process (clk, reset)
    begin
        if reset = '1' then
            irq0_previous <= '0';
            irq1_previous <= '0';
            irq0_memo     <= '0';
            irq1_memo     <= '0';
        elsif rising_edge(clk) then
            irq0_previous <= irq0;
            irq1_previous <= irq1;

            if irq_serv = '1' then
                if irq0_memo = '1' then
                    irq0_memo <= '0';
                else
                    irq1_memo <= '0';
                end if;
            end if;

            if irq0 = '1' and irq0_previous = '0' then
                irq0_memo <= '1';
            end if;

            if irq1 = '1' and irq1_previous = '0' then
                irq1_memo <= '1';
            end if;
        end if;
    end process;

    irq <= irq0_memo or irq1_memo;

    vic_pc <= IRQ0_HANDLER_ADDRESS when irq0_memo = '1' else
              IRQ1_HANDLER_ADDRESS when irq1_memo = '1' else
              (others => '0');

end architecture RTL;
