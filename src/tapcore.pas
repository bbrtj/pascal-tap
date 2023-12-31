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

	This unit contains the internals of this TAP implementation. For normal
	usage, see TAP unit.
}
unit TAPCore;

{$mode objfpc}{$H+}{$J-}

interface

uses sysutils;

type
	TSkippedType = (stNoSkip, stSkip, stTodo, stSkipAll);
	TFatalType = (ftNoFatal, ftFatalSingle, ftFatalAll);
	TBailoutType = (btHalt, btException, btExceptionNoOutput);
	TTAPPrinter = procedure(const vLine: String; vDiag: Boolean) of Object;

	EBailout = class(Exception);

	{
		TTAPContext is the main class which keeps track of tests performed and
		outputs TAP. It can be used directly, but this is considered advanced
		usage. Instead, use the helper procedures provided by TAPHelpers unit to
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
		FNested: UInt32;
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

		procedure PrintToStandardOutput(const vLine: String; vDiag: Boolean);

		procedure Print(vVals: Array of String; vDiag: Boolean = False);
		procedure PrintDiag(const vName, vExpected, vGot: String);

	public
		constructor Create(vParent: TTAPContext = nil); virtual;

		procedure Skip(vSkip: TSkippedType; const vReason: String); virtual;
		procedure Ok(vPassed: Boolean; const vName, vExpected, vGot: String); virtual;

		procedure Comment(const vText: String; vDiag: Boolean = False); virtual;
		procedure Pragma(const vPragma: String; vStatus: Boolean = True); virtual;
		procedure Plan(vNumber: UInt32; const vReason: String = ''; vSkipIfPlanned: Boolean = False); virtual;
		procedure BailOut(const vReason: String); virtual;

		function SubtestBegin(const vName: String): TTAPContext; virtual;
		function SubtestEnd(): TTAPContext; virtual;

		property TestsExecuted: UInt32 read FExecuted;
		property TestsPassed: UInt32 read FPassed;
		property Fatal: TFatalType read FFatal write FFatal;
		property Printer: TTAPPrinter read FPrinter write FPrinter;
		property BailoutBehavior: TBailoutType read FBailoutBehavior write FBailoutBehavior;
	end;

	TTAPContextClass = class of TTAPContext;

var
	TAPGlobalContext: TTAPContext;

implementation

// Hidden helpers

function Escaped(const vVal: String): String;
begin
	result := StringReplace(vVal, '\', '\\', [rfReplaceAll]);
	result := StringReplace(result, '#', '\#', [rfReplaceAll]);
end;

// Object interface

procedure TTAPContext.PrintToStandardOutput(const vLine: String; vDiag: Boolean);
begin
	if vDiag then
		writeln(StdErr, vLine)
	else
		writeln(vLine);
end;

procedure TTAPContext.Print(vVals: Array of String; vDiag: Boolean = False);
var
	vStr: String;
	vInd: Int32;
begin
	vStr := '';
	for vInd := 1 to FNested do
		vStr += cTAPSubtestIndent;

	for vInd := low(vVals) to high(vVals) do begin
		vStr += vVals[Int32(vInd)];
	end;

	FPrinter(vStr, vDiag);
end;

procedure TTAPContext.PrintDiag(const vName, vExpected, vGot: String);
begin
	if length(vName) > 0 then
		self.Comment('Failed test ''' + vName + '''', True)
	else
		self.Comment('Failed test', True);

	self.Comment('expected: ' + vExpected, True);
	self.Comment('     got: ' + vGot, True);
	self.Comment('', True);
end;

constructor TTAPContext.Create(vParent: TTAPContext = nil);
begin
	FParent := vParent;
	FName := '';

	FPassed := 0;
	FExecuted := 0;
	FPlanned := False;
	FPlan := 0;

	if vParent <> nil then begin
		FNested := vParent.FNested + 1;
		FSkipped := vParent.FSkipped;
		FSkippedReason := vParent.FSkippedReason;
		FFatal := vParent.FFatal;

		FPrinter := vParent.FPrinter;
		FBailoutBehavior := vParent.FBailoutBehavior;
	end
	else begin
		FNested := 0;
		FSkipped := stNoSkip;
		FSkippedReason := '';
		FFatal := ftNoFatal;

		FPrinter := @self.PrintToStandardOutput;
		FBailoutBehavior := btHalt;
	end;
end;

procedure TTAPContext.Comment(const vText: String; vDiag: Boolean = False);
begin
	if FSkipped = stSkipAll then exit;

	if length(vText) > 0 then
		self.Print([cTAPComment, vText], vDiag)
	else
		self.Print([], vDiag);
end;

procedure TTAPContext.Skip(vSkip: TSkippedType; const vReason: String);
begin
	if FSkipped = stSkipAll then exit;

	if vSkip = stSkipAll then begin
		if FExecuted > 0 then
			self.BailOut('cannot skip a running test');

		self.Plan(0, cTAPSkip + vReason);
	end;

	FSkipped := vSkip;
	FSkippedReason := vReason;
end;

procedure TTAPContext.Ok(vPassed: Boolean; const vName, vExpected, vGot: String);
var
	vResult: String;
	vSkipped: Boolean;
begin
	if FSkipped = stSkipAll then exit;
	vSkipped := FSkipped <> stNoSkip;

	FExecuted += 1;
	FPassed += Integer(vPassed);

	vResult := cTAPOk;
	if not vPassed then
		vResult := cTAPNot + vResult;

	vResult += IntToStr(FExecuted);

	if length(vName) > 0 then
		vResult += ' - ' + Escaped(vName);

	case FSkipped of
		stSkip: vResult += ' ' + cTAPComment + cTAPSkip + FSkippedReason;
		stTodo: vResult += ' ' + cTAPComment + cTAPTodo + FSkippedReason;
	else
	end;

	self.Print([vResult]);
	if (not vPassed) and (not vSkipped) then begin
		self.PrintDiag(vName, vExpected, vGot);
	end;

	self.Skip(stNoSkip, '');

	if FFatal <> ftNoFatal then begin
		if FFatal = ftFatalSingle then FFatal := ftNoFatal;
		if (not vPassed) and (not vSkipped) then self.BailOut('fatal test failure');
	end;
end;

procedure TTAPContext.Pragma(const vPragma: String; vStatus: Boolean = True);
var
	vPragmaStatus: Char;
begin
	if FSkipped = stSkipAll then exit;

	if vStatus then
		vPragmaStatus := '+'
	else
		vPragmaStatus := '-';

	self.Print([cTAPPragma, vPragmaStatus, vPragma]);
end;

procedure TTAPContext.Plan(vNumber: UInt32; const vReason: String = ''; vSkipIfPlanned: Boolean = False);
var
	vFullReason: String;
begin
	if FSkipped = stSkipAll then exit;

	if FPlanned then begin
		if vSkipIfPlanned then exit;
		self.BailOut('cannot plan twice');
	end;

	FPlan := vNumber;
	FPlanned := True;

	if length(vReason) > 0 then
		vFullReason := ' ' + cTAPComment + Escaped(vReason)
	else
		vFullReason := '';

	self.Print(['1..', IntToStr(vNumber), vFullReason]);
end;

procedure TTAPContext.BailOut(const vReason: String);
begin
	if FSkipped = stSkipAll then exit;

	// not using self.Print causes bailout to be printed at top TAP
	// level (compatibility with TAP 13)
	if FBailoutBehavior <> btExceptionNoOutput then
		FPrinter(cTAPBailOut + Escaped(vReason), False);

	case FBailoutBehavior of
		btHalt: halt(255);
		btException, btExceptionNoOutput: raise EBailout.Create(vReason);
	end;
end;

function TTAPContext.SubtestBegin(const vName: String): TTAPContext;
begin
	result := TTAPContextClass(self.ClassType).Create(self);
	result.FName := vName;

	self.Comment(cTAPSubtest + vName);
end;

function TTAPContext.SubtestEnd(): TTAPContext;
begin
	if FParent = nil then
		self.BailOut('no subtest to end');

	result := FParent;

	self.Plan(FExecuted, '', True);
	if FSkipped = stSkipAll then result.Skip(stSkip, FSkippedReason);
	result.Ok(FPlan = FPassed, FName, 'pass', 'fail');
	Free;
end;

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	if TAPGlobalContext <> nil then
		TAPGlobalContext.Free;

end.

