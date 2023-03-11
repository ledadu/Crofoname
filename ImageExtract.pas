unit ImageExtract;

interface

uses Windows, Graphics, SysUtils, ShellApi, ShlObj, ActiveX, ComObj;

const
  IEIFLAG_ASYNC    =   $001;
  IEIFLAG_CACHE    =   $002;
  IEIFLAG_ASPECT   =   $004;
  IEIFLAG_OFFLINE  =   $008;
  IEIFLAG_GLEAM    =   $010;
  IEIFLAG_SCREEN   =   $020;
  IEIFLAG_ORIGSIZE =   $040;
  IEIFLAG_NOSTAMP  =   $080;
  IEIFLAG_NOBORDER =   $100;
  IEIFLAG_QUALITY  =   $200;

const
  {$EXTERNALSYM IID_IExtractImage}
  IID_IExtractImage: TGUID = '{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}'; //Ç±ÇÃGUIDÇ∂Ç·Ç»Ç´Ç·É_ÉÅ

type
  {$EXTERNALSYM IExtractImage}
  IExtractImage = interface(IUnknown)
    ['{BB2E617C-0920-11D1-9A0B-00C04FC2D6C1}']
    function GetLocation(pszPathBuffer: LPWSTR; cchMax: DWORD;
      pdwPriority: PDWORD; const prgSize: PSIZE; dwRecClrDepth: DWORD;
      pdwFlags: PDWORD): HRESULT; stdcall;
    function Extract(phBmpImage: PHandle): HRESULT; stdcall;
  end;

function ExtractImage(AFileName: string; ABitmap: TBitmap; AFlags: DWORD = 0): Boolean;

var
  Malloc: IMalloc;

implementation

function ExtractImage(AFileName: string; ABitmap: TBitmap; AFlags: DWORD = 0): Boolean;
var
  WidePath: WideString;
  Eaten, Attribute: Cardinal;

  DesktopFolder, Folder: IShellFolder;
  ItemIDList, IDList: PItemIDList;

  ExtractImage: IExtractImage;
  Unknown: IUnknown;
  PCh : PWideChar;
  Priority : DWORD;
  ImageSize : SIZE;
  RecClrDepth: DWORD;
  Flags: DWORD;
  hBmp : THandle;
begin
  Result := False;
  SHGetDesktopFolder(DesktopFolder);
  AFileName:=  StringReplace(AFileName,'\\','\',[rfReplaceAll, rfIgnoreCase]);
  WidePath := ExtractFilePath(AFileName);

  DesktopFolder.ParseDisplayName(0, nil, PWideChar(WidePath),
    Eaten, ItemIDList, Attribute);
  DesktopFolder.BindToObject(ItemIDList, nil,
    IID_IShellFolder, Pointer(Folder));

  WidePath := ExtractFileName(AFileName);
  Folder.ParseDisplayName(0, nil, PWideChar(WidePath), Eaten, IDList, Attribute);

  if Succeeded(Folder.GetUIObjectOf(0, 1,
    IDList, IID_IExtractImage, nil, Unknown)) then
  begin
    ExtractImage := Unknown as IExtractImage;
    if ExtractImage <> nil then
    begin

      case ABitmap.PixelFormat of
        pfDevice : RecClrDepth := 24;
        pf1bit   : RecClrDepth := 1;
        pf4bit   : RecClrDepth := 4;
        pf8bit   : RecClrDepth := 8;
        pf15bit  : RecClrDepth := 16;
        pf16bit  : RecClrDepth := 16;
        pf24bit  : RecClrDepth := 24;
        pf32bit  : RecClrDepth := 32;
        pfCustom : RecClrDepth := 24;
        else RecClrDepth := 24;
      end;

      Priority := 0;
      ImageSize.cx := ABitmap.Width;
      ImageSize.cy := ABitmap.Height;
      Flags := AFlags;

      PCh := AllocMem(512);
      try
        ExtractImage.GetLocation(PCh, 512,
          @Priority, @ImageSize, RecClrDepth, @Flags);
        if Succeeded(ExtractImage.Extract(@hBmp)) then
        begin
          ABitmap.Handle := hBmp;
          Result := True;
        end;
      finally
        FreeMem(PCh);
      end;
    end;
  end;

  Malloc.Free(ItemIDList);
  Malloc.Free(IDList);
  DesktopFolder := nil;
  Folder := nil;
end;

initialization
  OleInitialize(nil);
  SHGetMalloc(Malloc);

finalization
  Malloc := nil;
  OleUninitialize;

end.
