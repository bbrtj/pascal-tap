// Common interface

procedure Note(const vText: String);
begin
	TAPGlobalContext.Comment(vText, False);
end;

procedure Diag(const vText: String);
begin
	TAPGlobalContext.Comment(vText, True);
end;

procedure Skip(const vSkip: TSkippedType; const vReason: String);
begin
	TAPGlobalContext.Skip(vSkip, vReason);
end;

procedure TestPass(const vName: String = '');
begin
	TAPGlobalContext.Ok(True, vName, '', '');
end;

procedure TestFail(const vName: String = '');
begin
	TAPGlobalContext.Ok(False, vName, '(nothing)', 'failure');
end;

procedure TestOk(const vPassed: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(vPassed, vName, BoolToReadableStr(True), BoolToReadableStr(False));
end;

procedure TestIs(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot = vExpected, vName, IntToStr(vExpected), IntToStr(vGot));
end;

procedure TestIs(const vGot, vExpected: String; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot = vExpected, vName, Quoted(vExpected), Quoted(vGot));
end;

procedure TestIs(const vGot, vExpected: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot = vExpected, vName, BoolToReadableStr(vExpected), BoolToReadableStr(vGot));
end;

procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot is vExpected, vName, 'object of class ' + vExpected.ClassName, 'object of class ' + vGot.ClassName);
end;

procedure TestIsnt(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(not(vGot = vExpected), vName, 'not ' + IntToStr(vExpected), IntToStr(vGot));
end;

procedure TestIsnt(const vGot, vExpected: String; const vName: String = '');
begin
	TAPGlobalContext.Ok(not(vGot = vExpected), vName, 'not ' + Quoted(vExpected), Quoted(vGot));
end;

procedure TestIsnt(const vGot, vExpected: Boolean; const vName: String = '');
begin
	TAPGlobalContext.Ok(not(vGot = vExpected), vName, 'not ' + BoolToReadableStr(vExpected), BoolToReadableStr(vGot));
end;

procedure TestIsnt(const vGot: TObject; const vExpected: TObjectClass; const vName: String = '');
begin
	TAPGlobalContext.Ok(not(vGot is vExpected), vName, 'not object of class ' + vExpected.ClassName, 'object of class ' + vGot.ClassName);
end;

procedure TestGreater(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot > vExpected, vName, 'more than ' + IntToStr(vExpected), IntToStr(vGot));
end;

procedure TestGreater(const vGot, vExpected: Double; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot > vExpected, vName, 'more than ' + FloatToStr(vExpected), FloatToStr(vGot));
end;

procedure TestGreaterOrEqual(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot >= vExpected, vName, 'at least ' + IntToStr(vExpected), IntToStr(vGot));
end;

procedure TestLesser(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot < vExpected, vName, 'less than ' + IntToStr(vExpected), IntToStr(vGot));
end;

procedure TestLesser(const vGot, vExpected: Double; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot < vExpected, vName, 'less than ' + FloatToStr(vExpected), FloatToStr(vGot));
end;

procedure TestLesserOrEqual(const vGot, vExpected: Int64; const vName: String = '');
begin
	TAPGlobalContext.Ok(vGot <= vExpected, vName, 'at most ' + IntToStr(vExpected), IntToStr(vGot));
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

procedure Plan(const vType: TSkippedType; const vReason: String);
begin
	TAPGlobalContext.Plan(vType, vReason);
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

// vim: ft=pascal

