program IsntTest;

uses TAP, Tester;

procedure RunTestIntegers();
begin
	TestIsnt(5, 4, 'integers 0');
	TestIsnt(5, 5, 'integers 1');
end;

procedure RunTestStrings();
begin
	TestIsnt('', '?', 'strings 0');
	TestIsnt('abc', 'abc', 'strings 1');
end;

procedure RunTestBooleans();
begin
	TestIsnt(True, False, 'booleans 0');
	TestIsnt(False, False, 'booleans 1');
end;

begin
	TAPTester.Hijack;
	RunTestIntegers;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - integers 0', 'integers 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - integers 1', 'integers 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not 5', 'integers 1 test diag ok');

	TAPTester.Hijack;
	RunTestStrings;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - strings 0', 'strings 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - strings 1', 'strings 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not ''abc''', 'strings 1 test diag ok');

	TAPTester.Hijack;
	RunTestBooleans;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - booleans 0', 'booleans 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - booleans 1', 'booleans 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not False', 'booleans 1 test diag ok');

	DoneTesting;
end.

