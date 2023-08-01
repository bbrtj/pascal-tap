{
	Test subtests behavior.
}
unit SubtestsTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, TAPCore, Tester;

type
	TSubtestsSuite = class(TTAPSuite)
		constructor Create(); override;

		procedure SubtestTest();
		procedure NestedSubtestTest();
	end;

implementation

constructor TSubtestsSuite.Create();
begin
	inherited;
	Scenario(@self.SubtestTest, 'Test subtests');
	Scenario(@self.NestedSubtestTest, 'Test nested subtests');
end;

procedure TSubtestsSuite.SubtestTest();
begin
	TAPTester.Hijack;
	SubtestBegin('this is a subtest');
	TestOk(True, 'success');
	TestOk(True, 'another success');
	SubtestEnd;
	DoneTesting;
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 6, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag line count ok');
	TestIs(TAPTester.Lines[0], '# Subtest: this is a subtest', 'subtest comment ok');
	TestIs(TAPTester.Lines[1], '    ok 1 - success', 'subtest test ok');
	TestIs(TAPTester.Lines[2], '    ok 2 - another success', 'subtest second test ok');
	TestIs(TAPTester.Lines[3], '    1..2', 'subtest plan ok');
	TestIs(TAPTester.Lines[4], 'ok 1 - this is a subtest', 'subtest testpoint ok');
	TestIs(TAPTester.Lines[5], '1..1', 'global plan ok');

	TAPTester.Hijack;
	SubtestBegin('this is a subtest');
	TestOk(False, 'failure');
	SubtestEnd;
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 4, 'line count ok');
	Fatal; TestIs(TAPTester.DiagLines.Count, 8, 'diag line count ok');
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
end;

procedure TSubtestsSuite.NestedSubtestTest();
begin
	TAPTester.Hijack;
	SubtestBegin('level 1');
		SubtestBegin('level 2');
			SubtestBegin('level 3');
				TestPass;
			SubtestEnd;
		SubtestEnd;
	SubtestEnd;
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 10, 'line count ok');
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
end;

end.

