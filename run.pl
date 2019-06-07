#!usr/bin/perl
use warnings; use strict;
use LWP::Simple;

my $now_time = localtime;
my $PATH = 'C:\Users\KuiliangLin\Desktop\test'.
			'\rtl\*';

			
print ">>> TOP => Delet .out/.vvp/.vcd!\n";
system "del *.out";#for windows
system "del *.vvp";#for windows
system "del *.vcd";#for windows
#system "rm -fr test_0_$stockNO.txt";#for linux 

print ">>> TOP => Run iverilog! $now_time \n";
system "iverilog -o out.vvp $PATH";

print ">>> TOP => Run vvp! $now_time \n";
system "vvp out.vvp";

print ">>> TOP => Run gtkwave! $now_time \n";
#system "gtkwave *.vcd";

print ">>> TOP => All works have been done! \n\n";
