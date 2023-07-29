program EmptyTest;

uses TAP, Tester;

procedure RunTest();
begin
	DoneTesting;
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '1..0', 'plan ok');
	DoneTesting;
end.

