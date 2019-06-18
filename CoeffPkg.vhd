library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
package CoeffPkg is
      constant COEFF_WIDTH_C : natural := 18;
      type CoeffArray is array (natural range <>) of signed(COEFF_WIDTH_C - 1 downto 0);
      function to_Coeff(x : integer) return signed;
end package CoeffPkg;

package body CoeffPkg is
   function to_Coeff(x : integer) return signed is
   begin
      return to_signed( x, COEFF_WIDTH_C );
   end function to_Coeff;
end package body CoeffPkg;


