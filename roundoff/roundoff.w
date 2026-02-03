% CWEB Literate Program: Round-off Error Demonstration
% This program demonstrates floating-point round-off error accumulation

@* Introduction.
This program demonstrates the accumulation of round-off error in
floating-point arithmetic. We iterate a simple recurrence relation
that, mathematically, should keep $x = 1/3$ forever, but due to
the inability to represent $1/3$ exactly in binary floating-point,
errors accumulate and grow over time.

The mathematical identity is: if $x = 1/3$, then
$$(9x + 1) \cdot x - 1 = (9 \cdot {1\over 3} + 1) \cdot {1\over 3} - 1
= (3 + 1) \cdot {1\over 3} - 1 = {4\over 3} - 1 = {1\over 3}$$

However, since $1/3 = 0.333\ldots$ cannot be represented exactly
in binary floating-point, small errors compound with each iteration.

@* Program Structure.
The program consists of standard includes and a main function that
performs the iteration.

@c
@<Include files@>@;
@<Main program@>@;

@ @<Include files@>=
#include <stdio.h>

@* The Main Program.
We initialize $x = 1/3$ and iterate 900 times, printing the value
of $x$ every iteration to observe how round-off error accumulates.

@<Main program@>=
int main(void)
{
    @<Declare variables@>@;
    @<Initialize values@>@;
    @<Perform iteration loop@>@;
    return 0;
}

@ We need a counter and a floating-point variable for~$x$.
@<Declare variables@>=
    int kntr;
    double x;

@ Initialize $x$ to $1/3$ and the counter to zero.
@<Initialize values@>=
    x = 1.0 / 3.0;
    kntr = 0;
    printf("Round-off Error Demonstration\n");
    printf("Mathematical value should remain 1/3 = 0.333...\n\n");
    printf("Iteration      x value\n");
    printf("---------  ----------------\n");

@ The main iteration loop. We apply the recurrence $x = (9x + 1) \cdot x - 1$
and print $x$ every iteration to observe the error growth.
@<Perform iteration loop@>=
    do {
        kntr = kntr + 1;
        x = (9.0 * x + 1.0) * x - 1.0;
        printf("%9d  %16.12f\n", kntr, x);
    } while (kntr < 900);

@* Index.
