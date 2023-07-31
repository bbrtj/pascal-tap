program FatalTest;

{$mode objfpc}{$H+}{$J-}

uses TAP, TAPCore, Tester;

function RunTestOne(): Boolean;
begin
	result := False;

	try
		Fatal; TestOk(False);
	except
		on EBailout do result := True;
	end;
end;

function RunTestTwo(): Boolean;
begin
	result := False;

	try
		Fatal; TestOk(True);
		TestOk(False);
	except
		on EBailout do result := True;
	end;
end;

function RunTestThree(): Boolean;
begin
	result := False;

	try
		FatalAll;
		TestOk(True);
		TestOk(False);
	except
		on EBailout do result := True;
	end;
end;

function RunTestFour(): Boolean;
begin
	result := False;

	try
		FatalAll;
		TestOk(True);
		FatalAll(False);
		TestOk(False);
	except
		on EBailout do result := True;
	end;
end;

function RunTestFive(): Boolean;
begin
	result := False;

	try
		FatalAll;
		TestPass;
		Fatal; TestPass;
		TestFail;
	except
		on EBailout do result := True;
	end;
end;

var
	vBailedOut: Boolean;

begin
	TAPTester.Hijack;
	vBailedOut := RunTestOne;
	TAPTester.Release;

	TestOk(vBailedOut, 'bailed out correctly');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag produced ok');

	TAPTester.Hijack;
	vBailedOut := RunTestTwo;
	TAPTester.Release;

	TestOk(not vBailedOut, 'not bailed out correctly');

	TAPTester.Hijack;
	vBailedOut := RunTestThree;
	TAPTester.Release;

	TestOk(vBailedOut, 'bailed out correctly');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag produced ok');

	TAPTester.Hijack;
	vBailedOut := RunTestFour;
	TAPTester.Release;

	TestOk(not vBailedOut, 'not bailed out correctly');

	TAPTester.Hijack;
	vBailedOut := RunTestFive;
	TAPTester.Release;

	TestOk(vBailedOut, 'bailed out correctly');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag produced ok');

	DoneTesting;
end.

