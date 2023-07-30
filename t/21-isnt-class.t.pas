program IsntClassTest;

{$mode objfpc}{$H+}{$J-}

uses TAP, Tester;

type
	TC1 = class(TObject);
	TC2 = class(TC1);
	TC3 = class(TObject);

var
	vParent: TC1;

begin
	vParent := TC1.Create;
	TAPTester.Hijack;
	TestIsnt(vParent, TC1, 'TC1 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 5, 'line count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 - TC1 ok', 'class 1 test ok');
	TestIs(TAPTester.Lines[2], '# expected: not object of class TC1', 'class 1 test ok');

	TAPTester.Hijack;
	TestIsnt(vParent, TC3, 'negative case 1 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - negative case 1 ok', 'negative class 1 test ok');

	DoneTesting;
end.

