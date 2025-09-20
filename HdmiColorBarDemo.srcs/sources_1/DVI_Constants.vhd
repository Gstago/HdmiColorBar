library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

package DVI_Constants is
   -- DVI Control Tokens
   constant kCtlTkn0 : std_logic_vector(9 downto 0) := "1101010100";
   constant kCtlTkn1 : std_logic_vector(9 downto 0) := "0010101011";
   constant kCtlTkn2 : std_logic_vector(9 downto 0) := "0101010100";
   constant kCtlTkn3 : std_logic_vector(9 downto 0) := "1010101011";
   
   constant kMinTknCntForBlank : natural := 128; --tB
   constant kBlankTimeoutMs : natural := 50;
end DVI_Constants;

package body DVI_Constants is 
end DVI_Constants;
