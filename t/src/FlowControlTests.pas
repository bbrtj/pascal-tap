{
	Test flow control behavior (such as Fatal and Skip).
}
unit FlowControlTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, TAPCore, Tester;

type
	TFlowControlSuite = class(TTAPSuite)
		constructor Create(); override;

		procedure FatalTest();
		procedure SkipTest();
	end;

implementation

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

procedure RunTestSkipAll();
begin
	SkipAll('all skipped');
	Plan(5);
	TestOk(False);
	Fatal;
	TestFail;
	SubtestBegin('??');
	Skip;
	TestPass;
	SubtestEnd;
	TestFail;
	Diag('test');
	Note('test');
	Pragma('test');
	BailOut('test');
	DoneTesting;
end;

procedure RunTestSkipOne();
begin
	Skip;
	Fatal; TestFail;
	TestFail;
end;

procedure RunTestTodoOne();
begin
	Todo;
	TestFail;
	TestPass;
end;

constructor TFlowControlSuite.Create();
begin
	inherited;
	Scenario(@self.FatalTest, 'Fatal tests');
	Scenario(@self.SkipTest, 'Skip tests');
end;

procedure TFlowControlSuite.FatalTest();
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
end;

procedure TFlowControlSuite.SkipTest();
begin
	TAPTester.Hijack;
	RunTestSkipAll;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], '1..0 # SKIP all skipped', 'lines ok');

	TAPTester.Hijack;
	RunTestSkipOne;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 # SKIP ', 'skipped line ok');
	TestIs(TAPTester.Lines[1], 'not ok 2', 'second line ok');

	TAPTester.Hijack;
	RunTestTodoOne;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 # TODO ', 'todo line ok');
	TestIs(TAPTester.Lines[1], 'ok 2', 'second line ok');
end;

begin
	TAPSuites.Add(TFlowControlSuite.Create);
end.

