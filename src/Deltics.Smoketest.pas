
{$i Deltics.Smoketest.inc}

  unit Deltics.Smoketest;

interface

  uses
    Deltics.Smoketest.Test,
    Deltics.Smoketest.TestRun,
    Deltics.Smoketest.Utils;

  // Elevate the scope of the TTest class so that test class implementation units
  //  need only reference Deltics.Smoketest.
  type
    TTest = Deltics.Smoketest.Test.TTest;
    TSelfTest = Deltics.Smoketest.Test.TSelfTest;
    EInvalidTest = Deltics.Smoketest.Utils.EInvalidTest;


  // This function provides read-only access to the TestRun variable maintained
  //  in the TestRun implementation unit.
  function TestRun: TTestRun;


  const
    DELPHI_VERSION = {$ifdef VER80}  '1' {$endif}
                     {$ifdef VER90}  '2' {$endif}
                     {$ifdef VER100} '3' {$endif}
                     {$ifdef VER120} '4' {$endif}
                     {$ifdef VER130} '5' {$endif}
                     {$ifdef VER140} '6' {$endif}
                     {$ifdef VER150} '7' {$endif}
                     {$ifdef VER160} '8' {$endif}

                     {$ifdef VER170} '2005' {$endif}
                     {$ifdef VER180} // VER180 is defined for both Delphi 2006 and 2007
                       {$ifdef VER185}
                         '2007'
                       {$else}
                         '2006'
                       {$endif}
                     {$endif}
                     {$ifdef VER200} '2009' {$endif}
                     {$ifdef VER210} '2010' {$endif}

                     {$ifdef VER220} 'xe'  {$endif}
                     {$ifdef VER230} 'xe2' {$endif}
                     {$ifdef VER240} 'xe3' {$endif}
                     {$ifdef VER250} 'xe4' {$endif}
                     {$ifdef VER260} 'xe5' {$endif}
                     {$ifdef VER270} 'xe6' {$endif}
                     {$ifdef VER280} 'xe7' {$endif}
                     {$ifdef VER290} 'xe8' {$endif}

                     {$ifdef VER300} '10'   {$endif}
                     {$ifdef VER310} '10.1' {$endif}
                     {$ifdef VER320} '10.2' {$endif}
                     {$ifdef VER330} '10.3' {$endif};

    DELPHI_VERSION_NAME = {$ifdef VER80}  '1' {$endif}
                          {$ifdef VER90}  '2' {$endif}
                          {$ifdef VER100} '3' {$endif}
                          {$ifdef VER120} '4' {$endif}
                          {$ifdef VER130} '5' {$endif}
                          {$ifdef VER140} '6' {$endif}
                          {$ifdef VER150} '7' {$endif}
                          {$ifdef VER160} '8' {$endif}

                          {$ifdef VER170} '2005' {$endif}
                          {$ifdef VER180} // VER180 is defined for both Delphi 2006 and 2007
                            {$ifdef VER185}
                              '2007'
                            {$else}
                              '2006'
                            {$endif}
                          {$endif}
                          {$ifdef VER200} '2009' {$endif}
                          {$ifdef VER210} '2010' {$endif}

                          {$ifdef VER220} 'XE'  {$endif}
                          {$ifdef VER230} 'XE2' {$endif}
                          {$ifdef VER240} 'XE3' {$endif}
                          {$ifdef VER250} 'XE4' {$endif}
                          {$ifdef VER260} 'XE5' {$endif}
                          {$ifdef VER270} 'XE6' {$endif}
                          {$ifdef VER280} 'XE7' {$endif}
                          {$ifdef VER290} 'XE8' {$endif}

                          {$ifdef VER300} '10 Seattle' {$endif}
                          {$ifdef VER310} '10.1 Berlin'{$endif}
                          {$ifdef VER320} '10.2 Tokyo' {$endif}
                          {$ifdef VER330} '10.3 Rio'   {$endif};



implementation

  // NOTE: Ensure that results writer implementations are added to the uses clause!
  uses
    Deltics.Smoketest.ResultsWriter.XUnit2;


  function TestRun: TTestRun;
  begin
    result := Deltics.Smoketest.TestRun.TestRun;
  end;


end.
