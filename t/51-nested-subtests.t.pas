program NestedSubtestsTest;

uses TAP, Tester;

procedure RunTest();
begin
	SubtestBegin('level 1');
		SubtestBegin('level 2');
			SubtestBegin('level 3');
				TestPass;
			SubtestEnd;
		SubtestEnd;
	SubtestEnd;
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 10, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag line count ok');
	TestIs(TAPTester.Lines[0], '# Subtest: level 1', 'level 1 ok');
	TestIs(TAPTester.Lines[1], '    # Subtest: level 2', 'level 2 ok');
	TestIs(TAPTester.Lines[2], '        # Subtest: level 3', 'level 3 ok');
	TestIs(TAPTester.Lines[3], '            ok 1', 'pass ok');
	TestIs(TAPTester.Lines[4], '            1..1', 'level 3 plan ok');
	TestIs(TAPTester.Lines[5], '        ok 1 - level 3', 'level 3 testpoint ok');
	TestIs(TAPTester.Lines[6], '        1..1', 'level 3 plan ok');
	TestIs(TAPTester.Lines[7], '    ok 1 - level 2', 'level 2 testpoint ok');
	TestIs(TAPTester.Lines[8], '    1..1', 'level 2 plan ok');
	TestIs(TAPTester.Lines[9], 'ok 1 - level 1', 'level 1 testpoint ok');

	DoneTesting;
end.

