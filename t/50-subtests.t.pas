program SubtestsTest;

uses TAP, Tester;

procedure RunTest();
begin
	SubtestBegin('this is a subtest');
	TestOk(True, 'success');
	TestOk(True, 'another success');
	SubtestEnd;
	DoneTesting;
end;

procedure RunTestWithFailure();
begin
	SubtestBegin('this is a subtest');
	TestOk(False, 'failure');
	SubtestEnd;
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 6, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag line count ok');
	TestIs(TAPTester.Lines[0], '# Subtest: this is a subtest', 'subtest comment ok');
	TestIs(TAPTester.Lines[1], '    ok 1 - success', 'subtest test ok');
	TestIs(TAPTester.Lines[2], '    ok 2 - another success', 'subtest second test ok');
	TestIs(TAPTester.Lines[3], '    1..2', 'subtest plan ok');
	TestIs(TAPTester.Lines[4], 'ok 1 - this is a subtest', 'subtest testpoint ok');
	TestIs(TAPTester.Lines[5], '1..1', 'global plan ok');

	TAPTester.Hijack;
	RunTestWithFailure;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 4, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 8, 'diag line count ok');
	TestIs(TAPTester.Lines[0], '# Subtest: this is a subtest', 'subtest comment ok');
	TestIs(TAPTester.Lines[1], '    not ok 1 - failure', 'subtest test ok');
	TestIs(TAPTester.Lines[2], '    1..1', 'subtest plan ok');
	TestIs(TAPTester.Lines[3], 'not ok 1 - this is a subtest', 'subtest testpoint ok');

	TestIs(TAPTester.DiagLines[0], '    # Failed test ''failure''', 'subtest test comment ok');
	TestIs(TAPTester.DiagLines[1], '    # expected: True', 'subtest test comment ok');
	TestIs(TAPTester.DiagLines[2], '    #      got: False', 'subtest test comment ok');
	TestIs(TAPTester.DiagLines[3], '    ', 'subtest test comment ok');
	TestIs(TAPTester.DiagLines[4], '# Failed test ''this is a subtest''', 'subtest comment ok');
	TestIs(TAPTester.DiagLines[5], '# expected: pass', 'subtest comment ok');
	TestIs(TAPTester.DiagLines[6], '#      got: fail', 'subtest comment ok');
	TestIs(TAPTester.DiagLines[7], '', 'subtest comment ok');

	DoneTesting;
end.

