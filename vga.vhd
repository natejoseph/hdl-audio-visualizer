library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY VGA IS
PORT(
CLOCK_24: IN STD_LOGIC_VECTOR(1 downto 0);
VGA_HS,VGA_VS:OUT STD_LOGIC;
VGA_R,VGA_B,VGA_G: OUT STD_LOGIC_VECTOR(7 downto 0);
VGA_CLK: out std_logic
);
END VGA;


ARCHITECTURE MAIN OF VGA IS
SIGNAL VGACLK,RESET:STD_LOGIC;
 
 COMPONENT SYNC IS
 PORT(
	CLK: IN STD_LOGIC;
HSYNC: OUT STD_LOGIC;
VSYNC: OUT STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(7 downto 0);
G: OUT STD_LOGIC_VECTOR(7 downto 0);
B: OUT STD_LOGIC_VECTOR(7 downto 0)

	);
END COMPONENT SYNC;

component pll is
		port (
			clk_in_clk  : in  std_logic := 'X'; -- clk
			reset_1_reset : in  std_logic := 'X'; -- reset
			clk_out_clk : out std_logic         -- clk
		);
end component pll;

BEGIN
 

 --C: pll PORT MAP (CLOCK_24(0),RESET,VGACLK);
 C: pll PORT MAP (
    clk_in_clk => CLOCK_24(0),
    reset_1_reset => RESET,    -- No reset functionality, keeping it low
    clk_out_clk => VGACLK
);

 C1: SYNC PORT MAP(VGACLK,VGA_HS,VGA_VS,VGA_R,VGA_G,VGA_B, VGA_SW1, VGA_SW2, VGA_SW3);

 VGA_CLK <= VGACLK;
 
 END MAIN;
 