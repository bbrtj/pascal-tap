{
}
unit TAPSuite;

{$mode objfpc}{$H+}{$J-}
{$interfaces corba}
{$modeswitch advancedrecords}

interface

uses TAP, TAPCore, fgl, sysutils;

type
	TTAPScenarioRunner = procedure() of object;
	TTAPScenario = record
		Runner: TTAPScenarioRunner;
		ScenarioName: String;
		class operator= (const vR1, vR2: TTAPScenario): Boolean;
	end;

	TTAPScenarios = specialize TFPGList<TTAPScenario>;

	ITAPSuiteSkip = interface
	['{06671f72-3010-11ee-86c0-002b67685373}']
	end;

	TTAPSuite = class abstract
	protected
		FScenarios: TTAPScenarios;
		FSuiteName: String;

		procedure Scenario(const vRunner: TTAPScenarioRunner; const vName: String = '');

	public
		constructor Create();
		destructor Destroy; override;

		procedure Setup(); virtual;
		procedure Teardown(); virtual;

		property SuiteName: String read FSuiteName write FSuiteName;
		property Scenarios: TTAPScenarios read FScenarios;
	end;

	TTAPSuites = specialize TFPGObjectList<TTAPSuite>;

var
	TAPSuites: TTAPSuites;

procedure RunAllSuites();

implementation

class operator TTAPScenario.= (const vR1, vR2: TTAPScenario): Boolean;
begin
	result := vR1.Runner = vR2.Runner;
end;

procedure RunAllSuites();
var
	vSuite: TTAPSuite;
	vScenario: TTAPScenario;
	vError: String;
begin
	TAPGlobalContext.BailoutBehavior := btExceptionNoOutput;

	for vSuite in TAPSuites do begin
		if vSuite is ITAPSuiteSkip then begin
			SkipAll('suite ' + vSuite.SuiteName + ' is skipped');
			continue;
		end;

		SubtestBegin('testing suite: ' + vSuite.SuiteName);

		for vScenario in vSuite.Scenarios do begin
			vError := '';

			SubtestBegin('testing scenario: ' + vScenario.ScenarioName);
			try
				vSuite.Setup();
				vScenario.Runner();
				vSuite.Teardown();
			except
				on E: Exception do begin
					vError := E.Message;
					if E is EBailout then
						Diag('!! bailed out: ' + vError)
					else
						Diag('!! encountered an exception: ' + vError);
				end;
			end;
			SubtestEnd;

			if length(vError) > 0 then
				TestFail('scenario failed: ' + vError);
		end;

		SubtestEnd;
	end;

	DoneTesting;
end;

procedure TTAPSuite.Scenario(const vRunner: TTAPScenarioRunner; const vName: String = '');
var
	vScenario: TTAPScenario;
begin
	vScenario.Runner := vRunner;
	if length(vName) > 0 then
		vScenario.ScenarioName := vName
	else
		vScenario.ScenarioName := '(unnamed)';

	self.FScenarios.Add(vScenario);
end;

constructor TTAPSuite.Create();
begin
	self.FScenarios := TTAPScenarios.Create;
	self.FSuiteName := self.ClassName;
end;

destructor TTAPSuite.Destroy;
begin
	if self.FScenarios <> nil then
		self.FScenarios.Free;

	inherited;
end;

procedure TTAPSuite.Setup();
begin
end;

procedure TTAPSuite.Teardown();
begin
end;

initialization
	TAPSuites := TTAPSuites.Create;

finalization
	if TAPSuites <> nil then
		TAPSuites.Free;

end.

