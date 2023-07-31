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
	TBailoutType = (btHalt, btException);
	TTAPPrinter = procedure(const vLine: String; const vDiag: Boolean) of Object;

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

		procedure PrintToStandardOutput(const vLine: String; const vDiag: Boolean);

		procedure Print(vVals: Array of String; const vDiag: Boolean = False);
		procedure PrintDiag(const vName, vExpected, vGot: String);

	public
		constructor Create(const vParent: TTAPContext = nil);

		procedure Skip(const vSkip: TSkippedType; const vReason: String); virtual;
		procedure Ok(const vPassed: Boolean; const vName, vExpected, vGot: String); virtual;

		procedure Comment(const vText: String; const vDiag: Boolean = False); virtual;
		procedure Pragma(const vPragma: String; const vStatus: Boolean = True); virtual;
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

implementation

// Hidden helpers

function Escaped(const vVal: String): String;
begin
	result := StringReplace(vVal, '\', '\\', [rfReplaceAll]);
	result := StringReplace(result, '#', '\#', [rfReplaceAll]);
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
	for vInd := 1 to self.FNested do
		vStr += cTAPSubtestIndent;

	for vInd := low(vVals) to high(vVals) do begin
		vStr += vVals[Int32(vInd)];
	end;

	self.FPrinter(vStr, vDiag);
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

constructor TTAPContext.Create(const vParent: TTAPContext = nil);
begin
	self.FParent := vParent;
	self.FName := '';

	self.FPassed := 0;
	self.FExecuted := 0;
	self.FPlanned := False;
	self.FPlan := 0;

	if vParent <> nil then begin
		self.FNested := vParent.FNested + 1;
		self.FSkipped := vParent.FSkipped;
		self.FSkippedReason := vParent.FSkippedReason;
		self.FFatal := vParent.FFatal;

		self.FPrinter := vParent.FPrinter;
		self.FBailoutBehavior := vParent.FBailoutBehavior;
	end
	else begin
		self.FNested := 0;
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

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	if TAPGlobalContext <> nil then
		TAPGlobalContext.Free;

end.

