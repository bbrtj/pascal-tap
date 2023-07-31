{
	This is an example of incorrect test code, which tries to plan twice.
	The program will produce the bailout TAP output.

	Bailout behavior can be controlled with BailoutBehavior of the global TAPGlobalContext.

	build with: make examples
	run with: prove build/bail.t
}
program Bail;

{$mode objfpc}{$H+}{$J-}

uses TAP;

begin
	// Uncomment to get an exception instead of straight halting of the
	// program. The exception will be of type EBailout.
	// TAPGlobalContext.BailoutBehavior := btException;

	Plan(1);
	Plan(1);
	TestPass('always passing, but never reached');

	DoneTesting;
end.

