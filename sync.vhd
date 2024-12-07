library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fft_types.all;

ENTITY SYNC IS
PORT(
CLK: IN STD_LOGIC;
HSYNC: OUT STD_LOGIC;
VSYNC: OUT STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(7 downto 0);
G: OUT STD_LOGIC_VECTOR(7 downto 0);
B: OUT STD_LOGIC_VECTOR(7 downto 0);
magnitude_ram: IN ram_type
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

CONSTANT FFT_SIZE : INTEGER := 1024;
CONSTANT NUM_BINS : INTEGER := FFT_SIZE / 2;
CONSTANT MAX_MAGNITUDE : INTEGER := 100000;
CONSTANT MAG_WIDTH : INTEGER := 16;

type ram_type is array (0 to NUM_BINS - 1) of std_logic_vector(MAG_WIDTH - 1 downto 0);

SIGNAL HPOS: INTEGER RANGE 0 TO H_TOTAL:=0;
SIGNAL VPOS: INTEGER RANGE 0 TO V_TOTAL:=0;
--SIGNAL HPOS: INTEGER RANGE 0 TO H_TOTAL - 1:=0;
--SIGNAL VPOS: INTEGER RANGE 0 TO V_TOTAL - 1:=0;

SIGNAL display_enable : STD_LOGIC;


BEGIN

 PROCESS(CLK)
	VARIABLE bin_index_var : INTEGER RANGE 0 TO NUM_BINS - 1;
	VARIABLE magnitude_value_var : INTEGER;
	VARIABLE bar_height_var : INTEGER;
 BEGIN
	IF (CLK'EVENT AND CLK='1') THEN

		IF(HPOS < H_TOTAL - 1)THEN
			HPOS <= HPOS+1;
		ELSE
			HPOS <= 0;
			IF VPOS < V_TOTAL - 1 THEN
				VPOS <= VPOS + 1;
			ELSE
				VPOS <= 0;
			END IF;
		END IF;

		IF((HPOS >= H_RES + H_FRONT_PORCH) AND (HPOS < H_RES + H_FRONT_PORCH + H_SYNC_PULSE))
		THEN
			HSYNC <= '0';
		ELSE
			HSYNC <= '1';
		END IF;

		IF((VPOS >= V_RES + V_FRONT_PORCH) AND (VPOS < V_RES + V_FRONT_PORCH + V_SYNC_PULSE))
		THEN
			VSYNC <= '0';
		ELSE
			VSYNC <= '1';
		END IF;


		IF (HPOS < H_RES) AND (VPOS < V_RES) THEN
			display_enable <= '1';
		ELSE
			display_enable <= '0';
		END IF;

		IF display_enable = '1' THEN
                -- Calculate bin index based on horizontal position
                bin_index_var := (HPOS * NUM_BINS) / H_RES;

                -- Ensure bin_index_var is within range
                IF bin_index_var > 0 AND bin_index_var < NUM_BINS THEN
                    -- Retrieve magnitude from magnitude_ram
                    magnitude_value_var := magnitude_ram(bin_index_var);

                    -- Scale magnitude to bar height (linear scaling)
                    bar_height_var := (magnitude_value_var * V_RES) / MAX_MAGNITUDE;

                    -- Limit bar_height_var to V_RES
                    IF bar_height_var > V_RES THEN
                        bar_height_var := V_RES;
                    END IF;

                    -- Determine if current pixel is within the bar
                    IF VPOS >= V_RES - bar_height_var THEN
                        -- Inside the bar
                        R <= X"FF";  -- Red color
                        G <= X"00";
                        B <= X"00";
                    ELSE
                        -- Background
                        R <= X"00";  -- Green color
                        G <= X"FF";
                        B <= X"00";
                    END IF;
                ELSE
                    -- Invalid bin index
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
                END IF;
            ELSE
                -- Outside display area
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            END IF;
	END IF;
END PROCESS;
 END MAIN;