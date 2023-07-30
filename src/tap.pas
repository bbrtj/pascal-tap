{
	Partial implementation of TAP version 14 producer.
	https://testanything.org/tap-version-14-specification.html

	Features:
	- outputs valid TAP
	- minimal interface with a few helpers for basic Pascal types
	- configurable output destination
	- keeps track of suite / subtest state (passed / executed)
	- simple and small, easy to extend

	Missing TAP v14 features:
	- skipping single testpoints
	- YAML
	- pragmas
}
unit TAP;

{$mode objfpc}{$H+}{$J-}

interface

uses sysutils;

type
	TSkippedType = (stNotSkipped, stSkip, stTodo);
	TBailoutType = (btHalt, btException);
	TTAPPrinter = procedure(const vLine: String) of Object;

	EBailout = class(Exception);

	{
		TTAPContext is the main class which keeps track of tests performed and
		outputs TAP. It can be used directly, but this is considered advanced
		usage. Instead, use the helper procedures provided by this unit to
		manipulate the global object.
	}
	TTAPContext = class
	const
		cTAPOk = 'ok ';
		cTAPNot = 'not ';
		cTAPComment = '# ';
		cTAPSubtest = 'Subtest: ';
		cTAPSubtestIndent = '    ';
		cTAPTodo = 'TODO ';
		cTAPSkip = 'SKIP ';
		cTAPBailOut = 'Bail out! ';

	strict private
		FParent: TTAPContext;
		FName: String;

		FExecuted: UInt32;
		FPassed: UInt32;
		FPlanned: Boolean;
		FPlan: UInt32;

		FPrinter: TTAPPrinter;
		FSkipped: TSkippedType;
		FBailout: TBailoutType;

		procedure PrintToStandardOutput(const vLine: String);

		procedure Print(vVals: Array of String);
		procedure PrintDiag(const vName, vExpected, vGot: String);

	public
		constructor Create(const vParent: TTAPContext = nil);

		procedure Note(const vText: String);

		procedure TestPass(const vName: String);
		procedure TestFail(const vName: String);
		procedure TestOk(const vPassed: Boolean; const vName: String);
		procedure TestIs(const vGot, vExpected: Int64; const vName: String);
		procedure TestIs(const vGot, vExpected: String; const vName: String);
		procedure TestIs(const vGot, vExpected: Boolean; const vName: String);

		procedure Plan(const vNumber: UInt32; const vReason: String = '');
		procedure Plan(const vType: TSkippedType; const vReason: String);
		procedure DoneTesting();
		procedure BailOut(const vReason: String);

		function SubtestBegin(const vName: String): TTAPContext;
		function SubtestEnd(): TTAPContext;

		function TestsExecuted(): UInt32;
		function TestsPassed(): UInt32;

		property Printer: TTAPPrinter read FPrinter write FPrinter;
		property BailoutBehavior: TBailoutType read FBailout write FBailout;
	end;

var
	TAPGlobalContext: TTAPContext;

{
	Adds a note to the TAP output as a comment in a new line
}
procedure Note(const vText: String);

{
	Adds a new unconditionally passing testpoint to the output
}
procedure TestPass(const vName: String);

{
	Adds a new unconditionally failing testpoint to the output
}
procedure TestFail(const vName: String);

{
	Tests whether the boolean passed as first argument is a true value. Adds a
	testpoint to the output depending on that test. In case of a failure, extra
	diagnostics may be added as comments.
}
procedure TestOk(const vPassed: Boolean; const vName: String);

{
	Compares two first arguments and adds a testpoint to the output based on
	comparison result, much like TestOk. Can compare Integers, Strings and
	Booleans. Comparing Floats for equality is flawed on the basic level, so no
	Float variant is provided.
}
procedure TestIs(const vGot, vExpected: Int64; const vName: String);
procedure TestIs(const vGot, vExpected: String; const vName: String);
procedure TestIs(const vGot, vExpected: Boolean; const vName: String);

{
	Adds an explicit plan to the output. Best run before running other tests.
	If you don't want to count tests manually you can finish your test with
	DoneTesting instead.
}
procedure Plan(const vNumber: UInt32; const vReason: String = '');

{
	Plans for skips or todos. Must be run before any other tests. All the tests
	will be run, but no output will be produced.
}
procedure Plan(const vType: TSkippedType; const vReason: String);

{
	Outputs a plan based on the number of tests ran (if it was not printed
	already)
}
procedure DoneTesting();

{
	Bails out of the test. By default, it will be done by halting the program
	with exit code 255.
}
procedure BailOut(const vReason: String);

{
	Starts a subtest. All subtests must be closed with SubtestEnd for valid
	output to be produced. Note that subtests cannot be nested.
}
procedure SubtestBegin(const vName: String);
procedure SubtestEnd();

implementation

// Hidden helpers

function Escaped(const vVal: String): String;
begin
	result := StringReplace(vVal, '\', '\\', [rfReplaceAll]);
	result := StringReplace(result, '#', '\#', [rfReplaceAll]);
end;

function Quoted(const vVal: String): String;
begin
	result := '''' + vVal + '''';
end;

function BoolToReadableStr(const vBool: Boolean): String;
begin
	if vBool then result := 'True'
	else result := 'False';
end;

// Object interface

procedure TTAPContext.PrintToStandardOutput(const vLine: String);
begin
	writeln(vLine);
end;

procedure TTAPContext.Print(vVals: Array of String);
var
	vStr: String = '';
	vInd: Int32;
begin
	if FParent <> nil then
		vStr += cTAPSubtestIndent;

	for vInd := low(vVals) to high(vVals) do begin
		vStr += vVals[Int32(vInd)];
	end;

	self.FPrinter(vStr);
end;

constructor TTAPContext.Create(const vParent: TTAPContext = nil);
begin
	self.FParent := vParent;
	self.FName := '';

	self.FPassed := 0;
	self.FExecuted := 0;
	self.FPlanned := False;
	self.FPlan := 0;
	self.FSkipped := stNotSkipped;

	if vParent <> nil then begin
		self.FPrinter := vParent.FPrinter;
		self.FBailout := vParent.FBailout;
	end
	else begin
		self.FPrinter := @self.PrintToStandardOutput;
		self.FBailout := btHalt;
	end;
end;

procedure TTAPContext.PrintDiag(const vName, vExpected, vGot: String);
begin
	self.Note('expected: ' + vExpected);
	self.Note('     got: ' + vGot);
	self.Note('');
end;

procedure TTAPContext.Note(const vText: String);
begin
	if self.FSkipped <> stNotSkipped then exit;

	if length(vText) > 0 then
		self.Print([cTAPComment, Escaped(vText)])
	else
		self.Print([]);
end;

procedure TTAPContext.TestPass(const vName: String);
begin
	self.TestOk(True, vName);
end;

procedure TTAPContext.TestFail(const vName: String);
begin
	self.TestOk(False, vName);
end;

procedure TTAPContext.TestOk(const vPassed: Boolean; const vName: String);
var
	vResult: String = cTAPOk;
begin
	if self.FSkipped <> stNotSkipped then exit;

	self.FExecuted += 1;

	if vPassed then self.FPassed += 1
	else vResult := cTAPNot + vResult;

	self.Print([vResult, IntToStr(self.FExecuted), ' - ', Escaped(vName)]);
	if not vPassed then begin
		self.Note('Failed test ' + Quoted(vName));
	end;
end;

procedure TTAPContext.TestIs(const vGot, vExpected: Int64; const vName: String);
var
	vResult: Boolean;
begin
	vResult := vGot = vExpected;
	self.TestOk(vResult, vName);

	if not vResult then
		self.PrintDiag(vName, IntToStr(vExpected), IntToStr(vGot));
end;

procedure TTAPContext.TestIs(const vGot, vExpected: String; const vName: String);
var
	vResult: Boolean;
begin
	vResult := vGot = vExpected;
	self.TestOk(vResult, vName);

	if not vResult then
		self.PrintDiag(vName, Quoted(vExpected), Quoted(vGot));
end;

procedure TTAPContext.TestIs(const vGot, vExpected: Boolean; const vName: String);
var
	vResult: Boolean;
begin
	vResult := vGot = vExpected;
	self.TestOk(vResult, vName);

	if not vResult then
		self.PrintDiag(vName, BoolToReadableStr(vExpected), BoolToReadableStr(vGot));
end;

procedure TTAPContext.Plan(const vNumber: UInt32; const vReason: String = '');
var
	vFullReason: String = '';
begin
	if self.FPlanned then
		raise Exception.Create('cannot plan twice');

	self.FPlan := vNumber;
	self.FPlanned := True;

	if length(vReason) > 0 then
		vFullReason := ' ' + cTAPComment + Escaped(vReason);

	self.Print(['1..', IntToStr(vNumber), vFullReason]);
end;

procedure TTAPContext.Plan(const vType: TSkippedType; const vReason: String);
var
	vFullReason: String = '';
begin
	if self.FExecuted > 0 then
		raise Exception.Create('cannot plan a running test');

	if vType = stSkip then vFullReason += cTAPSkip
	else if vType = stTodo then vFullReason += cTAPTodo
	else exit;

	vFullReason += Escaped(vReason);
	self.Plan(0, vFullReason);
	self.FSkipped := vType;
end;

procedure TTAPContext.DoneTesting();
begin
	if not self.FPlanned then
		self.Plan(self.FExecuted);
end;

procedure TTAPContext.BailOut(const vReason: String);
begin
	self.Print([cTAPBailOut, Escaped(vReason)]);

	case self.FBailout of
		btHalt: halt(255);
		btException: raise EBailout.Create(vReason);
	end;
end;

function TTAPContext.SubtestBegin(const vName: String): TTAPContext;
begin
	if self.FParent <> nil then
		raise Exception.Create('cannot nest subtests');

	result := TTAPContext.Create(self);
	result.FName := vName;

	self.Print([cTAPComment, cTAPSubtest, Escaped(vName)]);
end;

function TTAPContext.SubtestEnd(): TTAPContext;
begin
	if self.FParent = nil then
		raise Exception.Create('no subtest to end');

	result := self.FParent;

	self.DoneTesting;
	result.TestOk(self.FPlan = self.FPassed, self.FName);
	self.Free;
end;

function TTAPContext.TestsExecuted(): UInt32;
begin
	result := self.FExecuted;
end;

function TTAPContext.TestsPassed(): UInt32;
begin
	result := self.FPassed;
end;

// Common interface

procedure Note(const vText: String);
begin
	TAPGlobalContext.Note(vText);
end;

procedure TestPass(const vName: String);
begin
	TAPGlobalContext.TestPass(vName);
end;

procedure TestFail(const vName: String);
begin
	TAPGlobalContext.TestFail(vName);
end;

procedure TestOk(const vPassed: Boolean; const vName: String);
begin
	TAPGlobalContext.TestOk(vPassed, vName);
end;

procedure TestIs(const vGot, vExpected: Int64; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure TestIs(const vGot, vExpected: String; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure TestIs(const vGot, vExpected: Boolean; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure Plan(const vNumber: UInt32; const vReason: String = '');
begin
	TAPGlobalContext.Plan(vNumber, vReason);
end;

procedure Plan(const vType: TSkippedType; const vReason: String);
begin
	TAPGlobalContext.Plan(vType, vReason);
end;

procedure DoneTesting();
begin
	TAPGlobalContext.DoneTesting;
end;

procedure BailOut(const vReason: String);
begin
	TAPGlobalContext.BailOut(vReason);
end;

procedure SubtestBegin(const vName: String);
begin
	TAPGlobalContext := TAPGlobalContext.SubtestBegin(vName);
end;

procedure SubtestEnd();
begin
	TAPGlobalContext := TAPGlobalContext.SubtestEnd;
end;

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	TAPGlobalContext.Free;

end.

