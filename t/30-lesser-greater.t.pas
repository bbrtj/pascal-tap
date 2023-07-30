program LesserGreaterTest;

uses TAP, Tester;

procedure RunTestPositive();
begin
	TestLesser(1, 2, '');
	TestLesser(1.1, 1.2, '');
	TestLesserOrEqual(1, 1, '');
	TestGreater(2, 1, '');
	TestGreater(1.2, 1.1, '');
	TestGreaterOrEqual(2, 2, '');
end;

procedure RunTestNegative();
begin
	TestLesser(2, 2, '');
	TestLesser(3, 2, '');
	TestLesser(1.2, 1.2, '');
	TestLesserOrEqual(2, 1, '');
	TestGreater(2, 2, '');
	TestGreater(2, 3, '');
	TestGreater(1.2, 1.2, '');
	TestGreaterOrEqual(1, 2, '');
end;

var
	vTotalTests, vPassedTests: UInt32;

begin
	TAPTester.Hijack;
	RunTestPositive;
	vTotalTests := TAPGlobalContext.TestsExecuted;
	vPassedTests := TAPGlobalContext.TestsPassed;
	TAPTester.Release;

	TestIs(vTotalTests, 6, 'test count ok');
	TestIs(vPassedTests, 6, 'passed test count ok');
	TestIs(TAPTester.Lines.Count, 6, 'line count ok');

	TAPTester.Hijack;
	RunTestNegative;
	vTotalTests := TAPGlobalContext.TestsExecuted;
	vPassedTests := TAPGlobalContext.TestsPassed;
	TAPTester.Release;

	TestIs(vTotalTests, 8, 'test count ok');
	TestIs(vPassedTests, 0, 'passed test count ok');
	TestIs(TAPTester.Lines.Count, 40, 'line count ok');
	TestIs(TAPTester.Lines[2], '# expected: less than 2', 'test 1 diag ok');
	TestIs(TAPTester.Lines[12], '# expected: less than 1.2', 'test 3 diag ok');
	TestIs(TAPTester.Lines[17], '# expected: at most 1', 'test 4 diag ok');
	TestIs(TAPTester.Lines[22], '# expected: more than 2', 'test 5 diag ok');
	TestIs(TAPTester.Lines[32], '# expected: more than 1.2', 'test 7 diag ok');
	TestIs(TAPTester.Lines[37], '# expected: at least 2', 'test 8 diag ok');

	DoneTesting;
end.

