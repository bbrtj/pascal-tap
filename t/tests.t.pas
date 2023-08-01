program Tests;

uses TAP, TAPSuite,
	BasicTests, HelpersTests, SubtestsTests, FlowControlTests;

begin
	// BasicTests unit has 2 suites
	Plan(5);

	RunAllSuites;
end.

