library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.CoeffPkg.all;

-- Complex first-order system with 4-stage pipelined IIR part
--
--  H(z) = (z - zo)/(z - p)
--
-- with complex zo, p. ->  H * (z+p)(z-jp)(z+jp)/(z+p)/(z-jp)/(z+jp)
--
--   Hpip(z) = H(z) * (z+p)(z+p^2)/(z+p)(z+p^2)
--
--              (z - zo)(z + p)(z^2 + p^2)    (z^2 + z (p - zo) - zo p) (z^2 + p^2)
--   Hpip(z) = --------------------------  =  -------------------------------------
--              (z^4 - p^4)                                z^4 - p^4
--
-- IIR:     y(n) = y(n-4) * Pp + x(n)
--
-- FIR:     x(n) + b(3) x(n-1) + b(2) x(n-2) + b(1) x(n-3) + b(0) x(n-4)
--
--          b(3) =       (p - zo)
--          b(2) =   p   (p - zo)
--          b(1) =   p^2 (p - zo)
--          b(0) = - p^3 zo       =  p^3 (p - zo) - p^4

entity FirstOrderComplex is
   generic (
      DATA_WIDTH_G : natural := 25
   );
   port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      -- complex input signal
      x_re     : in  signed(DATA_WIDTH_G - 1 downto 0);
      x_im     : in  signed(DATA_WIDTH_G - 1 downto 0);
      -- complex coefficients
      --   coeff(0)  -> Real( b(0) )
      --   coeff(1)  -> Imag( b(0) )
      --   ...
      --   coeff(10) -> Real( p^4  ) *** IIR coefficient (real)
      --   coeff(11) -> Imag( p^4  ) *** IIR coefficient (imag)
      coeffs   : in  CoeffArray(0 to 9);
      -- complex filter response
      y_re     : out signed(DATA_WIDTH_G - 1 downto 0);
      y_im     : out signed(DATA_WIDTH_G - 1 downto 0)
   );
end entity FirstOrderComplex;

architecture Impl of FirstOrderComplex is
   constant ORDER_C : natural := 4;

   type SignalArray    is array (natural range<>) of signed(DATA_WIDTH_G - 1 downto 0);

   signal s_re, s_im     : SignalArray(ORDER_C - 1 downto 0);
   signal ac_re, ac_im   : SignalArray(ORDER_C - 1 downto 0);
   signal y_re_i, y_im_i : signed(DATA_WIDTH_G     downto 0);
   -- last multiplier stage has a latency of 4; the ac_re/im output
   -- has a latency of 1; thus the x(n) term has to be delayed by 2
   -- cycles (one less than 4 - 1);
   signal xn_re, xn_im   : SignalArray(1 downto 0);
   signal fir_re, fir_im : signed(DATA_WIDTH_G downto 0);

begin

   GEN_NUM : for i in 0 to ORDER_C - 1 generate
      signal x_re_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal x_im_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal c_re_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal c_im_i : signed(DATA_WIDTH_G - 1 downto 0);
   begin
      GEN_FRST : if ( i = 0 ) generate
         x_re_i <= x_re;
         x_im_i <= x_im;
         c_re_i <= (others => '0');
         c_im_i <= (others => '0');
      end generate;

      GEN_OTH : if ( i /= 0 ) generate
         x_re_i <= ac_re(i - 1);
         x_im_i <= ac_im(i - 1);
         c_re_i <= s_re(i-1);
         c_im_i <= s_im(i-1);
      end generate;

      U_STAGE : entity work.ComplexMadd
         generic map (
            DATA_WIDTH_G => DATA_WIDTH_G
         )
         port map (
            clk     => clk,
            rst     => rst,
            a_re    => x_re_i,
            a_im    => x_im_i,
            b_re    => coeffs(2*i + 0),
            b_im    => coeffs(2*i + 1),
            c_re    => c_re_i,
            c_im    => c_im_i,
            y_re    => s_re(i),
            y_im    => s_im(i),
            ac_re   => ac_re(i),
            ac_im   => ac_im(i)
         );
   end generate;

   -- need to add the x(n) term
   P_X : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( rst = '1' ) then
            xn_re   <= (others => (others => '0') );
            xn_im   <= (others => (others => '0') );
            fir_re  <= (others => '0');
            fir_im  <= (others => '0');
         else
            for i in xn_re'left - 1 downto xn_re'right loop
               xn_re( i + 1 ) <= xn_re ( i );
               xn_im( i + 1 ) <= xn_im ( i );
            end loop;
            xn_re(0) <= ac_re(ORDER_C - 1);
            xn_im(0) <= ac_im(ORDER_C - 1);
            fir_re   <= resize( s_re(ORDER_C - 1), fir_re'length ) + resize( xn_re( xn_re'left ), fir_re'length );
            fir_im   <= resize( s_im(ORDER_C - 1), fir_re'length ) + resize( xn_im( xn_re'left ), fir_re'length );
         end if;
      end if;
   end process P_X;

   U_DEN : entity work.ComplexMadd
         generic map (
            DATA_WIDTH_G  => DATA_WIDTH_G,
            DINO_WIDTH_G  => DATA_WIDTH_G + 1
         )
         port map (
            clk     => clk,
            rst     => rst,
            a_re    => y_re_i(DATA_WIDTH_G - 1 downto 0),
            a_im    => y_im_i(DATA_WIDTH_G - 1 downto 0),
            b_re    => coeffs(2*ORDER_C + 0),
            b_im    => coeffs(2*ORDER_C + 1),
            c_re    => fir_re,
            c_im    => fir_im,
            y_re    => y_re_i,
            y_im    => y_im_i
         );

   y_re <= y_re_i(DATA_WIDTH_G - 1 downto 0);
   y_im <= y_im_i(DATA_WIDTH_G - 1 downto 0);

end architecture Impl;
