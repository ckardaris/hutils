#!/usr/bin/env perl

open(FH, '>', sprintf($ARGV[1])) or die $!;
print FH ""; # empty the file

# Lines probabilities
my $prob_blank = 0.03;

# Line length
# [0, 10), [10, 40), [40, 80), [80, 160)
my @prob_length = (0.5, 0.8, 0.9, 0.99);

# Character probabilities
# escape, tab, print, extended, rest
my @prob_char = (0.05, 0.1, 0.45, 0.8);

for( my $i = 0 ; $i < $ARGV[0]; $i++ )
{
    if (rand() < 0.01)
    {
        print FH sprintf( "\n");
        next;
    }

    my $length;
    my $random = rand();
    if ($random < $prob_length[0])
    {
        $length = int rand (10);
    }
    elsif ($random < $prob_length[1])
    {
        $length = int rand (30) + 10;
    }
    elsif ($random < $prob_length[2])
    {
        $length = int rand (40) + 40;
    }
    elsif ($random < $prob_length[3])
    {
        $length = int rand (80) + 80;
    }
    else
    {
        $length = int rand (200) + 160;
    }

    for( my $j = 0 ; $j < $length; $j++ )
    {
        my $char;
        my $random = rand();
        if ($random < $prob_char[0])
        {
            $char = int rand (32);
        }
        elsif ($random < $prob_char[1])
        {
            $char = 9; # TAB
        }
        elsif ($random < $prob_char[2])
        {
            $char = int rand (96) + 32;
        }
        elsif ($random < $prob_char[3])
        {
            $char = int rand (128) + 128;
        }
        else
        {
            $char = int rand (1000000) + 256;
        }
        print FH sprintf( "%c", $char);
    }
    print FH sprintf( "\n");
}

close(FH);
