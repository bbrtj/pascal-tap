program NoteTest;

uses TAP, Tester;

procedure RunTest();
begin
	Note('this is a test');
end;

begin
	TAPTester.Hijack;
	RunTest;
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], '# this is a test', 'note ok');
	DoneTesting;
end.

