unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, ImgList, ShellCtrls, Jpeg,Exif, ToolWin,
  ActnMan, ActnCtrls, ExtActns, StdActns, ActnList, ActnMenus, XPStyleActnCtrls,Registry,
  Unit2,Unit3,unit4,CommCtrl;

type
  TMyListView = class(TListView)
  protected
    procedure WndProc(var Message: TMessage);
      override;
  end;
  //end;
  TForm1 = class(TForm)
    ImageList1: TImageList;
    ShellTreeView1: TShellTreeView;
    Splitter1: TSplitter;
    ActionManager1: TActionManager;
    ActionMainMenuBar1: TActionMainMenuBar;
    ActionToolBar1: TActionToolBar;
    Arefresh: TAction;
    ImageList2: TImageList;
    Select_all: TAction;
    Select_none: TAction;
    BrowseURL1: TBrowseURL;
    About: TAction;
    use_exif: TCheckBox;
    A_rename: TAction;
    StatusBar1: TStatusBar;
    ProgressBar1: TProgressBar;
    A_language: TAction;
    procedure ListView1_prevDblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure A_languageExecute(Sender: TObject);
    procedure ShellTreeView1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure A_renameExecute(Sender: TObject);
    procedure ListView1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Select_noneExecute(Sender: TObject);
    procedure ArefreshExecute(Sender: TObject);
    procedure Select_allExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadFiles();
    procedure RefreshLanguage();
    procedure refresh_statusbar();
    procedure TraiteMessage(var Msg: TMsg; var Handled: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure ListView1CustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ShellTreeView1Change(Sender: TObject; Node: TTreeNode);
  private
    { Private êÈåæ }
    FTmpStream: TFileStream;    // èkè¨âÊëúÇï€ä«Ç∑ÇÈÉXÉgÉäÅ[ÉÄ
    FSeekPosition: TStringList; // èkè¨âÊëúÇÃSeekà íuÅi-1:ì«çûé∏îs 0>:Seekà íuÅj
    FFileList: TStringList;     // ÉtÉ@ÉCÉãñº
    ListView1: TMyListView;
    procedure LVBGImage;
    procedure CreateThumbnail(Path: String);
  public
    { Public êÈåæ }

  end;

var
  Form1: TForm1;
  Version: string;

implementation

uses ShellAPI, ImageExtract, ComObj;

{$R *.DFM}
//{$R stringtable.res}
type
  TLVBKIMAGE = packed record
    ulFlags : longint;
    hbm     : HBitmap;
    pszImage: PChar;
    cchImageMax : word;
    xOffsetPercent : integer;
    yOffsetPercent : integer;
  end;
const
  CLR_NONE = $FFFFFFFF;
  LVM_FIRST = $1000;
  LVM_SETTEXTBKCOLOR = (LVM_FIRST + 38);
  LVM_SETBKIMAGE = (LVM_FIRST + 68);

  LVBKIF_SOURCE_NONE = 0;
  LVBKIF_SOURCE_HBITMAP = 1;
  LVBKIF_SOURCE_URL = 2;
  LVBKIF_SOURCE_MASK = 3;
  LVBKIF_STYLE_NORMAL = 0;
  LVBKIF_STYLE_TILE = 16;
  LVBKIF_STYLE_MASK = 16;

procedure TmyListView.WndProc(var Message: TMessage);
begin
  if Message.msg = WM_ERASEBKGND then
    DefaultHandler(Message)
  else
    inherited WndProc(Message);
end;

procedure TForm1.TraiteMessage(var Msg: TMsg; var Handled: Boolean); // Dans FormCreate, on a mis Application.OnMessage := TraiteMessage;
// c'est donc cette procÈdure qui est appelÈe ‡ chaque fois que se dÈclenche l'ÈvËnement OnMessage (c'est ‡ dire ‡ chaque fois que Windows envoie un message ‡ l'application)
// faire attention cette procÈdure est appelÈ trËs souvent par Windows d'o˘ le if dÈs le dÈpart.
var
  NombreDeFichiers,size,i:integer;
  NomDuFichierStr:string;
  NomDuFichier:array[0..255] of char;


begin
  if Msg.message=WM_DROPFILES then
  begin
    NombreDeFichiers:= DragQueryFile( Msg.wParam, $FFFFFFFF, NomDuFichier, sizeof(NomDuFichier));// rÈcupÈration du nombre de fichiers
 //   for i:=0 to NombreDeFichiers-1 do
//    begin
      size:= DragQueryFile( Msg.wParam, 0, NomDuFichier, sizeof(NomDuFichier) );// rÈcupÈration du nom du fichier
      NomDuFichierStr:=NomDuFichier; // tansformation du tableau de char en STRING
     // DragQueryPoint(Msg.wParam,PointDuLache); // rÈcupÈration du point de lachÈ
  //    Memo1.Lines.add(NomDuFichierStr); //+' X='+IntToStr(PointDuLache.x)+' Y='+ IntToStr(PointDuLache.y));
      //DessineIcone(NomDuFichier,PointDuLache);

      if DirectoryExists(NomDuFichierStr) then ShelltreeView1.Path:=NomDuFichierStr;
//    end;
    end;
end;


//****************************************
// ÉTÉÄÉlÉCÉãÇÉtÉ@ÉCÉãÉXÉgÉäÅ[ÉÄè„Ç…çÏê¨
//****************************************
procedure TForm1.CreateThumbnail(Path: String);
var
  I: Integer;
  FilePath: String;
  SeekPos: Integer;
  AWidth, AHeight, bmpWidth, bmpHeight, HMargin, VMargin: Integer;
  Bmp: TBitmap;
  SHFileInfo: TSHFileInfo;
  IconHandle: HICON;
begin
  FTmpStream.Size := 0;
  FSeekPosition.Clear;

  // ï`âÊóÃàÊÇÃëÂÇ´Ç≥
  AWidth := ListView1.LargeImages.Width;
  AHeight := ListView1.LargeImages.Height;

  if ListView1.Items.Count <>0 then begin
  ProgressBar1.Min:=0; ProgressBar1.Max:=ListView1.Items.Count -1;
  end;
  for I := 0 to ListView1.Items.Count -1 do
  begin
    if ListView1.Items.Count <>0 then
    Begin
    ProgressBar1.Position:=I;
    StatusBar1.Panels[1].text:=inttostr(I+1)+'/'+inttostr(ListView1.Items.Count)+' - '+ LoadStringLanguage(11);
    end;
      StatusBar1.Refresh;
    FSeekPosition.Add('-1');
    // èkè¨âÊëúçÏê¨
    FilePath := Path + '\' + FFileList[I];
    Bmp := TBitmap.Create;
    try
      Bmp.Width := AWidth;
      Bmp.Height :=AHeight;
      if ExtractImage(FilePath, Bmp) = False then
      begin
        Continue;
      end;

      // èkè¨âÊëúÇ∆ÇªÇÃà íuÇï€ë∂
      SeekPos := FTmpStream.Size;
      FSeekPosition.Strings[I] := IntToStr(SeekPos);
      FTmpStream.Seek(0, soFromEnd);
      Bmp.SaveToStream(FTmpStream);
    finally
      Bmp.Free;
    end;
      if ListView1.Items.Count <>0 then ProgressBar1.Position:=0;
  end;
   refresh_statusbar;
end;


procedure installer;
var
 Language:string;
 Registre       : TRegistry;
begin
    Registre:=TRegistry.Create;
    Registre.RootKey:=HKEY_CURRENT_USER;
If not(Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', false))
then
 Begin //-- si pas installÈ du tout ou changÈ chemin
      // chemin
      Registre.CloseKey();
      Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
      Registre.WriteString('Language','EN');
      Registre.WriteString('Patern','Photo *');
      Registre.Free;
     with  TForm2.Create(Form1) do ShowModal;
     Form1.RefreshLanguage;
   end;
end;


procedure TForm1.RefreshLanguage;
var
a : array[0..255] of char;
StrTblOfs : integer;
begin
  StrTblOfs := 0;
  if GetLanguage = 'EN' then StrTblOfs := 0;
  if GetLanguage = 'FR' then StrTblOfs := 50;
//----------
//Use exif
  if LoadString(hInstance,StrTblOfs + 1,a,sizeof(a)) <> 0 then
    use_exif.Caption  := StrPas(a);
//deselect
  if LoadString(hInstance,StrTblOfs + 2,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[0].Items.ActionClients[5].Caption:=  StrPas(a);
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[0].Items.ActionClients[1].Caption:=  StrPas(a);
//select all
  if LoadString(hInstance,StrTblOfs + 3,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[0].Items.ActionClients[4].Caption:=  StrPas(a);
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[0].Items.ActionClients[0].Caption:=  StrPas(a);
// Refresh
  if LoadString(hInstance,StrTblOfs + 4,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[0].Items.ActionClients[2].Caption:=  StrPas(a);
// Rename
  if LoadString(hInstance,StrTblOfs + 5,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[0].Items.ActionClients[0].Caption:=  StrPas(a);
// Edit
  if LoadString(hInstance,StrTblOfs + 6,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[0].Caption:=  StrPas(a);
// Help
  if LoadString(hInstance,StrTblOfs + 7,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[1].Caption:=  StrPas(a);
//Online Help
  if LoadString(hInstance,StrTblOfs + 8,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[1].Items.ActionClients[0].Caption:=  StrPas(a);
//Choose language
  if LoadString(hInstance,StrTblOfs + 9,a,sizeof(a)) <> 0 then
    ActionManager1.ActionBars.ActionBars[1].Items.ActionClients[0].Items.ActionClients[2].Caption:=  StrPas(a);


//----------
end;

procedure TForm1.LVBGImage;
var
  BKimg : TLVBKIMAGE;
      bmpfond:Tbitmap;
      Res: TResourceStream;
      Jpeg: TJpegImage;
begin
  FillChar(BKimg, SizeOf(BKimg), 0);

  BKimg.ulFlags := LVBKIF_SOURCE_URL  or LVBKIF_STYLE_TILE;
//BKimg.ulFlags := LVBKIF_SOURCE_HBITMAP  or LVBKIF_STYLE_TILE;
    bmpfond := TBitmap.Create;
    bmpfond.Width := 466;
    bmpfond.Height :=416;
    Res:=TResourceStream.Create(0,'IMAGE001','JPG');
    Jpeg:=TJpegImage.Create;
    Jpeg.LoadFromStream(res);
    bmpfond.Canvas.StretchDraw(bmpfond.Canvas.ClipRect,Jpeg);
      //if ExtractImage('C:\Documents and Settings\Lenny\Bureau\Crofoname\fond.jpg', bmpfond) = False then
  //    begin
   //     Continue;

    //  end;
 bmpfond.SaveToFile(GetEnvironmentVariable('TEMP')+'\fondexport.bitmap');
 BKimg.pszImage := PChar(GetEnvironmentVariable('TEMP')+'\fondexport.bitmap');

  BKimg.xOffsetPercent := 0;
  BKimg.yOffsetPercent := 0;
  SendMessage(listview1.Handle, LVM_SETTEXTBKCOLOR, 0, CLR_NONE);
  SendMessage(listview1.Handle, LVM_SETBKIMAGE, 0, integer(@BKimg));
end;

procedure TForm1.FormCreate(Sender: TObject);
BEGIN

ListView1 := TMyListView.Create(Self);
  with ListView1 do
  begin
    Parent := Self;
    Left := 183;
    Top := 70;
    Width := 485;
    //ViewStyle:=vsList;
    Height := 418;
    Align := alClient;
    LargeImages := ImageList1;
    SmallImages := ImageList1;
    Font.Charset := ANSI_CHARSET;
    Font.Color := clWindowText;
    Font.Height := -9;
    Font.Name := 'MS P????';
    Font.Style := [];
    Font.Size:=9;
    IconOptions.AutoArrange := false;
    MultiSelect := True;
    OwnerData := True;
    OwnerDraw := True;
    ParentFont := False;
    TabOrder := 0;
    OnChange := ListView1Change;
    OnCustomDrawItem := ListView1CustomDrawItem;
    OnData := ListView1Data;
    OnKeyUp := ListView1KeyUp;
    OnDblClick:=ListView1_prevDblClick;
  end;
  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', false);
  If Registre.ValueExists('TreeViewWhidth') then ShellTreeView1.Width:=Registre.ReadInteger('TreeViewWhidth');
  If Registre.ValueExists('WindowState') then form1.WindowState:=TWindowState(Registre.ReadInteger('WindowState'));
  If Registre.ValueExists('Width') then self.Width:=Registre.ReadInteger('Width');
  If Registre.ValueExists('Height') then self.Height:=Registre.ReadInteger('Height');

  Registre.Free;


  Version:='1.06';
  Form1.Caption:='Crofoname '+ version;
  Left:=(Screen.Width-Width)  div 2;
  Top:=(Screen.Height-Height) div 2;

  RefreshLanguage;
  LVBGImage;
  FTmpStream := TFileStream.Create(GetEnvironmentVariable('TEMP') +'\Crofoname-FTmpStream.dat', fmCreate);
  FSeekPosition := TStringList.Create;
  FFileList := TStringList.Create;

   // indique la fenÍtre o˘ pourra se faire le lachÈ. On peut y mettre tout type de fenÍtre
 DragAcceptFiles(ListView1.Handle,true);
  DragAcceptFiles(ShellTreeView1.Handle,true);
 Application.OnMessage := TraiteMessage; // c'est la procÈdure TraiteMessage qui va traiter les messages

 StatusBar1.ControlStyle := StatusBar1.ControlStyle + [csAcceptsControls];
ProgressBar1.Parent := StatusBar1;
ProgressBar1.SetBounds(0, 2, 300, 16);
ProgressBar1.BringToFront;
if paramcount>0 then if DirectoryExists(paramstr(1)) then ShelltreeView1.Path:=paramstr(1);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
  Registre.WriteInteger('TreeViewWhidth',self.ShellTreeView1.Width);
  Registre.WriteInteger('Width',self.Width);
  Registre.WriteInteger('Height',self.Height);
  Registre.WriteInteger('WindowState',Ord(self.WindowState));
  Registre.Free;

  FTmpStream.Size := 0;
  FTmpStream.Free;
  FSeekPosition.Free;
  FFileList.Free;
end;


//****************************************
// ÉäÉXÉgÉrÉÖÅ[ÇÃÉJÉXÉ^ÉÄï`âÊÉCÉxÉìÉgÇ≈ÅAèkè¨âÊëúÇé©ëOÇ≈ï`âÊ
//****************************************
procedure TForm1.ListView1CustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  SeekPos: Integer;
  SHFileInfo: TSHFileInfo;
  IconHandle: HICON;
  Bmp: TBitmap;
  ARect, BRect: TRect;
  coef : Real;
begin
 // ListView1.Canvas.Brush.Color := GetSysColor(COLOR_WINDOW);
  ListView1.Canvas.Font.Color:= clblack;
  ARect := Item.DisplayRect(drIcon);
  ARect.Left := ARect.Left + Trunc((ARect.Right - ARect.Left - ImageList1.Width) / 2);
  ARect.Right := ARect.Left + ImageList1.Width;
  ARect.Top := ARect.Top + Trunc((ARect.Bottom - ARect.Top - ImageList1.Height) / 2);
  ARect.Bottom := ARect.Top + ImageList1.Height;
  ListView1.Canvas.FillRect(ARect);

  SeekPos := StrToInt(FSeekPosition.Strings[Item.Index]);




  Bmp := TBitmap.Create;
  Bmp.LoadFromStream(FTmpStream);

  BRect := Classes.Rect(0, 0, Bmp.Width, Bmp.Height);
  ListView1.Canvas.CopyRect(ARect, Bmp.Canvas, BRect);
  Bmp.Free;




  if SeekPos = -1 then
  begin
    // ÉAÉCÉRÉìï`âÊ
    SHGetFileInfo(
      PChar(ExtractFileExt(Item.Caption)),
      0, SHFileInfo, Sizeof(TSHFileInfo),
      SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES or
      SHGFI_ICON or SHGFI_TYPENAME);
    IconHandle := SHFileInfo.hIcon;
    DrawIconEx(
      ListView1.Canvas.Handle,
      ARect.Left + (ARect.Right - ARect.Left - 32) div 2,
      ARect.Top + (ARect.Bottom - ARect.Top - 32) div 2,
      IconHandle, 32, 32, 0, 0,
      DI_NORMAL);
    DestroyIcon(IconHandle);
  end
  else
  begin
    // èkè¨âÊëúÇÉXÉgÉäÅ[ÉÄÇ©ÇÁÉçÅ[ÉhÇµÇƒï\é¶
    Bmp := TBitmap.Create;
    try

      FTmpStream.Seek(SeekPos, soFromBeginning);
      Bmp.Width  := ARect.Right  - ARect.Left;

      Bmp.LoadFromStream(FTmpStream);

      Bmp.Height := ARect.Bottom - ARect.Top;


      //bmp.Canvas.Brush.Color:=clnone;
      bmp.Canvas.Pen.Color := clwhite;
      bmp.Canvas.Pen.Width := 5;
      bmp.Canvas.MoveTo(0, 0);
      bmp.Canvas.LineTo(99, 0);
      bmp.Canvas.LineTo(99, 99);
      bmp.Canvas.LineTo(0, 99);
      bmp.Canvas.LineTo(0, 0);

      BRect := Classes.Rect(0, 0, Bmp.Width , Bmp.Height);
      ListView1.Canvas.CopyRect(ARect, Bmp.Canvas, BRect);
    finally
      Bmp.Free;
    end;

  end;

  // ëIëèÛë‘Çé¶Ç∑éläpÇï`âÊ
  if cdsSelected in State then
  begin
    ListView1.Canvas.Pen.Color := rgb(192,192,255);
    ListView1.Canvas.Pen.Width := 8;
    ListView1.Canvas.MoveTo(ARect.Left, ARect.Top+2);
    ListView1.Canvas.LineTo(ARect.Left, ARect.Bottom-1+2);
    ListView1.Canvas.LineTo(ARect.Right-1, ARect.Bottom-1+2);
    ListView1.Canvas.LineTo(ARect.Right-1, ARect.Top+2);
    ListView1.Canvas.LineTo(ARect.Left, ARect.Top+2);
  end
  else begin
    ListView1.Canvas.Pen.Color := Clwhite;
    ListView1.Canvas.Pen.Width := 5;
    ListView1.Canvas.MoveTo(ARect.Left, ARect.Top+3);
    ListView1.Canvas.LineTo(ARect.Left, ARect.Bottom-1+3);
    ListView1.Canvas.LineTo(ARect.Right-1, ARect.Bottom-1+3);
    ListView1.Canvas.LineTo(ARect.Right-1, ARect.Top+3);
    ListView1.Canvas.LineTo(ARect.Left, ARect.Top+3);

  end;
     SetBkMode(ListView1.Canvas.Handle, TRANSPARENT);
  ListView_SetTextBkColor(ListView1.Handle, CLR_NONE);
  ListView_SetBKColor(ListView1.Handle, CLR_NONE);
end;

//****************************************
// ÉäÉXÉgÉrÉÖÅ[ÇÃOwnerDataÇTrueÇ…ÇµÇƒÇ¢ÇÈèÍçáÅA
// OnDataÉCÉxÉìÉgÇ≈é©ëOÇ≈èàóùÇ∑ÇÈïKóvÇ™Ç†ÇÈ
//****************************************
procedure TForm1.ListView1Data(Sender: TObject; Item: TListItem);
begin
  Item.Caption := FFileList[Item.index];
end;


procedure TForm1.LoadFiles;
var
  SearchRec: TSearchRec;
begin
  if ShellTreeView1.Path ='' then Exit;

  ListView1.Items.Clear;
  FFileList.Clear;

  // ÉtÉ@ÉCÉãàÍóóçÏê¨
  if FindFirst(ShellTreeView1.Path + '\*.jpg', faDirectory, SearchRec) = 0 then
  begin
    repeat
      //if (SearchRec.Attr and faDirectory) = 0 then
      begin
        FFileList.Add(SearchRec.Name);
        ListView1.Items.Add;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;
  // ÉTÉÄÉlÉCÉãópÇÃÉtÉ@ÉCÉãçÏê¨
//****************************************
// ÉfÉBÉåÉNÉgÉäïœçX
//****************************************
procedure TForm1.ShellTreeView1Change(Sender: TObject; Node: TTreeNode);
BEGIN
  LoadFiles;
  CreateThumbnail(ShellTreeView1.Path);
end;

procedure TForm1.Select_allExecute(Sender: TObject);
var
ax:integer;
begin
ProgressBar1.Min:=0;ProgressBar1.Position:=0;ProgressBar1.Max:=ListView1.Items.Count-1;
//listview1.SelectAll;
for ax:=0 to ListView1.Items.Count-1 do
  begin
    ProgressBar1.Position:=ax;
    StatusBar1.Panels[1].text:=inttostr(ProgressBar1.Position)+'/'+inttostr(ProgressBar1.max)+' - '+LoadStringLanguage(12);
    StatusBar1.Refresh;
    ListView1.Items.item[ax].Selected:=true;
  end;
listview1.SetFocus;
ProgressBar1.Position:=0;
end;

procedure TForm1.ArefreshExecute(Sender: TObject);
begin
  LoadFiles;
  CreateThumbnail(ShellTreeView1.Path);
end;

procedure TForm1.Select_noneExecute(Sender: TObject);
begin
listview1.Selected:=nil;
listview1.SetFocus;
end;

procedure TForm1.ListView1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key= VK_ESCAPE then
  BEGIN
    listview1.Selected:=nil;
    listview1.SetFocus;
  end;
  if key= VK_F5 then
  BEGIN
  LoadFiles;
  CreateThumbnail(ShellTreeView1.Path);
  end;


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

procedure TForm1.A_renameExecute(Sender: TObject);
   var
Photos : Tform3.photarrtyp;

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
resultmodal:integer;
dummy : integer;

label
  RetryRename1,
  RetryRename2,
  RetryRename3;

begin
  rf := Tform3.passinfo(ListView1.Items,Photos, self,ShellTreeView1.Path,use_exif.Checked);
  with  TForm3.Create(self) do resultmodal:=ShowModal;
  if resultmodal = 80 then
  BEGIN
  countselected:=0; digit:=0;
   for ax := 0 to ListView1.Items.Count-1 do
      if ListView1.Items.Item[ax].Selected then countselected:=countselected+1;
   ProgressBar1.Position:=0;ProgressBar1.Min:=0; ProgressBar1.Max:=countselected;


SetLength(Photos,ListView1.Items.Count);
   for ax := 0 to ListView1.Items.Count-1 do
   begin
      if ListView1.Items.Item[ax].Selected then begin
//      s:= s + #10#13 + '(' +ListView1.Items.Item[ax].caption + ') -> ' + ShellTreeView1.Path + '\' + ListView1.Items.Item[ax].caption;
      JPegName:=ShellTreeView1.Path + '\' + ListView1.Items.Item[ax].caption;

      //      s:= s + ListView1.Items.Item[ax].caption + chr(9) + ' -> ' + 'Date prise de vue = '+ ExifImage.DateTimeOriginal + chr(9) + ' File date : ' +  DateToStr(FileDateToDateTime(FileAge(JPegName))) +  chr(9) + TimeToStr(FileDateToDateTime(FileAge(JPegName))) + chr(13);
      if use_exif.Checked then begin
      ExifImage := TExif.Create;
    //  MessageBox(0,pchar(JPegName),'Infos',MB_OK);
      ExifImage.ReadFromFile(JPegName);
      Sdate:=ExifImage.DateTimeOriginal;
      ExifImage.Free;
      end;
      if Sdate<>'?' then Sdate:=copy(Sdate,9,2) + '/' + copy(Sdate,6,2)+ '/' + copy(Sdate,1,4) + '_' + copy(Sdate,12,8);
      if (use_exif.Checked=false) or (Sdate='?') then
      Sdate:=DateToStr(FileDateToDateTime(FileAge(JPegName))) +  '_' + TimeToStr(FileDateToDateTime(FileAge(JPegName)));
//      Sdate:= StringReplace(Sdate,'/','-',[rfReplaceAll, rfIgnoreCase]);
      Sdate:= StringReplace(Sdate,':','.',[rfReplaceAll, rfIgnoreCase]);
      Sdate:=copy(Sdate,7,4)+'-'+copy(Sdate,4,2)+'-'+copy(Sdate,1,2)+'_'+copy(Sdate,12,8);

      Photos[Ax].filename:= ListView1.Items.Item[ax].caption;
      Photos[Ax].ssdate:=Sdate;

 //     s:= s + ListView1.Items.Item[ax].caption + chr(9) + ' -> ' + 'Date prise de vue = '+ Sdate + chr(13);
      ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
      StatusBar1.Panels[1].text:=inttostr(ProgressBar1.Position)+'/'+inttostr(ProgressBar1.max)+' - '+LoadStringLanguage(13);
      StatusBar1.Refresh;
      end;
      Sdate:='';

    end;
  //      MessageBox(0,PChar(s),'Infos',MB_OK);

  Registre:=TRegistry.Create;
  Registre.RootKey:=HKEY_CURRENT_USER;
  Registre.OpenKey('SOFTWARE\Ledadu\Cronos Rename', true);
  newfilename:=Registre.ReadString('Patern');
//  Registre.Free;


  //if InputQuery('Rename',LoadStringLanguage(10), newfilename) then
 //   BEGIN
       ProgressBar1.Position:=0; // ProgressBar1.Step:=countselected div 10;
       dummy:=countselected;
      while dummy>=10 do
        begin
         digit:=digit+1;
         dummy:=dummy div 10;
        end;


//    --- order general (*)
           for ax := 0 to ListView1.Items.Count-1 do
          if ListView1.Items.Item[ax].Selected then Photos[ax].samedate:=false;

          count:=1;
          for ax := 0 to ListView1.Items.Count-1 do
          if ListView1.Items.Item[ax].Selected then
           BEGIN
            for bx := 0 to ListView1.Items.Count-1 do
              if ListView1.Items.Item[bx].Selected then
              begin
                if Photos[ax].ssdate > Photos[bx].ssdate then count:=count+1;
                if (Photos[ax].ssdate = Photos[bx].ssdate) and (Photos[bx].samedate=false) then begin count:=count+1;Photos[ax].samedate:=true;end; // recherche date identique technique astuce :D
              end;
             Photos[ax].order:=count-1;
             count:=1;
             ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
             StatusBar1.Panels[1].text:=inttostr(ProgressBar1.Position)+'/'+inttostr(ProgressBar1.max)+' - '+LoadStringLanguage(14);
             StatusBar1.Refresh;
             Photos[ax].orderDate:=1; //init 1... orderdate  (profiteur)
           END;

//    --- order DATE (? + *)
         if (StrScan(PChar(newfilename),'?') <> nil) then begin
             ProgressBar1.Position:=0;
             for ax := 2 to ListView1.Items.Count   do
             for bx := 0 to ListView1.Items.Count-1  do
             if Photos[bx].order=ax then
              for bbx :=0  to ListView1.Items.Count-1  do                   // recherche date identique technique boucle
               if Photos[bbx].order=ax-1  then                BEGIN
                 if copy(Photos[bbx].ssdate,1,10)=copy(Photos[bx].ssdate,1,10) then Photos[bx].orderDate:=1+Photos[bbx].orderDate ;
                   // fo un break plus rapid.. c trouV
             ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
             StatusBar1.Panels[1].text:=inttostr(ProgressBar1.Position)+'/'+inttostr(ProgressBar1.max)+' - '+LoadStringLanguage(15);
             StatusBar1.Refresh;
             END;
         end;

  s:='';
  ProgressBar1.Position:=0;
  for ax := 0 to ListView1.Items.Count-1 do
      if ListView1.Items.Item[ax].Selected then
      BEGIN
// only *
        if (StrScan(PChar(newfilename),'*') <> nil) and (StrScan(PChar(newfilename),'?') = nil) and (StrScan(PChar(newfilename),'%') = nil) then
        BEgin
//        inc_retry:=0; errorcode:=false;
 //         while (not errorcode) and (inc_retry<10) do begin
//          inc_retry:=inc_retry+1;
          errorcode:=RenameFile(
          ShellTreeView1.Path + '\' + Photos[ax].filename,
          ShellTreeView1.Path + '\' + StringReplace(newfilename,'*',string_digit(digit,Photos[ax].order)+ IntToStr(Photos[ax].order),[])+'.jpg'
         );
//         s:= s + Photos[ax].filename + chr(9) +newfilename + ' / ' + BoolToStr(errorcode)+  ' / ' + IntToStr(Photos[ax].order) + chr(10) ;
//         end;

        ENd;
// DATE + TIME
        if (StrScan(PChar(newfilename),'*') = nil) and (StrScan(PChar(newfilename),'?') <> nil) and (StrScan(PChar(newfilename),'%') <> nil) then
         RenameFile(
          ShellTreeView1.Path + '\' + Photos[ax].filename,
          ShellTreeView1.Path + '\' + StringReplace(StringReplace(newfilename,'?',copy(Photos[ax].ssdate,1,10),[rfReplaceAll, rfIgnoreCase]),'%',copy(Photos[ax].ssdate,12,8),[rfReplaceAll, rfIgnoreCase])+'.jpg'
         );
// DATE + *
        if (StrScan(PChar(newfilename),'*') <> nil) and (StrScan(PChar(newfilename),'?') <> nil) and (StrScan(PChar(newfilename),'%') = nil) then
        BEgin

         RenameFile(
          ShellTreeView1.Path + '\' + Photos[ax].filename,
          ShellTreeView1.Path + '\' + StringReplace(StringReplace(newfilename,'?',copy(Photos[ax].ssdate,1,10),[rfReplaceAll, rfIgnoreCase]),'*',string_digit(digit,Photos[ax].orderDate)+ IntToStr(Photos[ax].orderDate),[rfReplaceAll, rfIgnoreCase])+'.jpg'
         );
        ENd;

          ProgressBar1.Position:=ProgressBar1.Position+1;ProgressBar1.Refresh;
          StatusBar1.Panels[1].text:=inttostr(ProgressBar1.Position)+'/'+inttostr(ProgressBar1.max)+' - '+LoadStringLanguage(16);
          StatusBar1.Refresh;
       //=s+newfilename+string_digit(digit,Photos[ax].order)+ IntToStr(Photos[ax].order)+chr(13);
    END; //fini renomage
  //  MessageBox(0,PChar(s),'Infos',MB_OK);
    Registre.WriteString('Patern',newfilename);
    LoadFiles;
    CreateThumbnail(ShellTreeView1.Path);

  END; // ValidedForm
    Registre.Free;
   ProgressBar1.Position:=0;
 //  END;

end;



procedure TForm1.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
 refresh_statusbar;
end;

procedure TForm1.refresh_statusbar;
  var ax,count:integer;
  pluriel:string;
  BEGIN
count:=0;
 for ax := 0 to ListView1.Items.Count-1 do
      if ListView1.Items.Item[ax].Selected then count:=count+1;
      pluriel:='';
      if count>1 then  StatusBar1.Panels[1].text:=IntToStr(count)+' '+ LoadStringLanguage(17) + 's '+LoadStringLanguage(18)
      else StatusBar1.Panels[1].text:=IntToStr(count)+' '+ LoadStringLanguage(17) + ' '+LoadStringLanguage(19);
      if count=0 then A_rename.Enabled:=false;
      if count>0 then A_rename.Enabled:=true;
end;

procedure TForm1.ShellTreeView1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if key= VK_F5 then
  BEGIN
 ShellTreeView1.Refresh(shellTreeView1.Topitem);
  end;
end;

procedure TForm1.A_languageExecute(Sender: TObject);
begin
  with  TForm2.Create(self) do ShowModal;
  RefreshLanguage;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
   installer;
end;

procedure TForm1.ListView1_prevDblClick(Sender: TObject);

var
  I: Integer;
begin
  // if there is a selected item
  if ListView1.Selected <> nil then
    begin
      // create and show a description
      for I := 0 to ListView1.Items.Count -1 do

        if ListView1.Items.Item[I].Selected then
        begin
           //  ShowMessage (ShelltreeView1.Path + '\'+ListView1.Items.Item[I].caption);
             ShellExecute(Handle, 'open', PChar( ShelltreeView1.Path + '\'+ListView1.Items.Item[I].caption), nil, nil, SW_SHOW);
             break;
        end;
    end;

 end;





end.


