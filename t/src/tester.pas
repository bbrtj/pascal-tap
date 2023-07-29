unit Tester;

{$mode objfpc}{$H+}{$J-}

interface

uses TAP, Classes;

type
	TTAPTester = class
	strict private
		FOutput: TStringList;
		FLastContext: TTAPContext;
		FExited: Boolean;

		procedure PrintToVariable(const vLine: String);
		procedure ExitToVariable();

	public
		constructor Create();
		destructor Destroy; override;

		procedure Hijack();
		procedure Release();

		property Lines: TStringList read FOutput;
		property Exited: Boolean read FExited;
	end;

var
	TAPTester: TTAPTester;

implementation

procedure TTAPTester.PrintToVariable(const vLine: String);
begin
	self.FOutput.Append(vLine);
end;

procedure TTAPTester.ExitToVariable();
begin
	self.FExited := True;
end;

constructor TTAPTester.Create();
begin
	self.FOutput := TStringList.Create;
end;

destructor TTAPTester.Destroy;
begin
	self.FOutput.Free;
end;

procedure TTAPTester.Hijack();
var
	vNewContext: TTAPContext;
begin
	vNewContext := TTAPContext.Create;
	self.FOutput.Clear;
	self.FExited := False;
	vNewContext.Printer := @self.PrintToVariable;
	vNewContext.Stopper := @self.ExitToVariable;

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

