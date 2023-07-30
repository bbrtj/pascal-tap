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
	- YAML diagnostics
}
unit TAP;

{$mode objfpc}{$H+}{$J-}

interface

uses sysutils;

type
	TObjectClass = class of TObject;
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
		cTAPPragma = 'pragma ';

	strict private
		FParent: TTAPContext;
		FName: String;

		FExecuted: UInt32;
		FPassed: UInt32;
		FPlanned: Boolean;
		FPlan: UInt32;

		FPrinter: TTAPPrinter;
		FAllSkipped: TSkippedType;
		FSkipped: TSkippedType;
		FSkippedReason: String;
		FBailout: TBailoutType;

		procedure PrintToStandardOutput(const vLine: String);

		procedure Print(vVals: Array of String);
		procedure PrintDiag(const vName, vExpected, vGot: String);

	protected
		procedure InternalOk(const vPassed: Boolean; const vName, vExpected, vGot: String); virtual;

	public
		constructor Create(const vParent: TTAPContext = nil);

		procedure Note(const vText: String);

		procedure Skip(const vSkip: TSkippedType; const vReason: String); virtual;
		procedure TestPass(const vName: String); virtual;
		procedure TestFail(const vName: String); virtual;
		procedure TestOk(const vPassed: Boolean; const vName: String); virtual;
		procedure TestIs(const vGot, vExpected: Int64; const vName: String); virtual;
		procedure TestIs(const vGot, vExpected: String; const vName: String); virtual;
		procedure TestIs(const vGot, vExpected: Boolean; const vName: String); virtual;
		procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String); virtual;

		procedure Pragma(const vPragma: String; const vStatus: Boolean = True);
		procedure Plan(const vNumber: UInt32; const vReason: String = ''); virtual;
		procedure Plan(const vSkip: TSkippedType; const vReason: String); virtual;
		procedure DoneTesting(); virtual;
		procedure BailOut(const vReason: String); virtual;

		function SubtestBegin(const vName: String): TTAPContext; virtual;
		function SubtestEnd(): TTAPContext; virtual;

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
	Skips the next test executed (just one)
}
procedure Skip(const vSkip: TSkippedType; const vReason: String);

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
procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String);

{
	Outputs a pragma. Since pragmas are implementation-specific, no predefined
	list exists and full string name of the pragma must be specified.
}
procedure Pragma(const vPragma: String; const vStatus: Boolean = True);

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

procedure TTAPContext.PrintDiag(const vName, vExpected, vGot: String);
begin
	self.Note('Failed test ' + Quoted(vName));
	self.Note('expected: ' + vExpected);
	self.Note('     got: ' + vGot);
	self.Note('');
end;

procedure TTAPContext.InternalOk(const vPassed: Boolean; const vName, vExpected, vGot: String);
var
	vResult: String = cTAPOk;
	vDirective: String = '';
begin
	if self.FAllSkipped <> stNotSkipped then exit;

	self.FExecuted += 1;

	if vPassed then self.FPassed += 1
	else vResult := cTAPNot + vResult;

	case self.FSkipped of
		stSkip: vDirective := ' ' + cTAPComment + cTAPSkip + self.FSkippedReason;
		stTodo: vDirective := ' ' + cTAPComment + cTAPTodo + self.FSkippedReason;
	else
		// vDirective already empty
	end;

	self.Print([vResult, IntToStr(self.FExecuted), ' - ', Escaped(vName), vDirective]);
	if (not vPassed) and (self.FSkipped = stNotSkipped) then begin
		self.PrintDiag(vName, vExpected, vGot);
	end;

	self.FSkipped := stNotSkipped;
	self.FSkippedReason := '';
end;

constructor TTAPContext.Create(const vParent: TTAPContext = nil);
begin
	self.FParent := vParent;
	self.FName := '';

	self.FPassed := 0;
	self.FExecuted := 0;
	self.FPlanned := False;
	self.FPlan := 0;
	self.FAllSkipped := stNotSkipped;
	self.FSkipped := stNotSkipped;
	self.FSkippedReason := '';

	if vParent <> nil then begin
		self.FPrinter := vParent.FPrinter;
		self.FBailout := vParent.FBailout;
	end
	else begin
		self.FPrinter := @self.PrintToStandardOutput;
		self.FBailout := btHalt;
	end;
end;

procedure TTAPContext.Note(const vText: String);
begin
	if self.FAllSkipped <> stNotSkipped then exit;

	if length(vText) > 0 then
		self.Print([cTAPComment, vText])
	else
		self.Print([]);
end;

procedure TTAPContext.Skip(const vSkip: TSkippedType; const vReason: String);
begin
	self.FSkipped := vSkip;
	self.FSkippedReason := vReason;
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
begin
	self.InternalOk(vPassed, vName, BoolToReadableStr(True), BoolToReadableStr(False));
end;

procedure TTAPContext.TestIs(const vGot, vExpected: Int64; const vName: String);
begin
	self.InternalOk(vGot = vExpected, vName, IntToStr(vExpected), IntToStr(vGot));
end;

procedure TTAPContext.TestIs(const vGot, vExpected: String; const vName: String);
begin
	self.InternalOk(vGot = vExpected, vName, Quoted(vExpected), Quoted(vGot));
end;

procedure TTAPContext.TestIs(const vGot, vExpected: Boolean; const vName: String);
begin
	self.InternalOk(vGot = vExpected, vName, BoolToReadableStr(vExpected), BoolToReadableStr(vGot));
end;

procedure TTAPContext.TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String);
begin
	self.InternalOk(vGot is vExpected, vName, 'object of class ' + vExpected.ClassName, 'object of class ' + vGot.ClassName);
end;

procedure TTAPContext.Pragma(const vPragma: String; const vStatus: Boolean = True);
var
	vPragmaStatus: Char;
begin
	if vStatus then vPragmaStatus := '+'
	else vPragmaStatus := '-';

	self.Print([cTAPPragma, vPragmaStatus, vPragma]);
end;

procedure TTAPContext.Plan(const vNumber: UInt32; const vReason: String = '');
var
	vFullReason: String = '';
begin
	if self.FPlanned then
		self.BailOut('cannot plan twice');

	self.FPlan := vNumber;
	self.FPlanned := True;

	if length(vReason) > 0 then
		vFullReason := ' ' + cTAPComment + Escaped(vReason);

	self.Print(['1..', IntToStr(vNumber), vFullReason]);
end;

procedure TTAPContext.Plan(const vSkip: TSkippedType; const vReason: String);
var
	vFullReason: String = '';
begin
	if self.FExecuted > 0 then
		self.BailOut('cannot plan a running test');

	case vSkip of
		stSkip: vFullReason += cTAPSkip;
		stTodo: vFullReason += cTAPSkip + cTAPTodo;
	else
		exit;
	end;

	vFullReason += vReason;
	self.Plan(0, vFullReason);
	self.FAllSkipped := vSkip;

	// if this is a subtest, skip next testpoint
	// (it will be a subtest testpoint)
	if self.FParent <> nil then
		self.FParent.Skip(vSkip, vReason);
end;

procedure TTAPContext.DoneTesting();
begin
	if not self.FPlanned then
		self.Plan(self.FExecuted);
end;

procedure TTAPContext.BailOut(const vReason: String);
begin
	// not using self.Print causes bailout to be printed at top TAP
	// level (compatibility with TAP 13)
	self.FPrinter(cTAPBailOut + Escaped(vReason));

	case self.FBailout of
		btHalt: halt(255);
		btException: raise EBailout.Create(vReason);
	end;
end;

function TTAPContext.SubtestBegin(const vName: String): TTAPContext;
begin
	if self.FParent <> nil then
		self.BailOut('cannot nest subtests');

	result := TTAPContext.Create(self);
	result.FName := vName;

	self.Print([cTAPComment, cTAPSubtest, vName]);
end;

function TTAPContext.SubtestEnd(): TTAPContext;
begin
	if self.FParent = nil then
		self.BailOut('no subtest to end');

	result := self.FParent;

	self.DoneTesting;
	result.InternalOk(self.FPlan = self.FPassed, self.FName, 'pass', 'fail');
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

{$INCLUDE helpers.inc}

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	TAPGlobalContext.Free;

end.

