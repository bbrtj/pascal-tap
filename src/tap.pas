{
	This unit provides helpers for producing TAP output. Using its code you can
	easily add your own helpers in the same manner in another unit like
	CustomTAP.
}
unit TAP;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPCore, sysutils;

type
	TObjectClass = class of TObject;

{
	Adds a note to the TAP output as a comment in a new line
}
procedure Note(const vText: String);

{
	Adds diagnostics to the TAP output as a comment. Will be outputed to standard error.
}
procedure Diag(const vText: String);

{
	Marks the next test fatal. Not passing the test will cause the bailout.
}
procedure Fatal();
procedure FatalAll(const vEnabled: Boolean = True);

{
	Skips the next test executed (just one). Can also todo the next test or
	skip all tests.
}
procedure Skip(const vReason: String = '');
procedure Todo(const vReason: String = '');
procedure SkipAll(const vReason: String = '');

{
	Adds a new unconditionally passing testpoint to the output
}
procedure TestPass(const vName: String = '');

{
	Adds a new unconditionally failing testpoint to the output
}
procedure TestFail(const vName: String = ''; const vDiag: String = '(nothing)');

{
	Tests whether the boolean passed as first argument is a true value. Adds a
	testpoint to the output depending on that test. In case of a failure, extra
	diagnostics may be added as comments.
}
procedure TestOk(const vPassed: Boolean; const vName: String = '');

{
	Compares two first arguments and adds a testpoint to the output based on
	comparison result, much like TestOk. Can compare Integers, Strings,
	Booleans and Object classes. Comparing Floats for equality is flawed on the
	basic level, so no Float variant is provided.
}
procedure TestIs(const vGot, vExpected: Int64; const vName: String = '');
procedure TestIs(const vGot, vExpected: String; const vName: String = '');
procedure TestIs(const vGot, vExpected: Boolean; const vName: String = '');
procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');

{
	Same as TestIs, but fails if the arguments are equal.
}
procedure TestIsnt(const vGot, vExpected: Int64; const vName: String = '');
procedure TestIsnt(const vGot, vExpected: String; const vName: String = '');
procedure TestIsnt(const vGot, vExpected: Boolean; const vName: String = '');
procedure TestIsnt(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');

{
	Compares two numbers to determine whether one is greater than the other.
}
procedure TestGreater(const vGot, vExpected: Int64; const vName: String = '');
procedure TestGreater(const vGot, vExpected: Double; const vName: String = '');
procedure TestGreaterOrEqual(const vGot, vExpected: Int64; const vName: String = '');
procedure TestLesser(const vGot, vExpected: Int64; const vName: String = '');
procedure TestLesser(const vGot, vExpected: Double; const vName: String = '');
procedure TestLesserOrEqual(const vGot, vExpected: Int64; const vName: String = '');

{
	Tests whether two floating point values are within the precision of each other.
}
procedure TestWithin(const vGot, vExpected, vPrecision: Double; const vName: String = '');

{
	Outputs a pragma. Since pragmas are implementation-specific, no predefined
	list exists and full string name of the pragma must be specified.
}
procedure Pragma(const vPragma: String; const vStatus: Boolean = True);

{
	Adds an explicit plan to the output. Best run before running other tests.
	If you don't want to count tests manually you can finish your test with
	DoneTesting instead.
}
procedure Plan(const vNumber: UInt32; const vReason: String = '');

{
	Outputs a plan based on the number of tests ran (if it was not printed
	already)
}
procedure DoneTesting();

{
	Bails out of the test. By default, it will be done by halting the program
	with exit code 255.
}
procedure BailOut(const vReason: String);

{
	Starts a subtest. All subtests must be closed with SubtestEnd for valid
	output to be produced.
}
procedure SubtestBegin(const vName: String);
procedure SubtestEnd();

implementation

// Hidden helpers

function Quoted(const vVal: String): String;
begin
	result := '''' + vVal + '''';
end;

function BoolToReadableStr(const vBool: Boolean): String;
begin
	if vBool then
		result := 'True'
	else
		result := 'False';
end;

// TAP Interface

procedure Note(const vText: String);
begin
	TAPGlobalContext.Comment(vText);
end;

procedure Diag(const vText: String);
begin
	TAPGlobalContext.Comment(vText, True);
end;

procedure Fatal();
begin
	if TAPGlobalContext.Fatal <> ftFatalAll then
		TAPGlobalContext.Fatal := ftFatalSingle;
end;

procedure FatalAll(const vEnabled: Boolean = True);
begin
	if vEnabled then
		TAPGlobalContext.Fatal := ftFatalAll
	else
		TAPGlobalContext.Fatal := ftNoFatal;
end;


procedure Skip();
begin
	TAPGlobalContext.Skip(stSkip, '');
end;

procedure Skip(const vReason: String = '');
begin
	TAPGlobalContext.Skip(stSkip, vReason);
end;

procedure Todo(const vReason: String = '');
begin
	TAPGlobalContext.Skip(stTodo, vReason);
end;

procedure SkipAll(const vReason: String = '');
begin
	TAPGlobalContext.Skip(stSkipAll, vReason);
end;

procedure TestPass(const vName: String = '');
begin
	TAPGlobalContext.Ok(
		True,
		vName,
		'',
		''
	);
end;

procedure TestFail(const vName: String = ''; const vDiag: String = '(nothing)');
begin
	TAPGlobalContext.Ok(
		False,
		vName,
		vDiag,
		'failure'
	);
end;

procedure TestOk(const vPassed: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vPassed,
		vName,
		BoolToReadableStr(True),
		BoolToReadableStr(False)
	);
end;

procedure TestIs(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot = vExpected,
		vName,
		IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestIs(const vGot, vExpected: String; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot = vExpected,
		vName,
		Quoted(vExpected),
		Quoted(vGot)
	);
end;

procedure TestIs(const vGot, vExpected: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot = vExpected,
		vName,
		BoolToReadableStr(vExpected),
		BoolToReadableStr(vGot)
	);
end;

procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot is vExpected,
		vName,
		'object of class ' + vExpected.ClassName,
		'object of class ' + vGot.ClassName
	);
end;

procedure TestIsnt(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		not(vGot = vExpected),
		vName,
		'not ' + IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestIsnt(const vGot, vExpected: String; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		not(vGot = vExpected),
		vName,
		'not ' + Quoted(vExpected),
		Quoted(vGot)
	);
end;

procedure TestIsnt(const vGot, vExpected: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		not(vGot = vExpected),
		vName,
		'not ' + BoolToReadableStr(vExpected),
		BoolToReadableStr(vGot)
	);
end;

procedure TestIsnt(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		not(vGot is vExpected),
		vName,
		'not object of class ' + vExpected.ClassName,
		'object of class ' + vGot.ClassName
	);
end;

procedure TestGreater(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot > vExpected,
		vName,
		'more than ' + IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestGreater(const vGot, vExpected: Double; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot > vExpected,
		vName,
		'more than ' + FloatToStr(vExpected),
		FloatToStr(vGot)
	);
end;

procedure TestGreaterOrEqual(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot >= vExpected,
		vName,
		'at least ' + IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestLesser(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot < vExpected,
		vName,
		'less than ' + IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestLesser(const vGot, vExpected: Double; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot < vExpected,
		vName,
		'less than ' + FloatToStr(vExpected),
		FloatToStr(vGot)
	);
end;

procedure TestLesserOrEqual(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		vGot <= vExpected,
		vName,
		'at most ' + IntToStr(vExpected),
		IntToStr(vGot)
	);
end;

procedure TestWithin(const vGot, vExpected, vPrecision: Double; const vName: String = '');
begin
	TAPGlobalContext.Ok(
		abs(vGot - vExpected) < vPrecision,
		vName,
		FloatToStr(vExpected) + ' +-' + FloatToStr(vPrecision),
		FloatToStr(vGot)
	);
end;

procedure Pragma(const vPragma: String; const vStatus: Boolean = True);
begin
	TAPGlobalContext.Pragma(vPragma, vStatus);
end;

procedure Plan(const vNumber: UInt32; const vReason: String = '');
begin
	TAPGlobalContext.Plan(vNumber, vReason);
end;

procedure DoneTesting();
begin
	TAPGlobalContext.Plan(TAPGlobalContext.TestsExecuted, '', True);
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

end.

