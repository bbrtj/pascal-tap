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
	TestIs(TAPTester.Lines[0], '# Subtest: this is a subtest', 'subtest comment ok');
	TestIs(TAPTester.Lines[1], '    ok 1 - success', 'subtest test ok');
	TestIs(TAPTester.Lines[2], '    ok 2 - another success', 'subtest second test ok');
	TestIs(TAPTester.Lines[3], '    1..2', 'subtest plan ok');
	TestIs(TAPTester.Lines[4], 'ok 1 - this is a subtest', 'subtest testpoint ok');
	TestIs(TAPTester.Lines[5], '1..1', 'global plan ok');

	TAPTester.Hijack;
	RunTestWithFailure;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 12, 'line count ok');
	TestIs(TAPTester.Lines[0], '# Subtest: this is a subtest', 'subtest comment ok');
	TestIs(TAPTester.Lines[1], '    not ok 1 - failure', 'subtest test ok');
	TestIs(TAPTester.Lines[2], '    # Failed test ''failure''', 'subtest test comment ok');
	TestIs(TAPTester.Lines[3], '    # expected: True', 'subtest test comment ok');
	TestIs(TAPTester.Lines[4], '    #      got: False', 'subtest test comment ok');
	TestIs(TAPTester.Lines[5], '    ', 'subtest test comment ok');
	TestIs(TAPTester.Lines[6], '    1..1', 'subtest plan ok');
	TestIs(TAPTester.Lines[7], 'not ok 1 - this is a subtest', 'subtest testpoint ok');
	TestIs(TAPTester.Lines[8], '# Failed test ''this is a subtest''', 'subtest comment ok');
	TestIs(TAPTester.Lines[9], '# expected: pass', 'subtest comment ok');
	TestIs(TAPTester.Lines[10], '#      got: fail', 'subtest comment ok');
	TestIs(TAPTester.Lines[11], '', 'subtest comment ok');

	DoneTesting;
end.

