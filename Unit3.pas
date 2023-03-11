unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,registry,Exif, ComCtrls,unit4;

type
  TForm3 = class(TForm)
    Edit_Patern: TEdit;
    btt_cancel: TButton;
    btt_ok: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Edit_Filename: TEdit;
    chk_Date: TCheckBox;
    chk_Time: TCheckBox;
    chk_numerical: TCheckBox;
    Btt_genpatern: TButton;
    Label2: TLabel;
    ProgressBar1: TProgressBar;
    chk_prev: TCheckBox;
    ListView_prev: TListView;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btt_cancelClick(Sender: TObject);
    procedure Edit_PaternExit(Sender: TObject);
    procedure btt_okClick(Sender: TObject);
    procedure chk_numericalClick(Sender: TObject);
    procedure chk_TimeClick(Sender: TObject);
    procedure chk_DateClick(Sender: TObject);
    procedure Btt_genpaternClick(Sender: TObject);
    procedure chk_prevClick(Sender: TObject);
    procedure preview;
    type
   // Declare a customer record
   PhotoType = Record
      filename : string;
      ssdate  : string;
      order : integer;
      orderDate : integer;
      samedate : Boolean;
   end;
   photarrtyp=array of PhotoType;
  private
    { Private declarations }
  public
    Photos : tform3.photarrtyp;
    previous_patern:string;

  constructor passinfo(listeitems: ComCtrls.TListitems;ph:photarrtyp; Owner: TComponent;ypath:string;ycheck_exif:boolean);
    { Public declarations }
  end;



var
  Form3: TForm3;
  Registre       : TRegistry;
  PhotosItems : ComCtrls.TListitems;
     path:string;
    check_exif:boolean;

implementation

{$R *.dfm}

constructor TForm3.passinfo(listeitems: ComCtrls.TListitems;ph:photarrtyp; Owner: TComponent;ypath:string;ycheck_exif:boolean);
begin
  PhotosItems:= listeitems;
  photos:=ph;
  path:=ypath;
  check_exif:=ycheck_exif;
end;



function string_digit(digit,nbr:integer):string ;
var nbr_digit : integer;
  begin
  nbr_digit:=0;
      while nbr>=10 do
      begin
       nbr_digit:=nbr_digit+1;
       nbr:=nbr div 10;
      end;
   Result:= StringOfChar('0',digit-nbr_digit)

  end;



 procedure TForm3.preview;
   var
//Photos : Tform3.photarrtyp;

aax,ax,bbx,bx,count,countselected,digit,decplus: Integer;s : string;
JPegName,Sdate,newfilename:string;
ExifImage : TExif;
ImageSource:Tgraphic;
Tmpbitmap: Tbitmap;
AFormat: Word;
AData: THandle;
APalette: HPALETTE;
TFF:boolean;
Registre       : TRegistry;
errorcode : Boolean;
inc_retry :integer;
rf: TForm3;
NewItem : Tlistitem;
dummy:integer;
BEGIN
  listview_prev.Clear;
  previous_patern:=Edit_patern.Text;
  countselected:=0; digit:=0;
  ProgressBar1.Min:=0; ProgressBar1.Position:=0;
  SetLength(Photos,PhotosItems.Count);
  s:='';
   for ax := 0 to PhotosItems.Count-1 do
   begin
      if PhotosItems.Item[ax].Selected then begin
      countselected:=countselected+1;
      ProgressBar1.Max:=countselected;
//      s:= s + #10#13 + '(' +ListView1.Items.Item[ax].caption + ') -> ' + ShellTreeView1.Path + '\' + ListView1.Items.Item[ax].caption;
      JPegName:=Path + '\' + PhotosItems.Item[ax].caption;

      //      s:= s + ListView1.Items.Item[ax].caption + chr(9) + ' -> ' + 'Date prise de vue = '+ ExifImage.DateTimeOriginal + chr(9) + ' File date : ' +  DateToStr(FileDateToDateTime(FileAge(JPegName))) +  chr(9) + TimeToStr(FileDateToDateTime(FileAge(JPegName))) + chr(13);
      if check_exif then begin
      ExifImage := TExif.Create;
      ExifImage.ReadFromFile(JPegName);
      Sdate:=ExifImage.DateTimeOriginal;
      ExifImage.Free;
      end;
      if Sdate<>'?' then Sdate:=copy(Sdate,9,2) + '/' + copy(Sdate,6,2)+ '/' + copy(Sdate,1,4) + '_' + copy(Sdate,12,8);
      if (check_exif=false) or (Sdate='?') then
      Sdate:=DateToStr(FileDateToDateTime(FileAge(JPegName))) +  '_' + TimeToStr(FileDateToDateTime(FileAge(JPegName)));
//      Sdate:= StringReplace(Sdate,'/','-',[rfReplaceAll, rfIgnoreCase]);
      Sdate:= StringReplace(Sdate,':','.',[rfReplaceAll, rfIgnoreCase]);
      Sdate:=copy(Sdate,7,4)+'-'+copy(Sdate,4,2)+'-'+copy(Sdate,1,2)+'_'+copy(Sdate,12,8);

      Photos[Ax].filename:= PhotosItems.Item[ax].caption;
      Photos[Ax].ssdate:=Sdate;


 //     s:= s + ListView1.Items.Item[ax].caption + chr(9) + ' -> ' + 'Date prise de vue = '+ Sdate + chr(13);

      end;
      Sdate:='';
      ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
    end;
  //      MessageBox(0,PChar(s),'Infos',MB_OK);
{
  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
  newfilename:=Registre.ReadString('Patern');
  Registre.Free;
}
    newfilename:=Edit_Patern.Text;

  //if InputQuery('Rename',LoadStringLanguage(10), newfilename) then
 //   BEGIN
       // ProgressBar1.Step:=countselected div 10;
      dummy:=countselected;
      while dummy>=10 do
        begin
         digit:=digit+1;
         dummy:=dummy div 10;
        end;

//    --- order general (*)
          ProgressBar1.Position:=0;
           for ax := 0 to PhotosItems.Count-1 do
          if PhotosItems.Item[ax].Selected then Photos[ax].samedate:=false;

          count:=1;
          for ax := 0 to PhotosItems.Count-1 do
          if PhotosItems.Item[ax].Selected then
           BEGIN
            for bx := 0 to PhotosItems.Count-1 do
              if PhotosItems.Item[bx].Selected then
              begin
                if Photos[ax].ssdate > Photos[bx].ssdate then count:=count+1;
                if (Photos[ax].ssdate = Photos[bx].ssdate) and (Photos[bx].samedate=false) then begin count:=count+1;Photos[ax].samedate:=true;end; // recherche date identique technique astuce :D
              end;
             Photos[ax].order:=count-1;
             count:=1;
             Photos[ax].orderDate:=1; //init 1... orderdate  (profiteur)
             ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
           END;

//    --- order DATE (? + *)
         if (StrScan(PChar(newfilename),'?') <> nil) then begin
             ProgressBar1.Position:=0;
             for ax := 2 to PhotosItems.Count   do
             for bx := 0 to PhotosItems.Count-1  do
             if Photos[bx].order=ax then
              for bbx :=0  to PhotosItems.Count-1  do                   // recherche date identique technique boucle
               if Photos[bbx].order=ax-1  then                BEGIN
                 if copy(Photos[bbx].ssdate,1,10)=copy(Photos[bx].ssdate,1,10) then Photos[bx].orderDate:=1+Photos[bbx].orderDate ;
                   // fo un break plus rapid.. c trouV   aie bug!! arevoir
                ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
             END;
         end;
    //MessageBox(0,PChar(s),'Infos',MB_OK);

 ProgressBar1.Position:=0;
  for ax := 0 to PhotosItems.Count-1 do
      if PhotosItems.Item[ax].Selected then
      BEGIN
// only *
        if (StrScan(PChar(newfilename),'*') <> nil) and (StrScan(PChar(newfilename),'?') = nil) and (StrScan(PChar(newfilename),'%') = nil) then
           s:= StringReplace(newfilename,'*',string_digit(digit,Photos[ax].order)+ IntToStr(Photos[ax].order),[])+'.jpg';
// DATE + TIME
        if (StrScan(PChar(newfilename),'*') = nil) and (StrScan(PChar(newfilename),'?') <> nil) and (StrScan(PChar(newfilename),'%') <> nil) then
          s:= StringReplace(StringReplace(newfilename,'?',copy(Photos[ax].ssdate,1,10),[rfReplaceAll, rfIgnoreCase]),'%',copy(Photos[ax].ssdate,12,8),[rfReplaceAll, rfIgnoreCase])+'.jpg';
// DATE + *
        if (StrScan(PChar(newfilename),'*') <> nil) and (StrScan(PChar(newfilename),'?') <> nil) and (StrScan(PChar(newfilename),'%') = nil) then
          s:= StringReplace(StringReplace(newfilename,'?',copy(Photos[ax].ssdate,1,10),[rfReplaceAll, rfIgnoreCase]),'*',string_digit(digit,Photos[ax].orderDate)+ IntToStr(Photos[ax].orderDate),[rfReplaceAll, rfIgnoreCase])+'.jpg';

       //=s+newfilename+string_digit(digit,Photos[ax].order)+ IntToStr(Photos[ax].order)+chr(13);
NewItem := listview_prev.Items.Add;
NewItem.Caption := Pchar(s);
ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
    END; //fini preview renomage

 END;



procedure TForm3.chk_prevClick(Sender: TObject);
begin
if chk_prev.Checked then
 begin
  listview_prev.visible:=true;
  preview;
  end
 else listview_prev.visible:=false;

end;

procedure TForm3.Btt_genpaternClick(Sender: TObject);
//var newfilename : string;
begin

  //newfilename:=edit_filename+'*';

// only *
        if (chk_numerical.Checked=true) and (not chk_date.Checked) and (not chk_time.Checked) then
         edit_patern.Text:=edit_filename.Text+' *' else
// DATE + TIME
        if (not chk_numerical.Checked) and (chk_date.Checked) and (chk_time.Checked) then
         edit_patern.Text:=edit_filename.Text+' ?-%' else
// DATE + *
       if (chk_numerical.Checked) and (chk_date.Checked) and (not chk_time.Checked) then
        edit_patern.Text:=edit_filename.Text+' ?_*' else
        edit_patern.Text:='erreur';
 if chk_prev.Checked and (previous_patern<>Edit_patern.Text) then
 begin
  listview_prev.visible:=true;
  preview;
 end

end;

procedure TForm3.chk_DateClick(Sender: TObject);
begin
 if not chk_Date.Checked then chk_Time.Checked:=false;
 if chk_Date.Checked then chk_numerical.Checked:=true;
end;

procedure TForm3.chk_TimeClick(Sender: TObject);
begin
if chk_Time.Checked then
  begin
    chk_date.Checked:=true;
    chk_numerical.Checked:=false;
  end else chk_numerical.Checked:=true;
end;

procedure TForm3.chk_numericalClick(Sender: TObject);
begin
if chk_numerical.Checked then
  begin
    if chk_time.Checked then chk_time.Checked:=false;
  end
  else
  chk_time.Checked:=true;

end;

procedure TForm3.btt_okClick(Sender: TObject);
begin
  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
  Registre.WriteString('Patern',Edit_patern.Text);
  Registre.Free;
  self.ModalResult:=80;
end;

procedure TForm3.Edit_PaternExit(Sender: TObject);
begin

if chk_prev.Checked and (previous_patern<>Edit_patern.Text) then
 begin
  listview_prev.visible:=true;
  preview;
  end
end;


procedure TForm3.btt_cancelClick(Sender: TObject);
begin
 self.close;
end;

procedure TForm3.FormActivate(Sender: TObject);
begin

  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
  Edit_Patern.Text :=Registre.ReadString('Patern');
  Registre.Free;

  ProgressBar1.Min:=0; // ProgressBar1.Step:=countselected div 10;

preview;
end;

procedure TForm3.FormShow(Sender: TObject);
begin
  Left:=(Screen.Width-Width)  div 2;
  Top:=(Screen.Height-Height) div 2;
  GroupBox1.Caption:=LoadStringLanguage(20);
  label1.Caption:=LoadStringLanguage(21);
  chk_date.Caption:=LoadStringLanguage(22);
  chk_time.Caption:=LoadStringLanguage(23);
  chk_numerical.Caption:=LoadStringLanguage(24);
  Btt_genpatern.Caption:=LoadStringLanguage(25);
  label2.Caption:=LoadStringLanguage(26);
  chk_prev.Caption:=LoadStringLanguage(27);
  btt_cancel.Caption:=LoadStringLanguage(28);
  btt_ok.Caption:=LoadStringLanguage(29);



end;

end.


