unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,Registry;

type
  TForm2 = class(TForm)
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Button1: TButton;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

function GetLanguage : string;
Var
 Language:string;
 Registre       : TRegistry;
 begin
    Registre:=TRegistry.Create;
    Registre.RootKey:=HKEY_CURRENT_USER;
    Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename',False);
    GetLanguage:=Registre.ReadString('Language');
    Registre.Free;
end;

procedure TForm2.Button1Click(Sender: TObject);
var
 Language:  string;
 Registre       : TRegistry;
begin
    Registre:=TRegistry.Create;
    Registre.RootKey:=HKEY_CURRENT_USER;
    Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename',False);
    if RadioButton1.Checked then Registre.WriteString('Language','FR');
    if RadioButton2.Checked then Registre.WriteString('Language','EN');
    Registre.Free;
    self.Close
end;


procedure TForm2.FormShow(Sender: TObject);
begin
  Left:=(Screen.Width-Width)  div 2;
  Top:=(Screen.Height-Height) div 2;
  if GetLanguage='FR' then RadioButton1.Checked:=true;
  if GetLanguage='EN' then RadioButton2.Checked:=true;
end;

end.
