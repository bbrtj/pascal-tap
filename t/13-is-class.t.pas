program IsClassTest;

{$mode objfpc}{$H+}{$J-}

uses TAP, Tester;

type
	TC1 = class(TObject);
	TC2 = class(TC1);
	TC3 = class(TObject);

var
	vParent: TC1;
	vChild: TC2;
	vCousin: TC3;

begin
	TAPTester.Hijack;
	vParent := TC1.Create;
	vChild := TC2.Create;
	vCousin := TC3.Create;

	TestIs(vParent, TC1, 'TC1 ok');
	TestIs(vChild, TC2, 'TC2 ok');
	TestIs(vCousin, TC3, 'TC3 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - TC1 ok', 'class 1 test ok');
	TestIs(TAPTester.Lines[1], 'ok 2 - TC2 ok', 'class 2 test ok');
	TestIs(TAPTester.Lines[2], 'ok 3 - TC3 ok', 'class 3 test ok');

	TAPTester.Hijack;
	vParent.Free;
	vParent := TC2.Create;

	TestIs(vParent, TC1, 'mixed case 1 ok');
	TestIs(vChild, TC1, 'mixed case 2 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 2, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - mixed case 1 ok', 'mixed class 1 test ok');
	TestIs(TAPTester.Lines[1], 'ok 2 - mixed case 2 ok', 'mixed class 2 test ok');

	TAPTester.Hijack;
	TestIs(vChild, TC3, 'negative case 1 ok');
	TestIs(vCousin, TC1, 'negative case 2 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 10, 'line count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 - negative case 1 ok', 'negative class 1 test ok');
	TestIs(TAPTester.Lines[1], '# Failed test ''negative case 1 ok''', 'negative class 1 test name ok');
	TestIs(TAPTester.Lines[2], '# expected: object of class TC3', 'negative class 1 test diag ok');
	TestIs(TAPTester.Lines[3], '#      got: object of class TC2', 'negative class 1 test diag ok');
	TestIs(TAPTester.Lines[5], 'not ok 2 - negative case 2 ok', 'negative class 2 test ok');
	TestIs(TAPTester.Lines[6], '# Failed test ''negative case 2 ok''', 'negative class 2 test name ok');
	TestIs(TAPTester.Lines[7], '# expected: object of class TC1', 'negative class 2 test diag ok');
	TestIs(TAPTester.Lines[8], '#      got: object of class TC3', 'negative class 2 test diag ok');

	DoneTesting;
end.

