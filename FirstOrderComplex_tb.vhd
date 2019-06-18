------------------------------------------------------------------------------
-- This file is part of 'Pipelined First Order IIR'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'Pipelined First Order IIR', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.math_complex.all;
use     ieee.numeric_std.all;
use     work.CoeffPkg.all;

entity FirstOrderComplex_tb is
end entity FirstOrderComplex_tb;

architecture Impl of FirstOrderComplex_tb is
   constant DATA_WIDTH_G : natural := 25;

   constant Z0 : COMPLEX :=  ( re => 0.707,     im => -0.707     );
   constant P0 : COMPLEX :=  ( re => 0.9*0.707, im => -0.9*0.707 );

   signal clk : std_logic := '0';
   signal run : boolean   := true;
   signal cnt : integer   := 0;
   signal rst : std_logic := '1';

   signal x_re: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal x_im: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal coef: CoeffArray(0 to 9)                := to_CoeffArray( Z0, P0 );
   signal y_re: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal y_im: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal y_cmp_re, y_cmp_im : real;

   function to_Dat(x : integer) return signed is
   begin
      return to_signed(x, DATA_WIDTH_G);
   end function to_Dat;

   constant minus_one : signed := "10" & x"0000";

   signal y_sim   : COMPLEX;
   signal x_sim   : COMPLEX;
   signal x_sim_i : COMPLEX;

   constant scl : real := 2.0**17;

   constant FILT_DELAY_C : natural := 3 + 4 + 2;

   type  SimDelay is array( FILT_DELAY_C - 1 - 1 downto 0 ) of COMPLEX;

   signal x_sim_d : SimDelay := (others => ( re => 0.0, im => 0.0 ) );

begin

   P_CLK : process is
   begin
      if ( run ) then
         clk <= not clk;
         wait for 5 ns;
      else
         wait;
      end if;
   end process P_CLK;

   x_sim_i <= x_sim_d( x_sim_d'left );

   P_SIM : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( rst = '1' ) then
            y_sim.re <= 0.0;
            y_sim.im <= 0.0;
            x_sim.re <= 0.0;
            x_sim.im <= 0.0;
            for i in x_sim_d'left downto x_sim_d'right loop
               x_sim_d(i).re <= 0.0;
               x_sim_d(i).im <= 0.0;
            end loop;
         else
            y_sim <= y_sim * P0 + x_sim_i - Z0 * x_sim;
            x_sim <= x_sim_i;
            for i in x_sim_d'left - 1 downto x_sim_d'right loop
               x_sim_d(i + 1).re <= x_sim_d(i).re;
               x_sim_d(i + 1).im <= x_sim_d(i).im;
            end loop;
            x_sim_d(0).re <= real( to_integer( x_re ) );
            x_sim_d(0).im <= real( to_integer( x_im ) );
         end if;
      end if;
   end process P_SIM;

   P_CNT : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         case cnt is
            when 10    =>
               rst  <= '0';

            when 13    =>
               x_re <= to_Dat( 8765 );
            when 14    =>
               x_re <= to_Dat( 0    );
            when 500   =>
               run  <= false;
            when others => 
         end case;

         if ( cnt > 10 ) then
            assert abs( real(to_integer(y_re)) - y_sim.re ) < 4.0 severity failure;
            assert abs( real(to_integer(y_im)) - y_sim.im ) < 4.0 severity failure;
         end if;

         cnt <= cnt + 1;
      end if;
   end process P_CNT;

   U_DUT : entity work.FirstOrderComplex
      port map (
         clk           => clk,
         rst           => rst,
         x_re          => x_re,
         x_im          => x_im,
         coeffs        => coef,
         y_re          => y_re,
         y_im          => y_im
      );

end architecture Impl;
