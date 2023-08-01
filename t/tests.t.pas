program Tests;

uses TAPSuite,
	BasicTests, HelpersTests, SubtestsTests, FlowControlTests;

begin
	// Note: suites can also be added in initialization sections, but then
	// there is less control over their sequence.
	Suite(TBasicSuite);
	Suite(TSkippedSuite);
	Suite(THelpersSuite);
	Suite(TSubtestsSuite);
	Suite(TFlowControlSuite);

	RunAllSuites;
end.

