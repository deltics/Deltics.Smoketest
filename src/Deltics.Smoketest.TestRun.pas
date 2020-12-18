{
  * MIT LICENSE *

  Copyright � 2019 Jolyon Smith

  Permission is hereby granted, free of charge, to any person obtaining a copy of
   this software and associated documentation files (the "Software"), to deal in
   the Software without restriction, including without limitation the rights to
   use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is furnished to do
   so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.


  * GPL and Other Licenses *

  The FSF deem this license to be compatible with version 3 of the GPL.
   Compatability with other licenses should be verified by reference to those
   other license terms.


  * Contact Details *

  Original author : Jolyon Direnko-Smith
  e-mail          : jsmith@deltics.co.nz
  github          : deltics/deltics.smoketest
}

{$i deltics.smoketest.inc}

  unit Deltics.Smoketest.TestRun;


interface

  uses
    Classes,
    SysUtils,
    Deltics.Smoketest.Accumulators,
    Deltics.Smoketest.ExpectedException,
    Deltics.Smoketest.SelfTestContext,
    Deltics.Smoketest.Test,
    Deltics.Smoketest.TestResult;


  type
    TTestMethod = procedure of object;

    TTestRun = class
    private
      fCmdLineArgs: TStringList;
      fShowAllResults: Boolean;
      fVerboseOutput: Boolean;
      fLineFeedBeforeTypeNameOrSummary: Boolean;

      fDefaultTestName: String;
      fName: String;
      fEnvironment: String;
      fIsAborted: Boolean;
      fIsFinished: Boolean;
      fIsRunning: Boolean;
      fStartTime: TDateTime;
      fFinishTime: TDateTime;

      fTypeName: String;
      fHumanisedMethodName: String;
      fMethodName: String;
      fPreviousMethodName: String;
      fPreviousTypeName: String;
      fTestName: String;
      fTestNamePrefix: String;
      fExpectedException: IExpectedException;
      fSelfTest: ISelfTestContext;
      fTestsExpected: Boolean;

      fTestIndex: Integer;

      fResults: TList;
      fAccumulator: IAccumulator;
      fWriters: TStringList;

      function get_FinishTime: TDateTime;
      function get_RunTime: Integer;
      function get_Failed: Boolean;
      procedure set_Environment(const aValue: String);
      procedure set_Name(const aValue: String);

      function AddResult(const aTestName: String; const aResult: TResultState; const aReason: String; const aException: Exception): TTestResult;
      procedure EmitMethodName;
      procedure EmitTypeName;
      function ExtractMethod(const aTest: TTest; const aMethodList: TStringList; const aMethodToExtract: String): TTestMethod;

      procedure SaveResults;

    protected
      procedure Abort;
      procedure BeginRun;
      procedure Complete;
      procedure SetTestType(const aTypeName: String);
      procedure SetTestMethod(const aMethodName: String);
      procedure SetTestNamePrefix(const aPrefix: String);
      procedure ExpectingException(const aExceptionClass: TClass; const aMessage: String; const aExactClass: Boolean);
      procedure ExpectingNoException;
      procedure ExpectingToError;
      procedure ExpectingToFail;
      function TestError(const aException: Exception = NIL): TTestResult;
      function TestFailed(const aTestName: String; const aReason: String): TTestResult;
      function TestPassed(const aTestName: String): TTestResult;

    public
      constructor Create;
      destructor Destroy; override;

      function HasCmdLineOption(const aName: String; var aValue: String): Boolean; overload;
      function HasCmdLineOption(const aName: String): Boolean; overload;
      procedure NoTestsPerformed;
      procedure Test(const aTest: TTestClass; const aNamePrefix: String = ''); overload;
      procedure Test(const aTests: array of TTestClass; const aNamePrefix: String = ''); overload;

      property DefaultTestName: String read fDefaultTestName write fDefaultTestName;
      property Name: String read fName write set_Name;
      property Environment: String read fEnvironment write set_Environment;
      property IsAborted: Boolean read fIsAborted;
      property IsFinished: Boolean read fIsFinished;
      property IsRunning: Boolean read fIsRunning;
      property Failed: Boolean read get_Failed;

      property StartTime: TDateTime read fStartTime;
      property FinishTime: TDateTime read get_FinishTime;
      property RunTime: Integer read get_RunTime;

      property Results: IAccumulator read fAccumulator;
      property ResultsWriters: TStringList read fWriters;
    end;


  var
    TestRun: TTestRun;


implementation

  uses
  {$ifdef DELPHI2006__}
    {$ifdef __DELPHI2009}
      Windows,
    {$endif}
  {$endif}
    Deltics.Smoketest.Accumulators.StateAccumulator,
    Deltics.Smoketest.Assertions.Factory,
    Deltics.Smoketest.ResultsWriter,
    Deltics.Smoketest.Utils;


  type
    Accumulators = class(Deltics.Smoketest.Accumulators.Accumulators);
    TTestHelper = class(TTest); // For access to protected GetTestMethods


  function Humanised(const aString: String): String;
  var
    i, j: Integer;
    c, nc: AnsiChar;
  begin
    if aString = '' then
    begin
      result := '';
      EXIT;
    end;

    SetLength(result, 2 * Length(aString));
    j := 1;
    for i := 1 to Length(aString) do
    begin
      c := AnsiChar(aString[i]);
      if (c in ['A'..'Z']) then
      begin
        nc := AnsiChar(aString[i + 1]);

        if (i > 1) then
        begin
          if (i < Length(aString)) and NOT (nc in ['A'..'Z']) then
          begin
            result[j] := ' ';
            Inc(j);
          end;

          if i > 1 then
            result[j] := Char(Ord(aString[i]) + 32);
        end
        else
          result[j] := aString[i];

        Inc(j);
      end
      else
      begin
        result[j] := aString[i];
        Inc(j);
      end;
    end;

    SetLength(result, j - 1);
  end;



{ TTestRun --------------------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TTestRun.Create;
  var
    i: Integer;
  begin
    inherited Create;

    fCmdLineArgs  := TStringList.Create;
    fResults      := TList.Create;
    fWriters      := TStringList.Create;

    for i := 0 to ParamCount do
      fCmdLineArgs.Add(ParamStr(i));

    fVerboseOutput  := HasCmdLineOption('verbose') or HasCmdLineOption('v');
    fShowAllResults := fVerboseOutput or HasCmdLineOption('showAllResults') or HasCmdLineOption('a');

    fAccumulator := Accumulators.Register(TStateAccumulator);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TTestRun.Destroy;
  var
    i: Integer;
  begin
    for i := 0 to Pred(fResults.Count) do
      TObject(fResults[i]).Free;

    for i := 0 to Pred(fWriters.Count) do
      fWriters.Objects[i].Free;

    fResults.Free;
    fWriters.Free;
    fCmdLineArgs.Free;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.get_Failed: Boolean;
  begin
    result := (fAccumulator.Fail + fAccumulator.Error) > 0;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.get_FinishTime: TDateTime;
  {
    It is an error to attempt to reference the testrun finishtime if the
     testrun has not yet actually finished.
  }
  begin
    if NOT fIsFinished then
      raise Exception.Create('Test run has not yet finished');

    result := fFinishTime;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.get_RunTime: Integer;
  {
    Returns the runtime (in milliseconds) of the testrun.  If the testrun
     is finished then the runtime reflects the time from start to finish.
     If the testrun is not yet finished then the runtime reflects the time
     from start to now (and thus will keep increasing until the testrun is
     finished).
  }
  var
    finish: TDateTime;
  begin
    if fIsFinished then
      finish := FinishTime
    else
      finish := Now;

    result := Round((finish - fStartTime) * 24 * 60 * 60 * 1000);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.set_Environment(const aValue: String);
  begin
    if fIsRunning then
      WriteLn('WARNING: Attempt to change TestRun.Environment during test run (ignored)')
    else if fIsFinished then
      WriteLn('WARNING: Attempt to change TestRun.Environment after test run completion (ignored)')
    else
      fEnvironment := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.set_Name(const aValue: String);
  begin
    if fIsRunning then
      WriteLn('WARNING: Ignored attempt to change TestRun.Name during test run')
    else if fIsFinished then
      WriteLn('WARNING: Ignored attempt to change TestRun.Name after test run completion')
    else
      fName := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.Abort;
  begin
    fIsAborted := TRUE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.AddResult(const aTestName: String;
                              const aResult: TResultState;
                              const aReason: String;
                              const aException: Exception): TTestResult;

    function HumanisedTypeName: String;
    begin
      result := fTypeName;
      if (result[1] = 'T') and (AnsiChar(result[2]) in ['A'..'Z']) then
        Delete(result, 1, 1);

      result := Humanised(result);
    end;

    function GetTestName: String;
    {
      Calculates and returns the name of the current test.

      If no test name has been explicitly set then the name will default to the
       name of the currently executing test method.  If there is no method name
       then the test (class) name is used.

      Any specified name prefix is then applied.

      Finally, where the name has been derived from either the method or test
       class name, the name is appended by a numeric identifier of the test
       being performed (since in this case there are likely to be multiple
       'unnamed' tests being performed) to help identify which test is being
       referenced.
    }
    begin
      result := fTestName;

      result := StringReplace(result, METHOD_NAME, fHumanisedMethodName, [rfReplaceAll, rfIgnoreCase]);
      result := StringReplace(result, TEST_NAME, HumanisedTypeName, [rfReplaceAll, rfIgnoreCase]);

      if result = '' then
        result := fMethodName + ' test #' + IntToStr(fTestIndex);

      if fTestNamePrefix <> '' then
        result := '[' + fTestNamePrefix + '] ' + result;
    end;

  const
    STATE_LABEL: array[TResultState] of String = ('PASSED', 'FAILED', 'skipped', 'ERROR');
  var
    effectiveResult: TResultState;
    expectedResult: TResultState;
    testName: String;
    reason: String;
  begin
    fTestName := aTestName;
    try
      Inc(fTestIndex);

      effectiveResult := aResult;
      expectedResult  := rsPass;
      if IsAborted then
        effectiveResult := rsSkip;

      if Assigned(fSelfTest) then
        expectedResult := fSelfTest.ExpectedResult;

      testName  := GetTestName;
      reason    := aReason;

      result := TTestResult.Create(testName, fTypeName, fMethodName, fTestIndex, effectiveResult, expectedResult, reason);

      if effectiveResult = expectedResult then
        result.State := rsPass;

      fResults.Add(result);

      Accumulators.Execute(result);

      if NOT (fShowAllResults or (result.State in [rsFail, rsError])) then
        EXIT;

      EmitTypeName;
      EmitMethodName;
      fLineFeedBeforeTypeNameOrSummary := TRUE;

      Write('    + ');
      if (expectedResult = rsPass) then
      begin
        WriteLn(STATE_LABEL[aResult] + ': ' + testName);
        if aResult in [rsFail, rsError] then
          WriteLn('      [' + reason + ']');
      end
      else
        WriteLn(STATE_LABEL[result.ActualState] + ' (' + STATE_LABEL[result.ExpectedState] + ' was expected): ' + testName);

    finally
      fTestName := '';
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.BeginRun;
  begin
    if fIsRunning then
    begin
      WriteLn('WARNING: Multiple calls to TestRun.BeginRun detected (first call started the run)');
      EXIT;
    end;

    if (fName = '') then
      fName := ExtractFilename(ParamStr(0));

    if fEnvironment = '' then
      fEnvironment := 'Test';

    WriteLn(':> ' + CmdLine);
    WriteLn('Smoketest test run: Name=' + fName + ', Environment=' + fEnvironment);
    Write('Writers supported: ');
    if fWriters.Count > 0 then WriteLn(fWriters.CommaText) else WriteLn('(none)');
    WriteLn;

    fStartTime := Now;
    fIsRunning := TRUE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.Complete;
  begin
    if fIsFinished then
    begin
      WriteLn('WARNING: Attempt to call TestRun.Complete multiple times.');
      WriteLn('         (The first call already terminated the run)');
      EXIT;
    end;

    fIsFinished := TRUE;
    fFinishTime := Now;

    try
      if fLineFeedBeforeTypeNameOrSummary then
        WriteLn;

      if Results.Count = 0 then
      begin
        WriteLn('WARNING: No tests performed.');
        EXIT;
      end;

      WriteLn(Format('Total Tests = %d, Passed = %d, Failed = %d, Skipped = %d, Errors = %d',
                     [Results.Count, Results.Pass, Results.Fail, Results.Skip, Results.Error]));

      SaveResults;

    finally
      if Failed then
      begin
        WriteLn('Test run FAILED');
        ExitCode := 1;
      end;

      if (DebugHook > 0) or HasCmdLineOption('wait') then
      begin
        WriteLn('Press ENTER to terminate process.');
        ReadLn;
      end;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.EmitMethodName;
  begin
    if (fPreviousMethodName <> fMethodName) then
    begin
      WriteLn('  > ' + fMethodName);
      fPreviousMethodName := fMethodName;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.EmitTypeName;
  begin
    if (fPreviousTypeName <> fTypeName) then
    begin
      if fLineFeedBeforeTypeNameOrSummary then
        WriteLn;

      WriteLn(' ' + fTypeName);
      fPreviousTypeName := fTypeName;
      fLineFeedBeforeTypeNameOrSummary := FALSE;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.ExpectingException(const aExceptionClass: TClass;
                                        const aMessage: String;
                                        const aExactClass: Boolean);
  {
    Sets details of an expected exception.  If the next test that is performed
     raises an exception that matches these details then this will be
     acknowledged as the expected result (i.e. a PASS) rather than an error.

    These details are cleared and the expected result reset to Pass by the
     execution of a test.  That is, setting details of an expected exception
     applies only for the immediately following test.

    NOTE: This method is intended only to be called by the tests implemented
           in the smoketest selftest project.  It is NOT designed or intended
           for general use.
  }
  begin
    if Assigned(fExpectedException) then
      raise ESmoketestError.Create('Invalid attempt to configure multiple exception tests in this method');

    fExpectedException := TExpectedException.Create(aExceptionClass, aExactClass, aMessage);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.ExpectingNoException;
  {
    Sets details of an expected exception.  If the next test that is performed
     raises an exception that matches these details then this will be
     acknowledged as the expected result (i.e. a PASS) rather than an error.

    These details are cleared and the expected result reset to Pass by the
     execution of a test.  That is, setting details of an expected exception
     applies only for the immediately following test.

    NOTE: This method is intended only to be called by the tests implemented
           in the smoketest selftest project.  It is NOT designed or intended
           for general use.
  }
  begin
    if Assigned(fExpectedException) then
      raise ESmoketestError.Create('Invalid attempt to configure multiple exception tests in this method');

    fExpectedException := TExpectedException.CreateNoneExpected;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.ExpectingToError;
  {
    Sets the expected result to Fail.  If the next test that is performed
     fails then this can be acknowledged as the expected result (i.e. a PASS)
     rather than an actual failure.

    The expected result will be reset to Pass by the execution of a test.
     That is, setting the expected result to Fail applies only for the
     immediately following test.

    NOTE: This method is intended only to be called by the tests implemented
           in the smoketest selftest project.  It is NOT designed or intended
           for general use.
  }
  begin
    fSelfTest := TSelfTestContext.Create(rsError);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.ExpectingToFail;
  {
    Sets the expected result to Fail.  If the next test that is performed
     fails then this can be acknowledged as the expected result (i.e. a PASS)
     rather than an actual failure.

    The expected result will be reset to Pass by the execution of a test.
     That is, setting the expected result to Fail applies only for the
     immediately following test.

    NOTE: This method is intended only to be called by the tests implemented
           in the smoketest selftest project.  It is NOT designed or intended
           for general use.
  }
  begin
    fSelfTest := TSelfTestContext.Create(rsFail);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.TestError(const aException: Exception): TTestResult;
  var
    eo: TObject;
    e: Exception;
    reason: String;
    msg: String;
    testname: String;
    state: TResultState;
    expectedMessage: String;
    actualMessage: String;
  begin
    e         := aException;
    testname  := '';
    msg       := '';
    state     := rsError;

    if NOT Assigned(e) then
    begin
      eo := ExceptObject;

      if eo is Exception then
        e := Exception(eo);
    end
    else
      eo := e;

    if Assigned(e) then
      msg := e.Message;

    if msg = '' then
      msg := '<no exception message>';

    if Assigned(fExpectedException) then
    begin
      testname := fExpectedException.TestName;

      if (eo is ENoExceptionRaised) then
      begin
        reason := 'Expected exception ' + eo.ClassName;
        if fExpectedException.Message <> '' then
          reason := reason + ' with message ''' + fExpectedException.Message + '''';

        reason := reason + ' was NOT raised';
        state  := rsFail;
      end
      else if fExpectedException.Matches(eo) then
      begin
        reason   := Format('Raised expected exception %s [%s]', [eo.ClassName, msg]);
        state    := rsPass;
      end
      else
      begin
        if NOT fExpectedException.MatchesClass(eo) then
          reason  := Format('Expecting %s exception but raised %s'#13,
                            [fExpectedException.ExceptionClass.ClassName, eo.ClassName]);

        expectedMessage := fExpectedException.Message;
        if Assigned(e) then
          actualMessage := e.Message
        else
          actualMessage := '';

        if (expectedMessage <> '') and NOT fExpectedException.MatchesMessage(actualMessage) then
          reason  := reason + Format('Expected message ''%s'' is not contained in ''%s''', [fExpectedException.Message, actualMessage]);

        state := rsFail;  // We were expecting an exception but not the one we got - this results in a FAIL rather than an ERROR
      end;

      fExpectedException := NIL;
    end
    else
      reason  := Format('Exception: %s [%s]', [eo.ClassName, msg]);

    result := AddResult(testname, state, Format(reason, [eo.ClassName, msg]), e);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.TestFailed(const aTestName: String;
                               const aReason: String): TTestResult;
  begin
    result := AddResult(aTestName, rsFail, aReason, NIL);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.TestPassed(const aTestName: String): TTestResult;
  begin
    result := AddResult(aTestName, rsPass, '', NIL);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.ExtractMethod(const aTest: TTest;
                                  const aMethodList: TStringList;
                                  const aMethodToExtract: String): TTestMethod;
  var
    i: Integer;
  begin
    TMethod(result).Data := NIL;
    TMethod(result).Code := NIL;

    for i := 0 to Pred(aMethodList.Count) do
    begin
      if NOT SameText(aMethodList[i], aMethodToExtract) then
        CONTINUE;

      TMethod(result).Data := aTest;
      TMethod(result).Code := aTest.MethodAddress(aMethodList[i]);

      aMethodList.Delete(i);
      BREAK;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.SetTestType(const aTypeName: String);
  begin
    fTypeName := aTypeName;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.SetTestMethod(const aMethodName: String);
  begin
    fHumanisedMethodName  := Humanised(aMethodName);
    fMethodName           := aMethodName;

    fTestIndex     := 0;
    fTestsExpected := TRUE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.SetTestNamePrefix(const aPrefix: String);
  begin
    fTestNamePrefix := aPrefix;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.SaveResults;
  {
    Identifies command line options that specify known results writer
     formats.  For each identified writer option, call the writer to
     output the test results as required.
  }
  var
    i: Integer;
    filename: String;
  begin
    for i := 0 to Pred(fWriters.Count) do
    begin
      if NOT HasCmdLineOption(fWriters[i], filename) then
        CONTINUE;

      try
        WriteLn(Format('Writing %s results to %s', [fWriters[i], filename]));
        TResultsWriter(fWriters.Objects[i]).SaveResults(filename);

      except
        on e: Exception do
          WriteLn(Format('ERROR: Failed to write %s results to %s (%s: %s)', [fWriters[i], filename, e.ClassName, e.Message]));
      end;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.HasCmdLineOption(const aName: String): Boolean;
  {
    Convenience function for determining the presence of a command line
     option where there is no associated value or the value is of no interest.
  }
  var
    notUsed: String;
  begin
    result := HasCmdLineOption(aName, notUsed);
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  procedure TTestRun.NoTestsPerformed;
  {
    Indicates to the TestRun that a test method explicitly did not perform
     any tests.  This suppresses the console warning that is usually produced
     when a test method does not perform any tests.

    NOTE: This indicator auto-resets for each method.
  }
  begin
    fTestsExpected := FALSE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TTestRun.HasCmdLineOption(const aName: String;
                                     var   aValue: String): Boolean;
  {
    Examines the command line looking for the presence of a specified option
     with an optional value which, if present, is passed back in the var
     aValue parameter.

    Options are expected to be specified in one of the three forms:

         -name
         -name:value
         -name=value

    If value contains spaces, then the value should be quoted:

         -name="value with spaces"

    If a quoted value contains quotes then these will be stripped from the value,
     even if they are 'escaped' by doubling.  This is due to poor handling of
     quoted command line elements by the ParamSTR() RTL function and will
     possibly change in the future by avoiding the use of ParamStr() but only
     if the need becomes pressing.  For now be aware that quoted values will
     not themselves contain ANY quotes:

         -name="1 foot = 12"""           ->   value = '1 foot = 12'
         -name="1 foot = 12"             ->   value = '1 foot = 12'
         -name="value ""with"" spaces"   ->   value = 'value with spaces'

    The first provides the option but has no value.  The second and third
     forms provide the option and the associated value follows the separator
     character which must be either a ':' or a '='.  Only the first occurence
     of either of these separators is significant for the purpose of identifying
     options and associated values:

         -mode:level=42      > identifies option 'mode' with value 'level=42'
         -mode=level:42      > identifies option 'mode' with value 'level:42'
         -mode:level:42      > identifies option 'mode' with value 'level:42'
         -mode=level=42      > identifies option 'mode' with value 'level=42'
  }
  begin
    result := Deltics.Smoketest.Utils.HasCmdLineOption(fCmdLineArgs, aName, aValue);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.Test(const aTest: TTestClass;
                          const aNamePrefix: String);
  {
    Identifies and executes test methods on the specified class.

    The outcome of tests performed by each test method is recorded on the test
     run by the Assert() mechanisms implemented in the Test class and called
     during the execution of each method.
  }

    procedure PerformMethod(const aMethod: TTestMethod;
                            const aMessage: String;
                                  aIndent: Integer);
    var
      indent: String;
    begin
      if NOT Assigned(aMethod) then
        EXIT;

      indent := StringOfChar(' ', aIndent);
      if fVerboseOutput and (aMessage <> '') then
        WriteLn(indent + aMessage);

      try
        aMethod;

      except
        on e: Exception do
          WriteLn(indent + Format('  ERROR [%s]: %s', [e.ClassName, e.Message]));
      end;
    end;

  var
    i: Integer;
    test: TTest;
    methods: TStringList;
    method: TTestMethod;
    resultCountBeforeMethodRan: Integer;
    setupTest: TTestMethod;
    setupMethod: TTestMethod;
    teardownMethod: TTestMethod;
    teardownTest: TTestMethod;
  begin
    if IsFinished then
    begin
      WriteLn(Format('WARNING: Methods in test class %s not performed as TestRun has already finished', [aTest.ClassName]));
      EXIT;
    end;

    if NOT IsRunning then
      BeginRun;

    test    := aTest.Create;
    methods := TStringList.Create;
    try
      SetTestType(test.ClassName);
      SetTestNamePrefix(aNamePrefix);

      if (fVerboseOutput) then
        EmitTypeName;

      TTestHelper(test).GetTestMethods(methods);

      if methods.Count = 0 then
      begin
        WriteLn(Format('WARNING: Test class %s implements no test methods', [fTypeName]));
        fLineFeedBeforeTypeNameOrSummary := TRUE;
        EXIT;
      end;

      setupTest       := ExtractMethod(test, methods, 'SetupTest');
      setupMethod     := ExtractMethod(test, methods, 'SetupMethod');
      teardownMethod  := ExtractMethod(test, methods, 'TeardownMethod');
      teardownTest    := ExtractMethod(test, methods, 'TeardownTest');

      PerformMethod(setupTest, 'Setup Test', 2);
      try
        for i := 0 to Pred(methods.Count) do
        begin
          SetTestMethod(methods[i]);

          TMethod(method).Data := test;
          TMethod(method).Code := test.MethodAddress(methods[i]);

          resultCountBeforeMethodRan := Results.Count;
          try
            PerformMethod(setupMethod, 'Setup ' + methods[i], 4);
            try
              if (fVerboseOutput) then
                EmitMethodName;

              try
                method;

                if Assigned(fExpectedException) then
                begin
                  if fExpectedException.NoneExpected then
                    TestPassed('No exception raised')
                  else
                    TestFailed(fExpectedException.TestName, 'Expected exception was not raised');
                end;

              except
                on e: Exception do
                  TestError(e);
              end;

            finally
              fExpectedException  := NIL;
              fSelfTest           := NIL;

              PerformMethod(teardownMethod, 'Teardown ' + methods[i], 4);
            end;

          finally
            if fTestsExpected and (Results.Count = resultCountBeforeMethodRan) then
            begin
              WriteLn(Format('WARNING: Test method %s.%s did not perform any tests', [fTypeName, fMethodName]));
              fLineFeedBeforeTypeNameOrSummary := TRUE;
            end;

            SetTestMethod('');
          end;
        end;

      finally
        PerformMethod(teardownTest, 'Teardown Test', 2);
      end;

    finally
      SetTestNamePrefix('');
      SetTestType('');

      methods.Free;
      test.Free;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TTestRun.Test(const aTests: array of TTestClass;
                          const aNamePrefix: String);
  {
    Executes test methods on one or more identified test classes.
  }
  var
    i: Integer;
  begin
    for i := 0 to High(aTests) do
      Test(aTests[i], aNamePrefix);
  end;




initialization
  TestRun := TTestRun.Create;

finalization
  try
    if Assigned(TestRun) and NOT TestRun.IsFinished then
      TestRun.Complete;

  finally
    TestRun.Free;
  end;
end.
