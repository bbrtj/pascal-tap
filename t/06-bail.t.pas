program BailTest;

{$mode objfpc}{$H+}{$J-}

uses TAP, Tester;

var
	vBailedOut: Boolean = False;
begin
	TAPTester.Hijack;

	try
		BailOut('testing the bailout');
	except
		on EBailout do vBailedOut := True;
	end;

	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], 'Bail out! testing the bailout', 'bailout ok');
	TestIs(vBailedOut, True, 'bailout procedure called');
	DoneTesting;
end.

