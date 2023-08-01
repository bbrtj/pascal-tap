{
	Test helpers such like Is and Isnt.
}
unit HelpersTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, TAPCore, Tester;

type
	THelpersSuite = class(TTAPSuite)
		constructor Create(); override;

		procedure IsTest();
		procedure IsClassTest();
		procedure IsntTest();
		procedure IsntClassTest();
		procedure LesserGreaterTest();
	end;

implementation

type
	TC1 = class(TObject);
	TC2 = class(TC1);
	TC3 = class(TObject);

constructor THelpersSuite.Create();
begin
	inherited;
	Scenario(@self.IsTest, 'Test regular TestIs variants');
	Scenario(@self.IsClassTest, 'Test class TestIs variants');
	Scenario(@self.IsntTest, 'Test regular TestIsnt variants');
	Scenario(@self.IsntClassTest, 'Test class TestIsnt variants');
	Scenario(@self.LesserGreaterTest, 'Test all TestLesser variants');
end;

procedure THelpersSuite.IsTest();
begin
	TAPTester.Hijack;
	TestIs(5, 5, 'integers 1');
	TestIs(5, 4, 'integers 0');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - integers 1', 'integers 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - integers 0', 'integers 0 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');

	TAPTester.Hijack;
	TestIs('abc', 'abc', 'strings 1');
	TestIs('??', '?', 'strings 0');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - strings 1', 'strings 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - strings 0', 'strings 0 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');

	TAPTester.Hijack;
	TestIs(False, False, 'booleans 1');
	TestIs(True, False, 'booleans 0');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - booleans 1', 'booleans 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - booleans 0', 'booleans 0 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
end;

procedure THelpersSuite.IsClassTest();
var
	vParent: TC1;
	vChild: TC2;
	vCousin: TC3;
begin
	vParent := TC1.Create;
	vChild := TC2.Create;
	vCousin := TC3.Create;

	TAPTester.Hijack;
	TestIs(vParent, TC1, 'TC1 ok');
	TestIs(vChild, TC2, 'TC2 ok');
	TestIs(vCousin, TC3, 'TC3 ok');
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 3, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - TC1 ok', 'class 1 test ok');
	TestIs(TAPTester.Lines[1], 'ok 2 - TC2 ok', 'class 2 test ok');
	TestIs(TAPTester.Lines[2], 'ok 3 - TC3 ok', 'class 3 test ok');

	vParent.Free;
	vParent := TC2.Create;

	TAPTester.Hijack;
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

	TestIs(TAPTester.Lines.Count, 2, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 8, 'diag line count ok');

	TestIs(TAPTester.Lines[0], 'not ok 1 - negative case 1 ok', 'negative class 1 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - negative case 2 ok', 'negative class 2 test ok');

	TestIs(TAPTester.DiagLines[0], '# Failed test ''negative case 1 ok''', 'negative class 1 test name ok');
	TestIs(TAPTester.DiagLines[1], '# expected: object of class TC3', 'negative class 1 test diag ok');
	TestIs(TAPTester.DiagLines[2], '#      got: object of class TC2', 'negative class 1 test diag ok');
	TestIs(TAPTester.DiagLines[4], '# Failed test ''negative case 2 ok''', 'negative class 2 test name ok');
	TestIs(TAPTester.DiagLines[5], '# expected: object of class TC1', 'negative class 2 test diag ok');
	TestIs(TAPTester.DiagLines[6], '#      got: object of class TC3', 'negative class 2 test diag ok');

	vParent.Free;
	vChild.Free;
	vCousin.Free;
end;

procedure THelpersSuite.IsntTest();
begin
	TAPTester.Hijack;
	TestIsnt(5, 4, 'integers 0');
	TestIsnt(5, 5, 'integers 1');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - integers 0', 'integers 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - integers 1', 'integers 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not 5', 'integers 1 test diag ok');

	TAPTester.Hijack;
	TestIsnt('', '?', 'strings 0');
	TestIsnt('abc', 'abc', 'strings 1');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - strings 0', 'strings 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - strings 1', 'strings 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not ''abc''', 'strings 1 test diag ok');

	TAPTester.Hijack;
	TestIsnt(True, False, 'booleans 0');
	TestIsnt(False, False, 'booleans 1');
	TAPTester.Release;

	TestIs(TAPTester.Lines[0], 'ok 1 - booleans 0', 'booleans 0 test ok');
	TestIs(TAPTester.Lines[1], 'not ok 2 - booleans 1', 'booleans 1 test ok');
	TestOk(TAPTester.DiagLines.Count > 0, 'lines describing the failure ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not False', 'booleans 1 test diag ok');
end;

procedure THelpersSuite.IsntClassTest();
var
	vParent: TC1;
begin
	vParent := TC1.Create;
	TAPTester.Hijack;
	TestIsnt(vParent, TC1, 'TC1 ok');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	Fatal; TestIs(TAPTester.DiagLines.Count, 4, 'diag line count ok');
	TestIs(TAPTester.Lines[0], 'not ok 1 - TC1 ok', 'class 1 test ok');
	TestIs(TAPTester.DiagLines[1], '# expected: not object of class TC1', 'class 1 test ok');

	TAPTester.Hijack;
	TestIsnt(vParent, TC3, 'negative case 1 ok');
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 1, 'line count ok');
	TestIs(TAPTester.Lines[0], 'ok 1 - negative case 1 ok', 'negative class 1 test ok');

	vParent.Free;
end;

procedure THelpersSuite.LesserGreaterTest();
var
	vTotalTests, vPassedTests: UInt32;
begin
	TAPTester.Hijack;
	TestLesser(1, 2);
	TestLesser(1.1, 1.2);
	TestLesserOrEqual(1, 1);
	TestGreater(2, 1);
	TestGreater(1.2, 1.1);
	TestGreaterOrEqual(2, 2);
	TestWithin(1.51526, 1.51532, 0.0001);
	TAPTester.Release;

	TestIs(TAPTester.Lines.Count, 7, 'line count ok');
	TestIs(TAPTester.DiagLines.Count, 0, 'diag line count ok');

	TAPTester.Hijack;
	TestLesser(2, 2);
	TestLesser(3, 2);
	TestLesser(1.2, 1.2);
	TestLesserOrEqual(2, 1);
	TestGreater(2, 2);
	TestGreater(2, 3);
	TestGreater(1.2, 1.2);
	TestGreaterOrEqual(1, 2);
	TestWithin(1.5126, 1.5137, 0.001);
	TAPTester.Release;

	Fatal; TestIs(TAPTester.Lines.Count, 9, 'line count ok');
	Fatal; TestIs(TAPTester.DiagLines.Count, 36, 'diag line count ok');
	TestIs(TAPTester.DiagLines[1], '# expected: less than 2', 'test 1 diag ok');
	TestIs(TAPTester.DiagLines[9], '# expected: less than 1.2', 'test 3 diag ok');
	TestIs(TAPTester.DiagLines[13], '# expected: at most 1', 'test 4 diag ok');
	TestIs(TAPTester.DiagLines[17], '# expected: more than 2', 'test 5 diag ok');
	TestIs(TAPTester.DiagLines[25], '# expected: more than 1.2', 'test 7 diag ok');
	TestIs(TAPTester.DiagLines[29], '# expected: at least 2', 'test 8 diag ok');
	TestIs(TAPTester.DiagLines[33], '# expected: 1.5137 +-0.001', 'test 9 diag ok');
end;

begin
	TAPSuites.Add(THelpersSuite.Create);
end.

