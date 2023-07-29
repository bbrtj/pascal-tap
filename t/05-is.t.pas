program IsTest;

uses TAP, Tester;

procedure RunTestIntegers();
begin
	TestIs(5, 5, 'integers 1');
	TestIs(5, 4, 'integers 0');
end;

procedure RunTestStrings();
begin
	TestIs('abc', 'abc', 'strings 1');
	TestIs('??', '?', 'strings 0');
end;

procedure RunTestBooleans();
begin
	TestIs(False, False, 'booleans 1');
	TestIs(True, False, 'booleans 0');
end;

begin
	TAPTester.Hijack;
	RunTestIntegers;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - integers 1', 'integers 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - integers 0', 'integers 0 test ok');
	TestOk(TAPTester.Lines.Count > 2, 'lines describing the failure ok');

	TAPTester.Hijack;
	RunTestStrings;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - strings 1', 'strings 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - strings 0', 'strings 0 test ok');
	TestOk(TAPTester.Lines.Count > 2, 'lines describing the failure ok');

	TAPTester.Hijack;
	RunTestBooleans;
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - booleans 1', 'booleans 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - booleans 0', 'booleans 0 test ok');
	TestOk(TAPTester.Lines.Count > 2, 'lines describing the failure ok');

	DoneTesting;
end.

