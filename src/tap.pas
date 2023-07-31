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
	TSkippedType = (stNoSkip, stSkip, stTodo, stSkipAll);
	TFatalType = (ftNoFatal, ftFatalSingle, ftFatalAll);
	TBailoutType = (btHalt, btException);
	TTAPPrinter = procedure(const vLine: String; const vDiag: Boolean) of Object;

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

		FSkipped: TSkippedType;
		FSkippedReason: String;
		FFatal: TFatalType;

		FPrinter: TTAPPrinter;
		FBailoutBehavior: TBailoutType;

		procedure PrintToStandardOutput(const vLine: String; const vDiag: Boolean);

		procedure Print(vVals: Array of String; const vDiag: Boolean = False);
		procedure PrintDiag(const vName, vExpected, vGot: String);

	public
		constructor Create(const vParent: TTAPContext = nil);

		procedure Skip(const vSkip: TSkippedType; const vReason: String); virtual;
		procedure Ok(const vPassed: Boolean; const vName, vExpected, vGot: String); virtual;

		procedure Comment(const vText: String; const vDiag: Boolean = False); virtual;
		procedure Pragma(const vPragma: String; const vStatus: Boolean = True);
		procedure Plan(const vNumber: UInt32; const vReason: String = ''; const vSkipIfPlanned: Boolean = False); virtual;
		procedure BailOut(const vReason: String); virtual;

		function SubtestBegin(const vName: String): TTAPContext; virtual;
		function SubtestEnd(): TTAPContext; virtual;

		property TestsExecuted: UInt32 read FExecuted;
		property TestsPassed: UInt32 read FPassed;
		property Fatal: TFatalType read FFatal write FFatal;
		property Printer: TTAPPrinter read FPrinter write FPrinter;
		property BailoutBehavior: TBailoutType read FBailoutBehavior write FBailoutBehavior;
	end;

var
	TAPGlobalContext: TTAPContext;

{
	Adds a note to the TAP output as a comment in a new line
}
procedure Note(const vText: String);

{
	Adds diagnostics to the TAP output as a comment. Will be outputed to standard error.
}
procedure Diag(const vText: String);

{
	Marks the next test fatal. Not passing the test will cause the bailout.
	Argument can be passed to turn fatal on or off on all following tests.
}
procedure Fatal(const vType: TFatalType = ftFatalSingle);

{
	Skips the next test executed (just one). Can also todo the next test or
	skip all tests.
}
procedure Skip();
procedure Skip(const vSkip: TSkippedType; const vReason: String = '');

{
	Adds a new unconditionally passing testpoint to the output
}
procedure TestPass(const vName: String = '');

{
	Adds a new unconditionally failing testpoint to the output
}
procedure TestFail(const vName: String = '');

{
	Tests whether the boolean passed as first argument is a true value. Adds a
	testpoint to the output depending on that test. In case of a failure, extra
	diagnostics may be added as comments.
}
procedure TestOk(const vPassed: Boolean; const vName: String = '');

{
	Compares two first arguments and adds a testpoint to the output based on
	comparison result, much like TestOk. Can compare Integers, Strings,
	Booleans and Object classes. Comparing Floats for equality is flawed on the
	basic level, so no Float variant is provided.
}
procedure TestIs(const vGot, vExpected: Int64; const vName: String = '');
procedure TestIs(const vGot, vExpected: String; const vName: String = '');
procedure TestIs(const vGot, vExpected: Boolean; const vName: String = '');
procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');

{
	Same as TestIs, but fails if the arguments are equal.
}
procedure TestIsnt(const vGot, vExpected: Int64; const vName: String = '');
procedure TestIsnt(const vGot, vExpected: String; const vName: String = '');
procedure TestIsnt(const vGot, vExpected: Boolean; const vName: String = '');
procedure TestIsnt(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');

{
	Compares two numbers to determine whether one is greater than the other.
}
procedure TestGreater(const vGot, vExpected: Int64; const vName: String = '');
procedure TestGreater(const vGot, vExpected: Double; const vName: String = '');
procedure TestGreaterOrEqual(const vGot, vExpected: Int64; const vName: String = '');
procedure TestLesser(const vGot, vExpected: Int64; const vName: String = '');
procedure TestLesser(const vGot, vExpected: Double; const vName: String = '');
procedure TestLesserOrEqual(const vGot, vExpected: Int64; const vName: String = '');

{
	Tests whether two floating point values are within the precision of each other.
}
procedure TestWithin(const vGot, vExpected, vPrecision: Double; const vName: String = '');

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
	if vBool then
		result := 'True'
	else
		result := 'False';
end;

// Object interface

procedure TTAPContext.PrintToStandardOutput(const vLine: String; const vDiag: Boolean);
begin
	if vDiag then
		writeln(StdErr, vLine)
	else
		writeln(vLine);
end;

procedure TTAPContext.Print(vVals: Array of String; const vDiag: Boolean = False);
var
	vStr: String = '';
	vInd: Int32;
begin
	if FParent <> nil then
		vStr += cTAPSubtestIndent;

	for vInd := low(vVals) to high(vVals) do begin
		vStr += vVals[Int32(vInd)];
	end;

	self.FPrinter(vStr, vDiag);
end;

procedure TTAPContext.PrintDiag(const vName, vExpected, vGot: String);
begin
	if length(vName) > 0 then
		self.Comment('Failed test ' + Quoted(vName), True)
	else
		self.Comment('Failed test', True);

	self.Comment('expected: ' + vExpected, True);
	self.Comment('     got: ' + vGot, True);
	self.Comment('', True);
end;

constructor TTAPContext.Create(const vParent: TTAPContext = nil);
begin
	self.FParent := vParent;
	self.FName := '';

	self.FPassed := 0;
	self.FExecuted := 0;
	self.FPlanned := False;
	self.FPlan := 0;

	if vParent <> nil then begin
		self.FSkipped := vParent.FSkipped;
		self.FSkippedReason := vParent.FSkippedReason;
		self.FFatal := vParent.FFatal;

		self.FPrinter := vParent.FPrinter;
		self.FBailoutBehavior := vParent.FBailoutBehavior;
	end
	else begin
		self.FSkipped := stNoSkip;
		self.FSkippedReason := '';
		self.FFatal := ftNoFatal;

		self.FPrinter := @self.PrintToStandardOutput;
		self.FBailoutBehavior := btHalt;
	end;
end;

procedure TTAPContext.Comment(const vText: String; const vDiag: Boolean = False);
begin
	if self.FSkipped = stSkipAll then exit;

	if length(vText) > 0 then
		self.Print([cTAPComment, vText], vDiag)
	else
		self.Print([], vDiag);
end;

procedure TTAPContext.Skip(const vSkip: TSkippedType; const vReason: String);
begin
	if self.FSkipped = stSkipAll then exit;

	if vSkip = stSkipAll then begin
		if self.FExecuted > 0 then
			self.BailOut('cannot skip a running test');

		self.Plan(0, cTAPSkip + vReason);
	end;

	self.FSkipped := vSkip;
	self.FSkippedReason := vReason;
end;

procedure TTAPContext.Ok(const vPassed: Boolean; const vName, vExpected, vGot: String);
var
	vResult: String = cTAPOk;
	vSkipped: Boolean;
begin
	if self.FSkipped = stSkipAll then exit;
	vSkipped := self.FSkipped <> stNoSkip;

	self.FExecuted += 1;
	self.FPassed += Integer(vPassed);

	if not vPassed then
		vResult := cTAPNot + vResult;

	vResult += IntToStr(self.FExecuted);

	if length(vName) > 0 then
		vResult += ' - ' + Escaped(vName);

	case self.FSkipped of
		stSkip: vResult += ' ' + cTAPComment + cTAPSkip + self.FSkippedReason;
		stTodo: vResult += ' ' + cTAPComment + cTAPTodo + self.FSkippedReason;
	else
	end;

	self.Print([vResult]);
	if (not vPassed) and (not vSkipped) then begin
		self.PrintDiag(vName, vExpected, vGot);
	end;

	self.Skip(stNoSkip, '');

	if self.FFatal <> ftNoFatal then begin
		if self.FFatal = ftFatalSingle then self.FFatal := ftNoFatal;
		if (not vPassed) and (not vSkipped) then self.BailOut('fatal test failure');
	end;
end;

procedure TTAPContext.Pragma(const vPragma: String; const vStatus: Boolean = True);
var
	vPragmaStatus: Char;
begin
	if self.FSkipped = stSkipAll then exit;

	if vStatus then
		vPragmaStatus := '+'
	else
		vPragmaStatus := '-';

	self.Print([cTAPPragma, vPragmaStatus, vPragma]);
end;

procedure TTAPContext.Plan(const vNumber: UInt32; const vReason: String = ''; const vSkipIfPlanned: Boolean = False);
var
	vFullReason: String = '';
begin
	if self.FSkipped = stSkipAll then exit;

	if self.FPlanned then begin
		if vSkipIfPlanned then exit;
		self.BailOut('cannot plan twice');
	end;

	self.FPlan := vNumber;
	self.FPlanned := True;

	if length(vReason) > 0 then
		vFullReason := ' ' + cTAPComment + Escaped(vReason);

	self.Print(['1..', IntToStr(vNumber), vFullReason]);
end;

procedure TTAPContext.BailOut(const vReason: String);
begin
	if self.FSkipped = stSkipAll then exit;

	// not using self.Print causes bailout to be printed at top TAP
	// level (compatibility with TAP 13)
	self.FPrinter(cTAPBailOut + Escaped(vReason), False);

	case self.FBailoutBehavior of
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

	self.Comment(cTAPSubtest + vName);
end;

function TTAPContext.SubtestEnd(): TTAPContext;
begin
	if self.FParent = nil then
		self.BailOut('no subtest to end');

	result := self.FParent;

	self.Plan(self.FExecuted, '', True);
	if self.FSkipped = stSkipAll then result.Skip(stSkip, self.FSkippedReason);
	result.Ok(self.FPlan = self.FPassed, self.FName, 'pass', 'fail');
	self.Free;
end;

{$INCLUDE helpers.inc}

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	if TAPGlobalContext <> nil then
		TAPGlobalContext.Free;

end.

