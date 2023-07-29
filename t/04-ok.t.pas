program OkTest;

uses TAP, Tester;

procedure RunTest();
begin
	TestOk(True, 'test 1');
	TestOk(False, 'test 2');
	DoneTesting;
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - test 1', 'first test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - test 2', 'second test ok');
	TestIs(TAPTester.Lines[2], '1..2', 'plan ok');
	DoneTesting;
end.

