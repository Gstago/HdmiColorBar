library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.DVI_Constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity TMDS_Encoder is
   Port (
      PixelClk : in std_logic;   --Recovered TMDS clock x1 (CLKDIV)
      SerialClk : in std_logic;  --Recovered TMDS clock x5 (CLK)
      aRst : in std_logic;       --asynchronous reset; must be reset when PixelClk/SerialClk is not within spec
      
      --Encoded parallel data
      pDataOutRaw : out std_logic_vector(9 downto 0);
      
      --Unencoded parallel data
      pDataOut : in std_logic_vector(7 downto 0);
      pC0 : in std_logic;
      pC1 : in std_logic;
      pVde : in std_logic
   );
end TMDS_Encoder;

architecture Behavioral of TMDS_Encoder is

signal pDataOut_1 : std_logic_vector(7 downto 0);
signal q_m_1, q_m_xor_1, q_m_xnor_1, q_m_2: std_logic_vector(8 downto 0);
signal control_token_2, q_out_2: std_logic_vector(9 downto 0);
signal n1d_1, n1q_m_2, n0q_m_2, n1q_m_1 : unsigned(3 downto 0); --range 0-8
signal dc_bias_2, cnt_t_3, cnt_t_2 : signed(4 downto 0) := "00000"; --range -8 - +8 + sign
signal pC0_1, pC1_1, pVde_1, pC0_2, pC1_2, pVde_2 : std_logic;
signal cond_not_balanced_2, cond_balanced_2 : std_logic;

function sum_bits(u : std_logic_vector) return unsigned is
   variable sum : unsigned(3 downto 0);
	begin
      assert u'length < 16 report "sum_bits error";
      sum := to_unsigned(0,4);
		for i in u'range loop
         sum := sum + unsigned(u(i downto i));
		end loop;
		return sum;
	end sum_bits;
	
begin

----------------------------------------------------------------------------------
-- DVI 1.0 Specs Figure 3-5
-- Pipeline stage 1, minimise transitions
----------------------------------------------------------------------------------
Stage1: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		pVde_1 <= pVde;

		n1d_1 <= sum_bits(pDataOut(7 downto 0));
		pDataOut_1 <= pDataOut; --insert data into the pipeline;
		pC0_1 <= pC0; --insert control into the pipeline;
		pC1_1 <= pC1;
	end if;
end process Stage1;

----------------------------------------------------------------------------------
-- Choose one of the two encoding options based on n1d_1
----------------------------------------------------------------------------------
q_m_xor_1(0) <= pDataOut_1(0);
encode1: for i in 1 to 7 generate
	q_m_xor_1(i) <= q_m_xor_1(i-1) xor pDataOut_1(i);
end generate encode1;
q_m_xor_1(8) <= '1';

q_m_xnor_1(0) <= pDataOut_1(0);
encode2: for i in 1 to 7 generate
	q_m_xnor_1(i) <= q_m_xnor_1(i-1) xnor pDataOut_1(i);
end generate encode2;
q_m_xnor_1(8) <= '0';

q_m_1 <= q_m_xnor_1 when n1d_1 > 4 or (n1d_1 = 4 and pDataOut_1(0) = '0') else
         q_m_xor_1;

n1q_m_1 <= sum_bits(q_m_1(7 downto 0));
		
----------------------------------------------------------------------------------
-- Pipeline stage 2, balance DC
----------------------------------------------------------------------------------
Stage2: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		n1q_m_2 <= n1q_m_1;
		n0q_m_2 <= 8 - n1q_m_1;
		q_m_2 <= q_m_1;
		pC0_2 <= pC0_1;
		pC1_2 <= pC1_1;
		pVde_2 <= pVde_1;
	end if;
end process Stage2;

cond_balanced_2 <=   '1' when cnt_t_3 = 0 or n1q_m_2 = 4 else -- DC balanced output
						   '0';
cond_not_balanced_2 <=  '1' when (cnt_t_3 > 0 and n1q_m_2 > 4) or -- too many 1's
									 (cnt_t_3 < 0 and n1q_m_2 < 4) else -- too many 0's
                        '0';

control_token_2 <= 	kCtlTkn0 when pC1_2 = '0' and pC0_2 = '0' else
                     kCtlTkn1 when pC1_2 = '0' and pC0_2 = '1' else
                     kCtlTkn2 when pC1_2 = '1' and pC0_2 = '0' else
                     kCtlTkn3;
							
q_out_2 <=  control_token_2												when pVde_2 = '0' else	--control period
			   not q_m_2(8) & q_m_2(8) & not q_m_2(7 downto 0)    when cond_balanced_2 = '1' and q_m_2(8) = '0' else
			   not q_m_2(8) & q_m_2(8) & q_m_2(7 downto 0)        when cond_balanced_2 = '1' and q_m_2(8) = '1' else
			   '1' & q_m_2(8) & not q_m_2(7 downto 0)             when cond_not_balanced_2 = '1' else
			   '0' & q_m_2(8) & q_m_2(7 downto 0);	--DC balanced

dc_bias_2 <= signed('0' & n0q_m_2) - signed('0' & n1q_m_2);

cnt_t_2 <=  to_signed(0, cnt_t_2'length)                                   when pVde_2 = '0' else	--control period
			   cnt_t_3 + dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(8) = '0' else
			   cnt_t_3 - dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(8) = '1' else
			   cnt_t_3 + signed('0' & q_m_2(8 downto 8) & '0') + dc_bias_2	   when cond_not_balanced_2 = '1' else
			   cnt_t_3 - signed('0' & not q_m_2(8 downto 8) & '0') - dc_bias_2;

----------------------------------------------------------------------------------
-- Pipeline stage 3, registered output
----------------------------------------------------------------------------------
Stage3: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      cnt_t_3 <= cnt_t_2;
      pDataOutRaw <= q_out_2; --encoded, ready to be serialized
   end if;
end process Stage3;
		
end Behavioral;
