{
	Test for basic keywords used in testing. First test to execute, as these
	are essential for every test.
}
unit BasicTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, TAPCore, Tester;

type
	TBasicSuite = class(TTAPSuite, ITAPSuiteEssential)
		constructor Create(); override;

		procedure PlanTest();
		procedure BailTest();
		procedure PragmaTest();
		procedure CommentTest();
		procedure PassFailTest();
		procedure OkTest();
	end;

	TSkippedSuite = class(TTAPSuite, ITAPSuiteSkip)
		constructor Create();

		procedure FailMiserably();
	end;

implementation

constructor TBasicSuite.Create();
begin
	inherited;
	Scenario(@self.PlanTest, 'Plan tests');
	Scenario(@self.BailTest, 'Bail tests');
	Scenario(@self.PragmaTest, 'Pragma tests');
	Scenario(@self.CommentTest, 'Comment tests');
	Scenario(@self.PassFailTest, 'Pass/fail tests');
	Scenario(@self.OkTest, 'Ok tests');
end;

procedure TBasicSuite.PlanTest();
begin
	TAPTester.Hijack;
	Plan(5);
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..5', 'plan ok');

	TAPTester.Hijack;
	SkipAll('skipped for now');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0 # SKIP skipped for now', 'skip ok');

	TAPTester.Hijack;
	DoneTesting;
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0', 'done testing ok');
end;

procedure TBasicSuite.BailTest();
var
	vBailedOut: Boolean;
begin
	vBailedOut := False;

	TAPTester.Hijack;

	try
		BailOut('testing the bailout');
	except
		on EBailout do vBailedOut := True;
	end;

	TAPTester.Release;

	TestIs(vBailedOut, True, 'bailout procedure called');
	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], 'Bail out! testing the bailout', 'bailout ok');
end;

procedure TBasicSuite.PragmaTest();
begin
	TAPTester.Hijack;
	Pragma('bail');
	Pragma('strict', False);
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 2, 'line count ok');
	TestIs(TAPTester.Lines[0], 'pragma +bail', 'pragma on ok');
	TestIs(TAPTester.Lines[1], 'pragma -strict', 'pragma off ok');
end;

procedure TBasicSuite.CommentTest();
begin
	TAPTester.Hijack;
	Note('this is a test');
	Diag('this is a diag test');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '# this is a test', 'note ok');

	Fatal; TestIs(TAPTester.DiagLines.Count, 1, 'diag line count ok');
	TestIs(TAPTester.DiagLines[0], '# this is a diag test', 'diag ok');
end;

procedure TBasicSuite.PassFailTest();
begin
	TAPTester.Hijack;
	TestPass('test passed');
	TestFail('test failed');
	TestFail('test failed', '!!!');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	Fatal; TestIs(TAPTester.DiagLines.Count, 8, 'diag lines count ok');

	TestIs(TAPTester.Lines[0], 'ok 1 - test passed', 'pass ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - test failed', 'fail ok');

	TestIs(TAPTester.DiagLines[0], '# Failed test ''test failed''', 'diag ok');
	TestIs(TAPTester.DiagLines[1], '# expected: (nothing)', 'diag ok');
	TestIs(TAPTester.DiagLines[5], '# expected: !!!', 'diag ok');
end;

procedure TBasicSuite.OkTest();
begin
	TAPTester.Hijack;
	TestOk(True, 'test 1');
	TestOk(True);
	TestOk(False, 'test 2');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	Fatal; TestIs(TAPTester.DiagLines.Count, 4, 'diag line count ok');

	TestIs(TAPTester.Lines[0], 'ok 1 - test 1', 'first test ok');
	TestIs(TAPTester.Lines[1], 'ok 2', 'second test ok');
	TestIs(TAPTester.Lines[2], 'not ok 3 - test 2', 'third test ok');

	TestIs(TAPTester.DiagLines[0], '# Failed test ''test 2''', 'diag ok');
end;

constructor TSkippedSuite.Create();
begin
	inherited;
	Scenario(@self.FailMiserably, 'Would normally fail, but test is skipped');
end;

procedure TSkippedSuite.FailMiserably();
begin
	TestFail('I failed');
end;

end.

