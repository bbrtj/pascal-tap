{
	TAPSuite is a framework for execution of tests using pascal-tap. The goal
	is to group multiple test cases into one program which compiles and
	executes faster.

	TODO: parallelization.

	For usage examples, see the tests of this module.
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

	{
		Implementing this interface marks the entire suite as skipped.
	}
	ITAPSuiteSkip = interface
	['{06671f72-3010-11ee-86c0-002b67685373}']
	end;

	{
		Implementing this interface marks the entire suite as essential.
		Essential suites will halt the execution if they bail or error out.
	}
	ITAPSuiteEssential = interface
	['{98a0e1bd-301c-11ee-86c0-002b67685373}']
	end;

	{
		Extend this abstract class and add an object of it into TAPSuites list
		(with TAPSuites.Add) for the test to be run during RunAllSuites.
	}
	TTAPSuite = class abstract
	protected
		FScenarios: TTAPScenarios;
		FSuiteName: String;

		{
			Add a scenario to be run in this suite. Should be run in the constructor.
			A scenario is a method (procedure).
		}
		procedure Scenario(const vRunner: TTAPScenarioRunner; const vName: String = '');

	public
		constructor Create(); virtual;
		destructor Destroy; override;

		procedure Setup(); virtual;
		procedure Teardown(); virtual;

		property SuiteName: String read FSuiteName write FSuiteName;
		property Scenarios: TTAPScenarios read FScenarios;
	end;

	TTAPSuites = specialize TFPGObjectList<TTAPSuite>;

var
	TAPSuites: TTAPSuites;

{
	Run all registered test suites.
}
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
	for vSuite in TAPSuites do begin
		SubtestBegin('testing suite: ' + vSuite.SuiteName);

		if vSuite is ITAPSuiteSkip then begin
			SkipAll('suite ' + vSuite.SuiteName + ' is skipped');
			SubtestEnd;
			continue;
		end;

		for vScenario in vSuite.Scenarios do begin
			vError := '';

			SubtestBegin('testing scenario: ' + vScenario.ScenarioName);
			TAPGlobalContext.BailoutBehavior := btExceptionNoOutput;
			vSuite.Setup();

			try
				vScenario.Runner();
			except
				on E: Exception do begin
					vError := E.Message;
					if E is EBailout then
						Diag('!! bailed out: ' + vError)
					else
						Diag('!! encountered an exception: ' + vError);
				end;
			end;

			vSuite.Teardown();
			SubtestEnd;

			if length(vError) > 0 then begin
				if vSuite is ITAPSuiteEssential then
					BailOut('essential scenario failed: ' + vError)
				else
					TestFail('scenario failed: ' + vError, 'scenario finishing without exceptions');
			end;
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

