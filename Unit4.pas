unit Unit4;

interface
uses   Windows, SysUtils, forms,registry ;


 function LoadStringLanguage(number:integer):string;
 function GetLanguage : string;


implementation


function GetLanguage : string;
Var
 Registre       : TRegistry;
 begin
    Registre:=TRegistry.Create;
    Registre.RootKey:=HKEY_CURRENT_USER;
    Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename',False);
    GetLanguage:=Registre.ReadString('Language');
    Registre.Free;
end;

function LoadStringLanguage(number:integer):string;
var
a : array[0..255] of char;
StrTblOfs : integer;
begin
  StrTblOfs := 0;
  if GetLanguage = 'EN' then StrTblOfs := 0;
  if GetLanguage = 'FR' then StrTblOfs := 50;
 //Input mask string (lang)
  if LoadString(hInstance,StrTblOfs + number,a,sizeof(a)) <> 0 then
    LoadStringLanguage:= StrPas(a);

end;


end.
