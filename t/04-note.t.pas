program NoteTest;

uses TAP, Tester;

procedure RunTest();
begin
	Note('this is a test');
	Diag('this is a diag test');
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '# this is a test', 'note ok');

	TestIs(TAPTester.DiagLines.Count, 1, 'diag line count ok');
	TestIs(TAPTester.DiagLines[0], '# this is a diag test', 'diag ok');
	DoneTesting;
end.

