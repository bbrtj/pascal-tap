unit Tester;

{$mode objfpc}{$H+}{$J-}

interface

uses TAP, Classes;

type
	TTAPTester = class
	strict private
		FOutput: TStringList;
		FLastContext: TTAPContext;

		procedure PrintToVariable(const vLine: String);

	public
		constructor Create();
		destructor Destroy; override;

		procedure Hijack();
		procedure Release();

		property Lines: TStringList read FOutput;
	end;

var
	TAPTester: TTAPTester;

implementation

procedure TTAPTester.PrintToVariable(const vLine: String);
begin
	self.FOutput.Append(vLine);
end;

constructor TTAPTester.Create();
begin
	FOutput := TStringList.Create;
end;

destructor TTAPTester.Destroy;
begin
	FOutput.Free;
end;

procedure TTAPTester.Hijack();
var
	vNewContext: TTAPContext;
begin
	vNewContext := TTAPContext.Create;
	vNewContext.Printer := @self.PrintToVariable;

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

