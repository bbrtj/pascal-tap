program PassFailTest;

uses TAP, Tester;

procedure RunTest();
begin
	TestPass('test passed');
	TestFail('test failed');
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 6, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - test passed', 'pass ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - test failed', 'fail ok');
	DoneTesting;
end.

