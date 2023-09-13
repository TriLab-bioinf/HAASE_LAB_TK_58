#!/Users/lorenziha/opt/anaconda3/envs/snp_caller/bin/perl
use strict;

my $usage = "$0 -i <histogram file> -c <min coverage [def = 1]> -m <max coverage [def = 1e6]> -s <strand [any]>\n\n";
my %arg = @ARGV;
die $usage unless $arg{-i};

my $MINCOV = $arg{-c} || 1;
my $MAXCOV = $arg{-m} || 10000000;
die "ERROR, min coverage ($MINCOV) should be smaller or equal to max coverage ($MAXCOV )\n\n" if $MINCOV > $MAXCOV;

my $STRAND = $arg{-s} || 'any';

open (FHI, "<$arg{-i}") || die "ERROR, I cannot open $arg{-i}: $!\n\n";
while(<FHI>){
    chomp;
    if (m/^#/){
        print "$_\n";
    }
    my @x = split /\t/; #print "$x[0] $x[1] $x[2] ; cov=$x[3] ; strand=$x[5] ; STRAND=$STRAND\n";
    if ($x[5] eq $STRAND || $STRAND eq 'any'){
        print "$_\n" if $x[3] >= $MINCOV && $x[3] <= $MAXCOV;
    }
}
close FHI;
