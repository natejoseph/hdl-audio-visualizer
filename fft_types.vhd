-- File: fft_types.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fft_types is
    -- Constants for FFT configuration
    constant FFT_SIZE  : integer := 1024;
    constant NUM_BINS  : integer := FFT_SIZE / 2;
    constant MAG_WIDTH : integer := 16;  -- Adjust based on your FFT magnitude width

    -- Type declaration for magnitude RAM
    type ram_type is array (0 to NUM_BINS - 1) of integer;
end package fft_types;
