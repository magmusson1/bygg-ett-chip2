library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

type std_logic_matrix is array (integer range <>, integer range <>) of std_logic;

constant map_matrix : std_logic_matrix(0 to 2, 0 to 2) := (
    ('1', '0', '1'),
    ('0', '0', '0'),
    ('1', '0', '1')
);


entity tt_um_example is
    port (
        ui_in   : in  std_logic_vector(7 downto 0);
        uo_out  : out std_logic_vector(7 downto 0);
        uio_in  : in  std_logic_vector(7 downto 0);
        uio_out : out std_logic_vector(7 downto 0);
        uio_oe  : out std_logic_vector(7 downto 0);
        ena     : in  std_logic;
        clk     : in  std_logic;
        rst_n   : in  std_logic
    );
end tt_um_example;

architecture Behavioral of tt_um_example is
    signal grid : std_logic_vector(63 downto 0);
begin
    uo_out <= std_logic_vector(unsigned(ui_in) + unsigned(uio_in));
    uio_out <= "00000000";
    uio_oe <= "00000000";

end Behavioral;