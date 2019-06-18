library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.CoeffPkg.all;

entity ComplexMadd_tb is
end entity Complexmadd_tb;

architecture Impl of ComplexMadd_tb is
   constant DATA_WIDTH_G : natural := 25;

   signal clk : std_logic := '0';
   signal run : boolean   := true;
   signal cnt : integer   := 0;
   signal rst : std_logic := '1';

   signal a_re: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal a_im: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal b   : CoeffArray(0 to 1)                := ( others => (others =>'0' ) );
   signal c_re: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal c_im: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal y_re: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );
   signal y_im: signed(DATA_WIDTH_G - 1 downto 0) := ( others => '0' );

   function to_Dat(x : integer) return signed is
   begin
      return to_signed(x, DATA_WIDTH_G);
   end function to_Dat;

   constant minus_one : signed := "10" & x"0000";

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

   P_CNT : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         case cnt is
            when 10    =>
               rst  <= '0';
            when 11    =>
               a_im <= to_Dat( 1234 );
               b(0) <= minus_one;
            when 12    =>
               b(0) <= to_Coeff( 0 );
               b(1) <= minus_one;
            when 13    =>
               a_im <= to_Dat( 0 );
               b(1) <= to_Coeff( 0 );
            when 18    =>
               c_re <= to_Dat( 5678 );
               c_im <= to_Dat(-3210 );
            when 19    =>
               c_re <= to_Dat( 0 );
               c_im <= to_Dat( 0 );
            when 25    =>
               a_re <= to_Dat( 1234 );
               b(0) <= minus_one;
            when 26    =>
               b(0) <= to_Coeff( 0 );
               b(1) <= minus_one;
            when 27    =>
               a_re <= to_Dat( 0 );
               b(1) <= to_Coeff( 0 );
            when 100   =>
               run  <= false;
            when others => 
         end case;

         case cnt is
            when 16 => assert y_im = to_Dat( -1234 ) and y_re = to_Dat(0) severity failure;
            when 17 => assert y_re = to_Dat(  1234 ) and y_im = to_Dat(0) severity failure;
            when 21 => assert y_re = to_Dat( 5678 ) and y_im = to_Dat( -3210 ) severity failure;
            when 30 => assert y_re = to_Dat( -1234 ) and y_im = to_Dat(0) severity failure;
            when 31 => assert y_im = to_Dat( -1234 ) and y_re = to_Dat(0) severity failure;
            when others => assert y_re = to_Dat(0) and y_im = to_Dat(0) severity failure;
         end case;
         cnt <= cnt + 1;
      end if;
   end process P_CNT;

   U_DUT : entity work.ComplexMadd
      port map (
         clk           => clk,
         rst           => rst,
         a_re          => a_re,
         a_im          => a_im,
         b_re          => b(0),
         b_im          => b(1),
         c_re          => c_re,
         c_im          => c_im,
         y_re          => y_re,
         y_im          => y_im
      );

end architecture Impl;
