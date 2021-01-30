{
  * MIT LICENSE *

  Copyright � 2020 Jolyon Smith

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

  unit Deltics.Smoketest.Assertions.Interface_;


interface

  uses
    Deltics.Smoketest.Assertions;


  type
    InterfaceAssertions = interface
    ['{61FD3055-26C8-42F0-AB74-527E3613DB83}']
      function DoesNotEqual(const aExpected: IUnknown): AssertionResult;
      function Equals(const aExpected: IUnknown): AssertionResult;
      function Supports(const aIID: TGuid): AssertionResult;
      function IsAssigned: AssertionResult;
      function IsNIL: AssertionResult;
      function IsNotNIL: AssertionResult;
    end;


    TInterfaceAssertions = class(TAssertions, InterfaceAssertions)
    private
      fValue: IUnknown;
      function DoesNotEqual(const aExpected: IUnknown): AssertionResult;
      function Equals(const aExpected: IUnknown): AssertionResult; reintroduce;
      function Supports(const aIID: TGuid): AssertionResult; reintroduce;
      function IsAssigned: AssertionResult;
      function IsNIL: AssertionResult;
      function IsNotNIL: AssertionResult;
    public
      constructor Create(const aTestName: String; const aValue: IUnknown);
    end;


implementation

  uses
    Classes,
    SysUtils,
    Deltics.Smoketest.Utils;



{ TInterfaceAssertions ----------------------------------------------------------------------------- }

  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  constructor TInterfaceAssertions.Create(const aTestName: String;
                                          const aValue: IUnknown);
  begin
    inherited Create(aTestName, '<interface@' + BinToHex(@aValue, sizeof(Pointer)) + '>');

    fValue := aValue as IUnknown;
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.DoesNotEqual(const aExpected: IUnknown): AssertionResult;
  begin
    FormatExpected('<interface@' + BinToHex(@aExpected, sizeof(Pointer)) + '>');

    Description := Format('{valueName} does not = {expected}');
    Failure     := Format('{valueWithName} = {expected}');

    result := Assert(fValue <> (aExpected as IUnknown));
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.Equals(const aExpected: IUnknown): AssertionResult;
  begin
    FormatExpected('<interface@' + BinToHex(@aExpected, sizeof(Pointer)) + '>');

    Description := Format('{valueName} = {expected}');
    Failure     := Format('{valueWithName} does not = {expected}');

    result := Assert(fValue = (aExpected as IUnknown));
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.Supports(const aIID: TGuid): AssertionResult;
  begin
    FormatExpected(GUIDToString(aIID));

    Description := Format('{valueName} supports interface {expected}');
    Failure     := Format('{valueWithName} does support interface {expected}');

    result := Assert(SysUtils.Supports(fValue, aIID));
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.IsAssigned: AssertionResult;
  begin
    Description := Format('{valueWithName} is assigned (not NIL)');
    Failure     := Format('{valueWithName} is NIL');

    result := Assert(Assigned(fValue));
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.IsNIL: AssertionResult;
  begin
    Description := Format('{valueWithName} is NIL');
    Failure     := Format('{valueWithName} is not NIL');

    result := Assert(fValue = NIL);
  end;


  {-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --}
  function TInterfaceAssertions.IsNotNIL: AssertionResult;
  begin
    Description := Format('{valueWithName} is NOT NIL');
    Failure     := Format('{valueWithName} is NIL');

    result := Assert(fValue <> NIL);
  end;



end.
