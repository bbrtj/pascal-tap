program PragmaTest;

uses TAP, Tester;

begin
	TAPTester.Hijack;
	Pragma('bail');
	Pragma('strict', False);
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'line count ok');
	TestIs(TAPTester.Lines[0], 'pragma +bail', 'pragma on ok');
	TestIs(TAPTester.Lines[1], 'pragma -strict', 'pragma off ok');
	DoneTesting;
end.

