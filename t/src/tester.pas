unit Tester;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPCore, Classes;

type
	TTAPTester = class
	strict private
		FOutput: TStringList;
		FDiagOutput: TStringList;
		FLastContext: TTAPContext;

		procedure PrintToVariable(const vLine: String; vDiag: Boolean);

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

procedure TTAPTester.PrintToVariable(const vLine: String; vDiag: Boolean);
begin
	if vDiag then FDiagOutput.Append(vLine)
	else FOutput.Append(vLine);
end;

constructor TTAPTester.Create();
begin
	FOutput := TStringList.Create;
	FDiagOutput := TStringList.Create;
end;

destructor TTAPTester.Destroy;
begin
	FOutput.Free;
	FDiagOutput.Free;
end;

procedure TTAPTester.Hijack();
var
	vNewContext: TTAPContext;
begin
	vNewContext := TTAPContext.Create;
	FOutput.Clear;
	FDiagOutput.Clear;
	vNewContext.Printer := @self.PrintToVariable;
	vNewContext.BailoutBehavior := btException;

	FLastContext := TAPGlobalContext;
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

