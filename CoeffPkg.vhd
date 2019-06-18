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
use     ieee.numeric_std.all;
use     ieee.math_complex.all;

package CoeffPkg is
      constant COEFF_WIDTH_C : natural := 18;
      type CoeffArray is array (natural range <>) of signed(COEFF_WIDTH_C - 1 downto 0);
      function to_Coeff(x : integer) return signed;
      function to_Coeff( x : real; scl : real := 2.0**17 ) return signed;

      function to_CoeffArray(z0, p0: COMPLEX; scl : real := 2.0**17) return CoeffArray;
end package CoeffPkg;

package body CoeffPkg is
   function to_Coeff(x : integer) return signed is
   begin
      return to_signed( x, COEFF_WIDTH_C );
   end function to_Coeff;

   function to_Coeff( x : real; scl : real := 2.0**17 ) return signed is
   begin
      return to_Coeff( integer( x * scl ) );
   end function to_Coeff;

   function to_CoeffArray(z0, p0: COMPLEX; scl : real := 2.0**17) return CoeffArray is
      variable p4  : COMPLEX;
      variable tmp : COMPLEX;
      variable y   : CoeffArray( 0 to 9 );
   begin
      p4  := p0 * p0;
      p4  := p4 * p4;
      -- y(10)/y(11) is the IIR coefficient
      y(8) := to_Coeff( p4.re, scl );
      y(9) := to_Coeff( p4.im, scl );
      tmp := (p0 - z0);
      y(6) := to_Coeff( tmp.re, scl );
      y(7) := to_Coeff( tmp.im, scl );
      tmp := tmp * p0;
      y(4) := to_Coeff( tmp.re, scl );
      y(5) := to_Coeff( tmp.im, scl );
      tmp := tmp * p0;
      y(2) := to_Coeff( tmp.re, scl );
      y(3) := to_Coeff( tmp.im, scl );
      tmp := tmp * p0 - p4;
      y(0) := to_Coeff( tmp.re, scl );
      y(1) := to_Coeff( tmp.im, scl );
      return y; 
   end function to_CoeffArray;
end package body CoeffPkg;


