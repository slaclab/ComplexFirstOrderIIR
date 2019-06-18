GHDL=/opt/ghdl/v0.36/bin/ghdl
test: 
	$(GHDL) -a CoeffPkg.vhd
	$(GHDL) -a ComplexMadd.vhd
	$(GHDL) -a FirstOrderComplex.vhd
	$(GHDL) -a FirstOrderComplex_tb.vhd
	$(GHDL) -r FirstOrderComplex_tb --wave=dump.ghw
