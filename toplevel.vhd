LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY toplevel IS
   PORT ( 
      CLOCK_50        : IN    STD_LOGIC;               -- 50MHz system clock
      CLOCK2_50       : IN    STD_LOGIC;               -- Audio clock (50MHz)
      AUD_DACLRCK     : IN    STD_LOGIC;               -- DAC left/right clock from codec
      AUD_ADCLRCK     : IN    STD_LOGIC;               -- ADC left/right clock from codec
      AUD_BCLK        : IN    STD_LOGIC;               -- Bit clock from codec
      AUD_ADCDAT      : IN    STD_LOGIC;               -- ADC data from codec
      AUD_XCK         : OUT   STD_LOGIC;               -- Audio clock output to codec
      FPGA_I2C_SDAT   : INOUT STD_LOGIC;               -- I2C data for codec configuration
      FPGA_I2C_SCLK   : OUT   STD_LOGIC;               -- I2C clock for codec configuration
      AUD_DACDAT      : OUT   STD_LOGIC;               -- DAC data output to codec
      KEY             : IN    STD_LOGIC_VECTOR(0 DOWNTO 0)  -- Reset signal (KEY for reset)
   );
END toplevel;

ARCHITECTURE Behavior OF toplevel IS

   -- Clock generator component
   COMPONENT clock_generator
      PORT( 
         CLOCK_27 : IN  STD_LOGIC;
         reset    : IN  STD_LOGIC;
         AUD_XCK  : OUT STD_LOGIC
      );
   END COMPONENT;

   -- Audio and video configuration component
   COMPONENT audio_and_video_config
      PORT ( 
         CLOCK_50 : IN  STD_LOGIC;      -- System clock for configuration
         reset    : IN  STD_LOGIC;      -- Reset signal
         I2C_SCLK : OUT STD_LOGIC;      -- I2C clock signal
         I2C_SDAT : INOUT STD_LOGIC     -- I2C data signal
      );
   END COMPONENT;

   -- Update the audio_codec component declaration
   COMPONENT audio_codec
      PORT (
         CLOCK_50          : IN  STD_LOGIC;
         reset             : IN  STD_LOGIC;
         read_s, write_s   : IN  STD_LOGIC;
         writedata_left, writedata_right : IN  STD_LOGIC_VECTOR(23 downto 0);
         AUD_ADCDAT        : IN  STD_LOGIC;
         AUD_BCLK          : IN  STD_LOGIC;
         AUD_ADCLRCK       : IN  STD_LOGIC;
         AUD_DACLRCK       : IN  STD_LOGIC;
         read_ready, write_ready : OUT STD_LOGIC;
         readdata_left, readdata_right : OUT STD_LOGIC_VECTOR(23 downto 0);
         AUD_DACDAT        : OUT STD_LOGIC -- Change to OUT
      );
   END COMPONENT;

   -- Internal signals
   SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
   SIGNAL readdata_left, readdata_right            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL writedata_left, writedata_right          : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
   SIGNAL reset                                    : STD_LOGIC := '0';

BEGIN
   -- Reset signal from key input
   reset <= NOT(KEY(0));

   -- Instantiate the clock generator for the audio clock (AUD_XCK)
   my_clock_gen: clock_generator 
      PORT MAP (
         CLOCK_27 => CLOCK2_50,       -- Connect to the 50MHz clock input
         reset => reset,              -- Use the reset signal
         AUD_XCK => AUD_XCK           -- Audio clock output
      );

   -- Instantiate the audio and video configuration (for I2C configuration)
   my_audio_config: audio_and_video_config
      PORT MAP (
         CLOCK_50 => CLOCK_50,        -- 50MHz clock for configuration
         reset => reset,              -- Reset signal
         I2C_SCLK => FPGA_I2C_SCLK,   -- I2C clock for codec configuration
         I2C_SDAT => FPGA_I2C_SDAT    -- I2C data for codec configuration
      );

   -- Instantiate the audio codec
   my_audio_codec: audio_codec
      PORT MAP (
         CLOCK_50       => CLOCK_50,
         reset          => reset,
         read_s         => read_s,
         write_s        => write_s,
         writedata_left => writedata_left,
         writedata_right => writedata_right,
         AUD_ADCDAT     => AUD_ADCDAT,
         AUD_BCLK       => AUD_BCLK,
         AUD_ADCLRCK    => AUD_ADCLRCK,
         AUD_DACLRCK    => AUD_DACLRCK,
         read_ready     => read_ready,
         write_ready    => write_ready,
         readdata_left  => readdata_left,
         readdata_right => readdata_right,
         AUD_DACDAT     => AUD_DACDAT -- Directly connect the output
      );

   -- Connect read_s to read_ready
   read_s <= read_ready;

   -- Assert write_s when write_ready is asserted
   write_s <= write_ready;
   writedata_left <= readdata_left;   -- Loopback for left channel
   writedata_right <= readdata_right; -- Loopback for right channel

END Behavior;