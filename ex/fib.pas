{
	This program tests a Fibonacci number generator with help of subtests

	build with: make examples
	run with: prove build/fib.t
}
program FibonacciTest;

{$mode objfpc}{$H+}{$J-}

uses TAP;

type
	TFibonacciHistory = Array [0 .. 1] of UInt32;

var
	vLastFibonacci: TFibonacciHistory = (0, 1);

function GetNextFibonacciNumber(): UInt32;
begin
	result := vLastFibonacci[0] + vLastFibonacci[1];
	vLastFibonacci[0] := vLastFibonacci[1];
	vLastFibonacci[1] := result;
end;

begin
	// Subtests are useful to subdivide your test
	SubtestBegin('Should return first 5 Fibonacci numbers');
	TestIs(GetNextFibonacciNumber(), 1, 'Fibonacci number 1 ok');
	TestIs(GetNextFibonacciNumber(), 2, 'Fibonacci number 2 ok');
	TestIs(GetNextFibonacciNumber(), 3, 'Fibonacci number 3 ok');
	TestIs(GetNextFibonacciNumber(), 5, 'Fibonacci number 4 ok');
	TestIs(GetNextFibonacciNumber(), 8, 'Fibonacci number 5 ok');
	SubtestEnd;

	// You can mark subtest as skipped, which will not produce any
	// output for its tests (even if implemented)
	SubtestBegin('Should return the sixth Fibonacci number');
	Skip(stSkipAll, 'procrastinating...');
	TestIs(GetNextFibonacciNumber(), 12, 'did I get this right?');
	SubtestEnd;

	// you have to run Plan or DoneTesting in your test program
	DoneTesting;
end.

