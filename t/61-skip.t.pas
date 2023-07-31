program SkipTest;

uses TAP, Tester;

procedure RunTestSkipAll();
begin
	SkipAll('all skipped');
	Plan(5);
	TestOk(False);
	Fatal;
	TestFail;
	SubtestBegin('??');
	Skip;
	TestPass;
	SubtestEnd;
	TestFail;
	Diag('test');
	Note('test');
	Pragma('test');
	BailOut('test');
	DoneTesting;
end;

procedure RunTestSkipOne();
begin
	Skip;
	Fatal; TestFail;
	TestFail;
end;

procedure RunTestTodoOne();
begin
	Todo;
	TestFail;
	TestPass;
end;

begin
	TAPTester.Hijack;
	RunTestSkipAll;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], '1..0 # SKIP all skipped', 'lines ok');

	TAPTester.Hijack;
	RunTestSkipOne;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 4, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 # SKIP ', 'skipped line ok');
	TestIs(TAPTester.Lines[1], 'not ok 2', 'second line ok');

	TAPTester.Hijack;
	RunTestTodoOne;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'lines count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag lines count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 # TODO ', 'todo line ok');
	TestIs(TAPTester.Lines[1], 'ok 2', 'second line ok');

	DoneTesting;
end.

