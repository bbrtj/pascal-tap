program PlanTest;

uses TAP, Tester;

begin
	TAPTester.Hijack;
	Plan(5);
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..5', 'plan ok');

	TAPTester.Hijack;
	Plan(stSkip, 'skipped for now');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0 # SKIP skipped for now', 'skip ok');

	TAPTester.Hijack;
	Plan(stTodo, 'not finished');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0 # SKIP TODO not finished', 'todo ok');

	TAPTester.Hijack;
	DoneTesting;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0', 'done testing ok');

	DoneTesting;
end.

