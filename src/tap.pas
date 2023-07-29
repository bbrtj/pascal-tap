unit TAP;

{$mode objfpc}{$H+}{$J-}

interface

uses sysutils;

type
	TSkippedType = (stNotSkipped, stSkip, stTodo);
	TTAPPrinter = procedure(const vLine: String) of Object;

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
		FSkipped: TSkippedType;

		FPrinter: TTAPPrinter;

		procedure Print(vVals: Array of String);
		procedure PrintToStandardOutput(const vLine: String);
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
	end;

var
	TAPGlobalContext: TTAPContext;

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
	vInd: Integer;
begin
	if FParent <> nil then
		vStr += cTAPSubtestIndent;

	for vInd := 0 to high(vVals) do
		vStr += vVals[vInd];

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

	if vParent <> nil then
		self.FPrinter := vParent.FPrinter
	else
		self.FPrinter := @self.PrintToStandardOutput;
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
	halt(255);
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

{ implementation end }

initialization
	TAPGlobalContext := TTAPContext.Create;

finalization
	TAPGlobalContext.Free;

end.

