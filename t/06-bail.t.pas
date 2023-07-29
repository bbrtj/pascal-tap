program BailTest;

uses TAP, Tester;

begin
	TAPTester.Hijack;
	BailOut('testing the bailout');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], 'Bail out! testing the bailout', 'bailout ok');
	TestIs(TAPTester.Exited, True, 'bailout procedure called');
	DoneTesting;
end.

