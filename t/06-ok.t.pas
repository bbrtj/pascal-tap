program OkTest;

uses TAP, Tester;

procedure RunTest();
begin
	TestOk(True, 'test 1');
	TestOk(True);
	TestOk(False, 'test 2');
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag line count ok');

	TestIs(TAPTester.Lines[0], 'ok 1 - test 1', 'first test ok');
	TestIs(TAPTester.Lines[1], 'ok 2', 'second test ok');
	TestIs(TAPTester.Lines[2], 'not ok 3 - test 2', 'third test ok');

	TestIs(TAPTester.DiagLines[0], '# Failed test ''test 2''', 'diag ok');

	DoneTesting;
end.

