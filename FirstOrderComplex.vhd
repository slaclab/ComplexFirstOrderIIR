library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.CoeffPkg.all;

entity FirstOrderComplex is
   generic (
      DATA_WIDTH_G : natural := 25
   );
   port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      x_re     : in  signed(DATA_WIDTH_G - 1 downto 0);
      x_im     : in  signed(DATA_WIDTH_G - 1 downto 0);
      coeffs   : in  CoeffArray(19 downto 0);
      y_re     : out signed(DATA_WIDTH_G - 1 downto 0);
      y_im     : out signed(DATA_WIDTH_G - 1 downto 0)
   );
end entity FirstOrderComplex;

architecture Impl of FirstOrderComplex is
   constant ORDER_C : natural := 4;

   type SignalArray    is array (natural range<>) of signed(DATA_WIDTH_G - 1 downto 0);

   signal s_re: SignalArray(ORDER_C - 1 downto 0);
   signal s_im: SignalArray(ORDER_C - 1 downto 0);

   signal ac_rr, ac_ri, ac_ir, ac_ii: SignalArray(ORDER_C - 1 downto 0);

   signal y_re_i, y_im_i : signed(DATA_WIDTH_G - 1 downto 0);

begin

   GEN_NUM : for i in 0 to ORDER_C - 1 generate
      signal x_rr_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal x_ri_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal x_ir_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal x_ii_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal c_re_i : signed(DATA_WIDTH_G - 1 downto 0);
      signal c_im_i : signed(DATA_WIDTH_G - 1 downto 0);
   begin
      GEN_FRST : if ( i = 0 ) generate
         x_rr_i <= x_re;
         x_ri_i <= x_re;
         x_ir_i <= x_im;
         x_ii_i <= x_im;
         c_re_i <= (others => '0');
         c_im_i <= (others => '0');
      end generate;

      GEN_OTH : if ( i /= 0 ) generate
         x_rr_i <= ac_rr(i - 1);
         x_ri_i <= ac_ri(i - 1);
         x_ir_i <= ac_ir(i - 1);
         x_ii_i <= ac_ii(i - 1);
         c_re_i <= s_re(i-1);
         c_im_i <= s_im(i-1);
      end generate;

      U_STAGE : entity work.ComplexMadd
         generic map (
            DATA_WIDTH_G => DATA_WIDTH_G,
            USE_CASC_G   => true
         )
         port map (
            clk     => clk,
            rst     => rst,
            a_rr    => x_rr_i,
            a_ri    => x_ri_i,
            a_ir    => x_ir_i,
            a_ii    => x_ii_i,
            b_rr    => coeffs(4*i + 0),
            b_ri    => coeffs(4*i + 1),
            b_ir    => coeffs(4*i + 2),
            b_ii    => coeffs(4*i + 3),
            c_re    => c_re_i,
            c_im    => c_im_i,
            y_re    => s_re(i),
            y_im    => s_im(i),
            ac_rr   => ac_rr(i),
            ac_ri   => ac_ri(i),
            ac_ir   => ac_ir(i),
            ac_ii   => ac_ii(i)
         );
   end generate;

   U_DEN : entity work.ComplexMadd
         generic map (
            DATA_WIDTH_G  => DATA_WIDTH_G
         )
         port map (
            clk     => clk,
            rst     => rst,
            a_re    => y_re_i,
            a_im    => y_im_i,
            b_rr    => coeffs(4*ORDER_C + 0),
            b_ri    => coeffs(4*ORDER_C + 1),
            b_ir    => coeffs(4*ORDER_C + 2),
            b_ii    => coeffs(4*ORDER_C + 3),
            c_re    => s_re(ORDER_C - 1),
            c_im    => s_im(ORDER_C - 1),
            y_re    => y_re_i,
            y_im    => y_im_i
         );

   y_re <= y_re_i;
   y_im <= y_im_i;

end architecture Impl;
