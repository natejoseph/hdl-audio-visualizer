library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my.all;

ENTITY SYNC IS
PORT(
CLK: IN STD_LOGIC;
HSYNC: OUT STD_LOGIC;
VSYNC: OUT STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(7 downto 0);
G: OUT STD_LOGIC_VECTOR(7 downto 0);
B: OUT STD_LOGIC_VECTOR(7 downto 0);
SW1: IN STD_LOGIC;
SW2: IN STD_LOGIC;
SW3: IN STD_LOGIC

);
END SYNC;


ARCHITECTURE MAIN OF SYNC IS

CONSTANT H_RES: INTEGER := 1280;
CONSTANT H_FRONT_PORCH: INTEGER := 48;
CONSTANT H_SYNC_PULSE: INTEGER := 112;
CONSTANT H_BACK_PORCH: INTEGER := 248;
CONSTANT H_TOTAL: INTEGER := H_RES + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; -- 1688

CONSTANT V_RES: INTEGER := 1024;
CONSTANT V_FRONT_PORCH: INTEGER := 1;
CONSTANT V_SYNC_PULSE: INTEGER := 3;
CONSTANT V_BACK_PORCH: INTEGER := 38;
CONSTANT V_TOTAL: INTEGER := V_RES + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; -- 1066

SIGNAL square1_size: INTEGER := 100;
SIGNAL square2_size: INTEGER := 200;
SIGNAL DRAW1, DRAW2: STD_LOGIC;
SIGNAL RGB: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL square1_x_axis,square1_y_axis: INTEGER RANGE 0 TO H_TOTAL:=0;
SIGNAL square2_x_axis,square2_y_axis: INTEGER RANGE 0 TO H_TOTAL:=600;
SIGNAL HPOS: INTEGER RANGE 0 TO H_TOTAL:=0;
SIGNAL VPOS: INTEGER RANGE 0 TO V_TOTAL:=0;
--SIGNAL HPOS: INTEGER RANGE 0 TO H_TOTAL - 1:=0;
--SIGNAL VPOS: INTEGER RANGE 0 TO V_TOTAL - 1:=0;

BEGIN
square(HPOS,VPOS,square1_x_axis,square1_y_axis,RGB,DRAW1);
square(HPOS,VPOS,square2_x_axis,square2_y_axis,RGB,DRAW2);
 PROCESS(CLK)
 BEGIN
 
IF(CLK'EVENT AND CLK='1')THEN
	R<=(others=>'1');
	G<=(others=>'1');
	B<=(others=>'0');
	
	--Frame control code

IF(HPOS < H_TOTAL - 1)THEN
	HPOS <= HPOS+1;
ELSE
	IF(VPOS < V_TOTAL - 1)THEN
		VPOS <= VPOS+1;
	ELSE
		VPOS <= 0;
	END IF;
	HPOS <= 0;
END IF;


--Porch control and synch control code
IF((HPOS >= H_RES) AND (HPOS < H_RES+H_FRONT_PORCH))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
END IF;

IF((HPOS >= H_RES+H_FRONT_PORCH+H_SYNC_PULSE) AND (HPOS < H_TOTAL))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
END IF;

IF((VPOS >= V_RES) AND (VPOS < V_RES+V_SYNC_PULSE))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
END IF;

IF((VPOS >= V_RES+V_FRONT_PORCH+V_SYNC_PULSE) AND (VPOS < H_TOTAL))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
END IF;

-- sync control
IF((HPOS >= H_RES + H_FRONT_PORCH) AND (HPOS < H_RES + H_FRONT_PORCH + H_SYNC_PULSE))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
	HSYNC <= '0';
ELSE
	HSYNC <= '1';
END IF;

IF((VPOS >= V_RES + V_FRONT_PORCH) AND (VPOS < V_RES + V_FRONT_PORCH + V_SYNC_PULSE))
THEN
	R<=(others=>'0');
	G<=(others=>'0');
	B<=(others=>'0');
	VSYNC <= '0';
ELSE
	VSYNC <= '1';
END IF;

IF((HPOS >= square1_x_axis) AND (HPOS < (square1_x_axis + square1_size)) AND (VPOS >= square1_y_axis) AND (VPOS < (square1_y_axis + square1_size))) THEN
	IF(SW3 = '1') THEN
		R <= "00000000";
		G <= "00000000";
		B <= "11111111";
	ELSE
		R <= "11111111";
		G <= "10100101";
		B <= "00000000";
	END IF;
END IF;

IF((HPOS >= square2_x_axis) AND (HPOS < (square2_x_axis + square2_size)) AND (VPOS >= square2_y_axis) AND (VPOS < (square2_y_axis + square2_size))) THEN
	R <= "10001010";
	G <= "00101011";
	B <= "11100010";
END IF;

	--Square signal control
IF SW1 = '1' THEN
	IF square1_x_axis < 1280 THEN
		square1_x_axis <= square1_x_axis+1;
	ELSE
		square1_x_axis <= 0;
	END IF;
END IF;

IF SW2 = '1' THEN
	IF square2_x_axis < 1280 THEN
		square2_x_axis <= square2_x_axis+1;
	ELSE
		square2_x_axis <= 0;
	END IF;
END IF;

 END IF;
 END PROCESS;
 END MAIN;