#!/usr/bin/env perl

open(FH, '>', sprintf("test_chars.txt")) or die $!;
print FH ""; # empty the file

my $limit = 10000;

for( my $i = 0 ; $i < 128; $i++ )
{
    print FH sprintf( "%4c is %3d %4x\n", $i, $i ,$i );
}

for( my $i = 0 ; $i < $limit; $i++ )
{
    my $c = int rand(2048); #[0, 2^11)
    print FH sprintf( "%4c is %3d %4x\n", $c, $c ,$c );
}

for( my $i = 0 ; $i < $limit; $i++ )
{
    my $c = int rand(65536); #[0, 2 ^ 16)  
    print FH sprintf( "%4c is %3d %4x\n", $c, $c ,$c );
}

for( my $i = 0 ; $i < $limit; $i++ )
{
    my $c = int rand(16777216); #[0, 2 ^^ 24)  
    print FH sprintf( "%4c is %3d %4x\n", $c, $c ,$c );
}

for( my $i = 0 ; $i < $limit; $i++ )
{
    my $c = int rand(4294967296); #[0, 2 ^^ 32)  
    print FH sprintf( "%4c is %3d %4x\n", $c, $c ,$c );
}

for( my $i = 0 ; $i < $limit; $i++ )
{
    my $c = int rand(18446744073709551616); #[0, 2 ^^ 64)  
    print FH sprintf( "%4c is %3d %4x\n", $c, $c ,$c );
}
close(FH);
