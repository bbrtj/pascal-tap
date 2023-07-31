program LesserGreaterTest;

uses TAP, Tester;

procedure RunTestPositive();
begin
	TestLesser(1, 2);
	TestLesser(1.1, 1.2);
	TestLesserOrEqual(1, 1);
	TestGreater(2, 1);
	TestGreater(1.2, 1.1);
	TestGreaterOrEqual(2, 2);
	TestWithin(1.51526, 1.51532, 0.0001);
end;

procedure RunTestNegative();
begin
	TestLesser(2, 2);
	TestLesser(3, 2);
	TestLesser(1.2, 1.2);
	TestLesserOrEqual(2, 1);
	TestGreater(2, 2);
	TestGreater(2, 3);
	TestGreater(1.2, 1.2);
	TestGreaterOrEqual(1, 2);
	TestWithin(1.5126, 1.5137, 0.001);
end;

var
	vTotalTests, vPassedTests: UInt32;

begin
	TAPTester.Hijack;
	RunTestPositive;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 7, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag line count ok');

	TAPTester.Hijack;
	RunTestNegative;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 9, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 36, 'diag line count ok');
	TestIs(TAPTester.DiagLines[1], '# expected: less than 2', 'test 1 diag ok');
	TestIs(TAPTester.DiagLines[9], '# expected: less than 1.2', 'test 3 diag ok');
	TestIs(TAPTester.DiagLines[13], '# expected: at most 1', 'test 4 diag ok');
	TestIs(TAPTester.DiagLines[17], '# expected: more than 2', 'test 5 diag ok');
	TestIs(TAPTester.DiagLines[25], '# expected: more than 1.2', 'test 7 diag ok');
	TestIs(TAPTester.DiagLines[29], '# expected: at least 2', 'test 8 diag ok');
	TestIs(TAPTester.DiagLines[33], '# expected: 1.5137 +-0.001', 'test 9 diag ok');

	DoneTesting;
end.

