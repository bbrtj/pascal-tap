// Common interface

procedure Note(const vText: String);
begin
	TAPGlobalContext.Note(vText);
end;

procedure Skip(const vSkip: TSkippedType; const vReason: String);
begin
	TAPGlobalContext.Skip(vSkip, vReason);
end;

procedure TestPass(const vName: String);
begin
	TAPGlobalContext.TestPass(vName);
end;

procedure TestFail(const vName: String);
begin
	TAPGlobalContext.TestFail(vName);
end;

procedure TestOk(const vPassed: Boolean; const vName: String);
begin
	TAPGlobalContext.TestOk(vPassed, vName);
end;

procedure TestIs(const vGot, vExpected: Int64; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure TestIs(const vGot, vExpected: String; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure TestIs(const vGot, vExpected: Boolean; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
end;

procedure TestIs(const vGot: TObject; const vExpected: TObjectClass; const vName: String);
begin
	TAPGlobalContext.TestIs(vGot, vExpected, vName);
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
	TAPGlobalContext.DoneTesting;
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

