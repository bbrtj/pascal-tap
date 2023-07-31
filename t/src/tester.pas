unit Tester;

{$mode objfpc}{$H+}{$J-}

interface

uses TAP, Classes;

type
	TTAPTester = class
	strict private
		FOutput: TStringList;
		FDiagOutput: TStringList;
		FLastContext: TTAPContext;

		procedure PrintToVariable(const vLine: String; const vDiag: Boolean);

	public
		constructor Create();
		destructor Destroy; override;

		procedure Hijack();
		procedure Release();

		property Lines: TStringList read FOutput;
		property DiagLines: TStringList read FDiagOutput;
	end;

var
	TAPTester: TTAPTester;

implementation

procedure TTAPTester.PrintToVariable(const vLine: String; const vDiag: Boolean);
begin
	if vDiag then self.FDiagOutput.Append(vLine)
	else self.FOutput.Append(vLine);
end;

constructor TTAPTester.Create();
begin
	self.FOutput := TStringList.Create;
	self.FDiagOutput := TStringList.Create;
end;

destructor TTAPTester.Destroy;
begin
	self.FOutput.Free;
	self.FDiagOutput.Free;
end;

procedure TTAPTester.Hijack();
var
	vNewContext: TTAPContext;
begin
	vNewContext := TTAPContext.Create;
	self.FOutput.Clear;
	self.FDiagOutput.Clear;
	vNewContext.Printer := @self.PrintToVariable;
	vNewContext.BailoutBehavior := btException;

	self.FLastContext := TAPGlobalContext;
	TAPGlobalContext := vNewContext;
end;

procedure TTAPTester.Release();
begin
	if TAPGlobalContext <> nil then
		TAPGlobalContext.Free;

	TAPGlobalContext := FLastContext;
end;

{ implementation end }

initialization
	TAPTester := TTAPTester.Create;

finalization
	TAPTester.Free;

end.

