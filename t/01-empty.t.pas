program EmptyTest;

uses TAP, Tester;

procedure RunTest();
begin
	DoneTesting;
end;

var
	vLine: String;
begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0', 'first line ok');
	DoneTesting;
end.

