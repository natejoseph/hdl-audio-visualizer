library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY audiotovideotop IS
PORT(
		CLOCK_24: IN STD_LOGIC;
		VGA_HS,VGA_VS:OUT STD_LOGIC;
		VGA_R,VGA_B,VGA_G: OUT STD_LOGIC_VECTOR(7 downto 0);
		VGA_CLK: out std_logic;
		VGA_SW1: in std_logic;
		VGA_SW2: in std_logic;
		VGA_SW3: in std_logic;
		
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
END audiotovideotop;

ARCHITECTURE MAIN OF audiotovideotop IS
SIGNAL VGACLK,RESET:STD_LOGIC;
 
 COMPONENT SYNC IS
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
END COMPONENT SYNC;

component pqs is
		port (
			pll_0_refclk_clk  : in  std_logic := 'X'; -- clk
			pll_0_reset_reset : in  std_logic := 'X'; -- reset
			pll_0_outclk0_clk : out std_logic         -- clk
		);
end component pqs;

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
         CLOCK_24 : IN  STD_LOGIC;      -- System clock for configuration
         reset    : IN  STD_LOGIC;      -- Reset signal
         I2C_SCLK : OUT STD_LOGIC;      -- I2C clock signal
         I2C_SDAT : INOUT STD_LOGIC     -- I2C data signal
      );
   END COMPONENT;

   -- Update the audio_codec component declaration
   COMPONENT audio_codec
      PORT (
         CLOCK_24          : IN  STD_LOGIC;
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
	
	COMPONENT audio_frequency_extraction
    GENERIC (
        SAMPLE_WIDTH : integer := 24;   -- Audio sample width (bits)
        FFT_SIZE     : integer := 1024 -- FFT size (must be a power of 2)
    );
    PORT (
        clk              : IN  std_logic;                -- System clock
        reset            : IN  std_logic;                -- Reset signal
        audio_in         : IN  std_logic_vector(SAMPLE_WIDTH-1 DOWNTO 0); -- Input audio data
        data_valid       : IN  std_logic;                -- Indicates valid input sample
        fft_start        : OUT std_logic;                -- Signal to start FFT
        frequency_bin    : OUT integer range 0 TO FFT_SIZE/2-1; -- Frequency bin index
        magnitude        : OUT integer;                 -- Magnitude of the frequency bin
        fft_done         : OUT std_logic                 -- Indicates FFT is complete
    );
END COMPONENT;


   -- Internal signals
   SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
   SIGNAL readdata_left, readdata_right            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL writedata_left, writedata_right          : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
   SIGNAL reset1                                    : STD_LOGIC := '0';

	SIGNAL fft_start : STD_LOGIC;
	SIGNAL frequency_bin : integer range 0 to 1024/2-1;
	SIGNAL magnitude : integer;
	SIGNAL fft_done : STD_LOGIC;
	SIGNAL audio_data : std_logic_vector(23 DOWNTO 0);
	SIGNAL data_valid : std_logic := '0';
	
BEGIN
 

 --C: pll PORT MAP (CLOCK_24(0),RESET,VGACLK);
 C: pqs PORT MAP (
    pll_0_refclk_clk => CLOCK_24,
    pll_0_reset_reset => RESET1,    -- No reset functionality, keeping it low
    pll_0_outclk0_clk => VGACLK
);

 C1: SYNC PORT MAP(VGACLK,VGA_HS,VGA_VS,VGA_R,VGA_G,VGA_B, VGA_SW1, VGA_SW2, VGA_SW3);

 VGA_CLK <= VGACLK;
 
 -- Reset signal from key input
   reset1 <= NOT(KEY(0));

   -- Instantiate the clock generator for the audio clock (AUD_XCK)
   my_clock_gen: clock_generator 
      PORT MAP (
         CLOCK_27 => CLOCK2_50,       -- Connect to the 50MHz clock input
         reset => reset1,              -- Use the reset signal
         AUD_XCK => AUD_XCK           -- Audio clock output
      );

   -- Instantiate the audio and video configuration (for I2C configuration)
   my_audio_config: audio_and_video_config
      PORT MAP (
         CLOCK_24 => CLOCK_24,        -- 50MHz clock for configuration
         reset => reset1,              -- Reset signal
         I2C_SCLK => FPGA_I2C_SCLK,   -- I2C clock for codec configuration
         I2C_SDAT => FPGA_I2C_SDAT    -- I2C data for codec configuration
      );

   -- Instantiate the audio codec
   my_audio_codec: audio_codec
      PORT MAP (
         CLOCK_24       => CLOCK_24,
         reset          => reset1,
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
		
	my_audio_frequency_extraction: audio_frequency_extraction
    GENERIC MAP (
        SAMPLE_WIDTH => 24,
        FFT_SIZE     => 1024
    )
    PORT MAP (
        clk           => CLOCK_24,       -- Use the system clock
        reset         => reset1,         -- Reset signal
        audio_in      => audio_data,     -- Input audio data
        data_valid    => data_valid,     -- Indicates valid input sample
        fft_start     => fft_start,      -- Signal to start FFT
        frequency_bin => frequency_bin,  -- Frequency bin index
        magnitude     => magnitude,      -- Magnitude of the frequency bin
        fft_done      => fft_done        -- Indicates FFT is complete
    );

   -- Connect read_s to read_ready
   read_s <= read_ready;
	audio_data <= readdata_left;
	data_valid <= read_ready;

   -- Assert write_s when write_ready is asserted
   write_s <= write_ready;
   writedata_left <= readdata_left;   -- Loopback for left channel
   writedata_right <= readdata_right; -- Loopback for right channel
 
 END MAIN;