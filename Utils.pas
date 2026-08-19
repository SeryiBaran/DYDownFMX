unit Utils;

interface

uses
  SysUtils, StrUtils;

function ContainsAnySubstring(const Strings, SearchTerms: array of string): Boolean;

implementation

function ContainsAnySubstring(const Strings, SearchTerms: array of string): Boolean;
var
  S, Term: string;
begin
  for S in Strings do
    for Term in SearchTerms do
      if ContainsText(S, Term) then  // или Pos(Term, S) > 0
        Exit(True);
  Result := False;
end;

end.
