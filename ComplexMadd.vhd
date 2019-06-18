library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CoeffPkg.all;

-- Complex multiply-add with 4-stage pipeline
--
--   y(n) = a(n-4) * b(n-4) + c(n - 2)
--

entity ComplexMadd is
   generic (
      DATA_WIDTH_G  : natural := 25;
      USE_CASC_G    : boolean := false
   );
   port (
      clk          : in  std_logic;
      rst          : in  std_logic;
      b_rr         : in  signed( COEFF_WIDTH_C - 1 downto 0 );
      b_ri         : in  signed( COEFF_WIDTH_C - 1 downto 0 );
      b_ir         : in  signed( COEFF_WIDTH_C - 1 downto 0 );
      b_ii         : in  signed( COEFF_WIDTH_C - 1 downto 0 );
      a_re, a_im   : in  signed( DATA_WIDTH_G  - 1 downto 0 ) := (others => '0');
      a_rr, a_ri   : in  signed( DATA_WIDTH_G  - 1 downto 0 ) := (others => '0');
      a_ir, a_ii   : in  signed( DATA_WIDTH_G  - 1 downto 0 ) := (others => '0');
      c_re, c_im   : in  signed( DATA_WIDTH_G  - 1 downto 0 );
      y_re, y_im   : out signed( DATA_WIDTH_G  - 1 downto 0 );
      ac_rr, ac_ri : out signed( DATA_WIDTH_G  - 1 downto 0 );
      ac_ir, ac_ii : out signed( DATA_WIDTH_G  - 1 downto 0 )
   );
end entity ComplexMadd;

architecture Impl of ComplexMadd is

   constant C_W_C : natural := COEFF_WIDTH_C;
   constant D_W_C : natural := DATA_WIDTH_G;
   constant M_W_C : natural := 43;
   constant P_W_C : natural := 48;

   type RegType is record
      b1_rr, b1_ri, b2_rr, b2_ri, b2_ir, b2_ii : signed( C_W_C - 1 downto 0 );
      a1_rr, a1_ri, a2_rr, a2_ri, a2_ir, a2_ii : signed( D_W_C - 1 downto 0 );
      m_rr, m_ii, m_ri, m_ir                   : signed( M_W_C - 1 downto 0 );
      p_rr, p_ii, p_ri, p_ir                   : signed( P_W_C - 1 downto 0 );
   end record RegType;

   constant REG_INIT_C : RegType := (
      b1_rr => ( others => '0' ),
      b1_ri => ( others => '0' ),
      b2_rr => ( others => '0' ),
      b2_ri => ( others => '0' ),
      b2_ii => ( others => '0' ),
      b2_ir => ( others => '0' ),
      a1_rr => ( others => '0' ),
      a1_ri => ( others => '0' ),
      a2_rr => ( others => '0' ),
      a2_ri => ( others => '0' ),
      a2_ii => ( others => '0' ),
      a2_ir => ( others => '0' ),
      m_rr  => ( others => '0' ),
      m_ii  => ( others => '0' ),
      m_ri  => ( others => '0' ),
      m_ir  => ( others => '0' ),
      p_rr  => ( others => '0' ),
      p_ii  => ( others => '0' ),
      p_ri  => ( others => '0' ),
      p_ir  => ( others => '0' )
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   constant SHIFT_C : natural := 17;

   signal a_rr_i, a_ri_i, a_ir_i, a_ii_i : signed( DATA_WIDTH_G - 1 downto 0 );

begin

   y_re <= r.p_rr( SHIFT_C + D_W_C - 1 downto SHIFT_C );
   y_im <= r.p_ri( SHIFT_C + D_W_C - 1 downto SHIFT_C );

   GEN_CASC : if ( USE_CASC_G ) generate
      a_rr_i <= a_rr;
      a_ri_i <= a_ri;
      a_ir_i <= a_ir;
      a_ii_i <= a_ii;
   end generate;

   GEN_NO_CASC : if ( not USE_CASC_G ) generate
      a_rr_i <= a_re;
      a_ri_i <= a_re;
      a_ir_i <= a_im;
      a_ii_i <= a_im;
   end generate;

   ac_rr <= r.a1_rr;
   ac_ri <= r.a1_ri;
   ac_ii <= r.a2_ii;
   ac_ir <= r.a2_ir;

   P_COMB : process ( r, a_rr_i, a_ri_i, a_ir_i, a_ii_i, b_rr, b_ri, b_ir, b_ii, c_re, c_im ) is
      variable v : RegType;
      variable d_rr, d_ri, d_ii, d_ir : signed( D_W_C - 1 downto 0 );
      variable m_rr, m_ii, m_ri, m_ir : signed( M_W_C - 1 downto 0 );
   begin
      v := r;

      -- store coefficients; 2-deep pipeline ro real signal path, 1-deep pipeline
      -- for imag signal path
      v.b2_rr := r.b1_rr;
      v.b1_rr := b_rr;
      v.b2_ri := r.b1_ri;
      v.b1_ri := b_ri;
      v.b2_ii := b_ii;
      v.b2_ir := b_ir;

      -- 2-deep pipeline for 'a' registers (real signal path) and 'b' (rere, reim coeffs)
      v.a2_rr := r.a1_rr;
      v.a1_rr := a_rr_i;
      v.a2_ri := r.a1_ri;
      v.a1_ri := a_ri_i;
      -- 1-deep pipeline for 'a' registers (imag signal path) and 'b' (imre, imim coeffs)
      v.a2_ii := a_ii_i;
      v.a2_ir := a_ir_i;

      v.m_rr := r.a2_rr * r.b2_rr;
      v.m_ii := r.a2_ii * r.b2_ii;
      v.m_ri := r.a2_ri * r.b2_ri;
      v.m_ir := r.a2_ir * r.b2_ir;

      v.p_ii := resize( r.m_ii, P_W_C ) - shift_left( resize( c_re,   P_W_C ), SHIFT_C );
      v.p_rr := resize( r.m_rr, P_W_C ) - resize( r.p_ii, P_W_C);

      v.p_ir := resize( r.m_ir, P_W_C ) + shift_left( resize( c_im,   P_W_C ), SHIFT_C );
      v.p_ri := resize( r.m_ri, P_W_C ) + resize( r.p_ir, P_W_C );

      rin <= v;
   end process;

   P_SEQ : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( rst = '1' ) then
            r <= REG_INIT_C;
         else
            r <= rin;
         end if;
      end if;
   end process P_SEQ;

end architecture Impl;
