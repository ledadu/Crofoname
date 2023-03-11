{==============================================================================
Component simple read Exif section in Jpeg/Jfif Files.
More information about Exif you can get at www.exif.org


Component writen by SimBa aka Dimoniusis (dimonius@mailru.com)
modified by RicRak (epiret@free.fr)

You may use this component absolutly free.

==============================================================================}



unit Exif;

interface

uses
  Classes, SysUtils,Graphics,jpeg;

type
  TTag = record
    TagID   : Word;       //Tag number
    TagType : Word;       //Type tag
    Count   : Cardinal;   //tag length
    OffSet  : Cardinal;   //Offset / Value
  end;

  TExif = class(TObject)
    private
{      FImageWidth         : String;}
      FImageLength        : String;
      FImageDesc          : String;     //Picture description
      FMake               : String;     //Camera manufacturer
      FModel              : String;     //Camere model
      FOrientation        : Byte;       //Image orientation - 1 normal
      FXResol             : String;
      FYResol             : String;
      FOrientationDesk    : String;     //Image orientation description
      FCopyright          : String;     //Copyright
      FValid              : Boolean;    //Has valid Exif header
      FDateTime           : String;     //Date and Time of Change
      FSoftware           : String;
      FDateTimeOriginal   : String;     //Original Date and Time
      FDateTimeDigitized  : String;     //Camshot Date and Time
      FUserComments       : String;     //User Comments, minus 8 first char

      FExposureTime       : String;
      FFNumber            : String;
      FExifVersion        : String;
      FSubjectDistance    : String;
      FMeteringMode       : String;
      FLightSource        : String;
      FFlash              : String;
      FFocallength        : String;
      FExpProg            : String;
      FISO                : String;
      FImageWidth         : String;
      FImageHeight        : String;
      FCompression        : String;
      FXResolThumb        : String;
      FYResolThumb        : String;
      FJPEG_OffsThumb      : String;
      FJPEG_LengThumb      : String;
      FUserCommentOffset   : word; {absolu, depuis début fichier}
      FUserCommentLength   : word; {y compris 8 car type jeu caractere}
      FUserCommentCarCode  : string;

{      f                   : File;}
      ExifIfdPtr          : Cardinal;
      _1IfdOffset         : Cardinal{word};
      ExifIfdNb           : word;
      _1IfdNb             : word;
      BigEndian           : boolean;

      function ReadIFDValue(ActTag:TTag; const offset0: Cardinal): String;
      procedure Init;
    public

      constructor Create;
      function ReadFromFile(const FileName: AnsiString):boolean;

{      property ImageWidth: String read FImageWidth;}
      property ImageLength: String read FImageLength;
      property ImageDesc: String read FImageDesc;
      property Make: String read FMake;
      property Model: String read FModel;
      property Orientation: Byte read FOrientation;
      property OrientationDesk: String read FOrientationDesk;
      property XResol: String read FXResol;
      property YResol: String read FYResol;
      property Copyright: String read FCopyright;
      property Valid: Boolean read FValid;
      property DateTime: String read FDateTime;
      property Software: String read FSoftware;
      property DateTimeOriginal: String read FDateTimeOriginal;
      property DateTimeDigitized: String read FDateTimeDigitized;
      property UserComments: String read FUserComments;

      property ExposureTime: String read FExposureTime;
      property FNumber: String read FFNumber;
      property ExifVersion: String read FExifVersion;
      property SubjectDistance: String read FSubjectDistance;
      property MeteringMode: String read FMeteringMode;
      property LightSource: String read FLightSource;
      property Flash: String read FFlash;
      property Focallength: String read FFocallength;
      property ExpProg: String read FExpProg;
      property ISO: String read FISO;
      property ImageWidth: String read FImageWidth;
      property ImageHeight: String read FImageHeight;
      property Compression: String read FCompression;
      property XResolThumb: String read FXResolThumb;
      property YResolThumb: String read FYResolThumb;
      property JPEG_OffsThumb: String read FJPEG_OffsThumb;
      property JPEG_LengThumb: String read FJPEG_LengThumb;
      property UserCommentOffset : word read FUserCommentOffset; {absolu, depuis début fichier}
      property UserCommentLength : word read FUserCommentLength; {y compris 8 car type jeu caractere}
      property UserCommentCarCode : string read FUserCommentCarCode;

  end;

  function ReadThumbFromFile(const FileName: AnsiString;var ThumbBMPImage : Tbitmap ):boolean;
  procedure SetCommentInFile(const FileName: AnsiString; AbsCommentOffset,AbsCommentlength:cardinal;
                                   UserComment:string);
  procedure ReadCommentInFile(const FileName: AnsiString; AbsCommentOffset,AbsCommentlength:cardinal;
                              var UserCommentCarCode,UserComment:string);

  var Exif_PtrThumb:pchar;
  var Exif_ThumbLength:integer;
  var ExifS:AnsiString;

implementation
uses Dialogs;
type
  TMarker = record
    Marker   : Word;      //Section marker
    Len      : Word;      //Length Section
    Indefin  : Array [0..4] of Char; //Indefiner - "Exif" 00, "JFIF" 00 and ets
    Pad      : Char;      //0x00
  end;

  TIFDHeader = record
{    pad          : Byte; //00h}
    ByteOrder    : Word; //"II" ($4949, Little Endian) or  "MM" ($4D4D, Big Endian)
    i42          : Word; //$2A00  or $002A
    IFD0offSet   : Cardinal; //0th offset IFD
    Interoperabil: {Byte}Word;
  end;

  TWordRec = record
    W1,W2:word;
  end;

var SS:string;
    f: File;

function swap32(X:cardinal):cardinal;
begin
  result:=swap(TwordRec(X).W1)*256+swap(TwordRec(X).W2);
end;

procedure Adapte_Tag(var ActTag:TTag);
var  Totalbytesize:word;
     UseOffset:boolean;
begin
  with ActTag do begin
    TagID   := swap(TagId);
    TagType := swap(TagType);
    Count   := swap32(Count);
    Totalbytesize:=0;
    case byte(TagType) of
    {1=byte, 2=chaine AZT, 3=short(int), 4=cardinal (word), 5=rationnel(rapport de 2 word),
     6=?, 7=char, 8=?, 9=integer (entier signé), 10=Srationnel(rapport de 2 integer)'}
      1,2,7: Totalbytesize:=ActTag.Count;
      3: Totalbytesize:=ActTag.Count*2;
      4,9: Totalbytesize:=ActTag.Count*4;
      5,10: Totalbytesize:=ActTag.Count*8;
    end;
    UseOffset:=(Totalbytesize>4);
    case byte(TagType) of
      1: Offset:=byte(offset);
      3: Offset:=swap(TwordRec(offset).W1);
      4,9: OffSet := swap32(Offset);
      5,10: OffSet := swap32(Offset);
      2,7: if Totalbytesize>4 then OffSet := swap32(Offset);
    end;
  end;
end;

function Texif.ReadIFDValue(ActTag:TTag; const offset0: Cardinal): String;
type Achar = array[1..4] of char;
var fp: LongInt;
     i: Word;
     Ab : achar;
     Numer,denom:cardinal;
     Totalbytesize:word;
     UseOffset:boolean;
begin
  Totalbytesize:=0;
  case byte(ActTag.TagType) of
  {1=byte, 2=chaine AZT, 3=short(int), 4=cardinal (word), 5=rationnel(rapport de 2 word),
   6=?, 7=char, 8=?, 9=integer (entier signé), 10=Srationnel(rapport de 2 integer)'}
    1,2,7: Totalbytesize:=ActTag.Count;
    3: Totalbytesize:=ActTag.Count*2;
    4,9: Totalbytesize:=ActTag.Count*4;
    5,10: Totalbytesize:=ActTag.Count*8;
  end;
  UseOffset:=(Totalbytesize>4);
  if not(UseOffset) then begin
    if byte(ActTag.TagType) in [1,3,4,9] then Result:=inttostr(ActTag.offset)
    else if ActTag.TagType=2 then begin
      SetLength(Result,ActTag.Count);
      Ab:=achar(ActTag.offset);
      i:=0;
      repeat
        inc(i);
        if Ab[i]<>#0 then Result[i]:=ab[i];
      until (i>ActTag.Count) or (Ab[i]=#0);
      if i<=ActTag.Count then Result:=Copy(Result,1,i-1);
    end
    else if ActTag.TagType=7 then begin
      SetLength(Result,ActTag.Count);
      Ab:=achar(ActTag.offset);
      for i:=1 to ActTag.Count do Result[i]:=ab[i];
    end;
    {pour Tag=5 ou 10, Totalbytesize=8 (donc > 4)}
  end
  else begin {UseOffset}
    fp:=FilePos(f); //Save file offset
    if ActTag.TagType=2 then begin
      SetLength(Result,ActTag.Count);
      Seek(f, ActTag.Offset+Offset0);
      try
        i:=1;
        repeat
          BlockRead(f,Result[i],1);
          inc(i);
        until (i>=ActTag.Count) or (Result[i-1]=#0);
        if i<=ActTag.Count then Result:=Copy(Result,1,i-1);
      except
        Result:='';
      end;
    end
    else if (ActTag.TagType=5) or (ActTag.TagType=10) then begin
      Seek(f, ActTag.Offset+Offset0);
      try
        BlockRead(f,Numer,4); if BigEndian then Numer:=swap32(Numer);
        BlockRead(f,Denom,4); if BigEndian then Denom:=swap32(Denom);
        if (Denom=0) or (Numer=0) then Result:='0'
        else
          if Numer>=Denom then Result:=floattostrf(Numer/Denom,fffixed,4,1)
        else
          Result:='1/'+inttostr(round(Denom/Numer));
      except
        Result:='';
      end;
    end
    else if ActTag.TagType=7 then begin
      SetLength(Result,ActTag.Count);
      Seek(f, ActTag.Offset+Offset0);
      try
        i:=1;
        repeat
          BlockRead(f,Result[i],1);
          inc(i);
        until (i>ActTag.Count);
      except
        Result:='';
      end;
    end;
    {pour Tag=1,3,4 ou 9, Totalbytesize<=4}
    Seek(f,fp);     //Restore file offset
  end;
end;

{EP}

procedure TExif.Init;
begin
  ExifIfdPtr:=0;
{  FImageWidth:='?';}
  FImageLength:='?';
  FImageDesc:='?';
  FMake:='?';
  FModel:='?';
  FOrientation:=1;
  FXResol:='?';
  FYResol:='?';
  FOrientationDesk:='Normal';
  FDateTime:='?';
  FSoftware:='?';
  FCopyright:='?';
  FValid:=False;
  FDateTimeOriginal:='?';
  FDateTimeDigitized:='?';
  FUserComments:='?';
  FExposureTime:='?';
  FFNumber:='?';
  FExifVersion:='?';
  FSubjectDistance:='?';
  FMeteringMode:='?';
  FLightSource:='?';
  FFlash:='?';
  FFocallength:='?';
  FExpProg:='?';
  FISO:='?';
  FImageWidth:='?';
  FImageHeight:='?';
  FCompression:='?';
  FXResolThumb:='?';
  FYResolThumb:='?';
  FJPEG_OffsThumb:='?';
  FJPEG_LengThumb:='?';
end;

constructor TExif.Create;
begin
  Init;
end;

function TExif.ReadFromFile(const FileName: AnsiString):boolean;
const ori: Array[1..8] of String=('Normal','Mirrored','Rotated 180','Rotated 180, mirrored','Rotated 90 left, mirrored','Rotated 90 right','Rotated 90 right, mirrored','Rotated 90 left');
      ModeMesure: Array[0..6] of String=('Inconnu','Moyen','Central pondéré','Spot','MultiSpot','Multi-segment','Partiel');
      TypeLumiere: Array[0..9] of String=('Inconnu','Naturel','Fluo','Tungsten','Std A','Std B','Std C','D55','D65','D75');
      ModeProgram: Array[0..8] of String=('Inconnu','Manuel','Normal','Priorité ouverture','Priorité vitesse','Créatif','Action','Portrait','Paysage');
var j: TMarker;
    _0ifdHeader: TIFDHeader;
    off0,offx: Cardinal; //Null Exif Offset
    tag: TTag;
    i: Integer;
  SOI: Word; //2 bytes SOI marker. FF D8 (Start Of Image)
  WW: Word;
  R:real;
  codeerr:integer;
  FileModeDef:byte;
  S:string;
  filesizeee:integer;
begin
  Result:=false;
  if not FileExists(FileName) then exit;
  Init;
  FileModeDef:=FileMode;
  FileMode:=0;

  AssignFile(f,FileName);
  reset(f,1);

  if not eof(f) then BlockRead(f,SOI,2);
  if SOI=$D8FF then begin //Is this Jpeg
    if not eof(f) then BlockRead(f,j,{9}10);

    if j.Marker=$E0FF then begin //JFIF Marker Found
      Seek(f,20); //Skip JFIF Header
      if not eof(f) then BlockRead(f,j,{9}10);
    end;

    if j.Marker=$E1FF then begin //If we found Exif Section. j.Indefin='Exif'.
      FValid:=True;
      off0:=FilePos(f){+1};   //0'th offset Exif header
      if not eof(f) then BlockRead(f,_0ifdHeader,{11}10);  //Read IFD Header
      BigEndian:= (_0ifdHeader.ByteOrder=$4D4D);
      if BigEndian then with _0ifdHeader do begin //numeric data stored in reverse order
        IFD0offSet:=swap32(IFD0offSet);
        Interoperabil:= swap(Interoperabil);
      end;

      i:=0;
      repeat
        inc(i);
        if ((not Eof(f)) and (FileSize(f)>FilePos(f)+12)) then BlockRead(f,tag,12); if BigEndian then Adapte_Tag(tag);
{        //0001 ImageWidth
        if tag.TagID=$0100 then FImageWidth:=ReadIFDValue(Tag,off0);
        //0101 ImageLength
        if tag.TagID=$0101 then FImageLength:=ReadIFDValue(Tag,off0);}
        //0E01 ImageDescription
        if tag.TagID=$010E then FImageDesc:=ReadIFDValue(Tag,off0);
        //0F01 Make
        if tag.TagID=$010F then FMake:=ReadIFDValue(Tag,off0);
        //1001 Model
        if tag.TagID=$0110 then FModel:=ReadIFDValue(Tag,off0);
        //6987 Exif IFD Pointer
        if tag.TagID=$8769 then ExifIfdPtr:=Tag.OffSet; //Read Exif IDF offset
        //1201 Orientation
        if tag.TagID=$0112 then begin
           FOrientation:=tag.OffSet;
           if tag.OffSet in [1..8] then FOrientationDesk:=ori[tag.OffSet] else FOrientationDesk:='Unknown';
        end;
        //1A01 XResolution of primary (main) image; for thumbnail caract., see 1'st IFD
        if tag.TagID=$011A then begin
          FXResol:=ReadIFDValue(Tag,off0);
          val(FXResol,R,codeerr);
          if (CodeErr<>0) or (round(R)=72) then FXResol:='?';
        end;
        //1B01 YResolution of primary (main) image; for thumbnail caract., see 1'st IFD
        if tag.TagID=$011B then begin
          FYResol:=ReadIFDValue(Tag,off0);
          val(FYResol,R,codeerr);
          if (CodeErr<>0) or (round(R)=72) then FYResol:='?';
        end;
        //3101 Software
        if tag.TagID=$0131 then FSoftware:=ReadIFDValue(Tag,off0);
        //3201 DateTime
        if tag.TagID=$0132 then FDateTime:=ReadIFDValue(Tag,off0);
        //9882 CopyRight
        if tag.TagID=$8298 then FCopyright:=ReadIFDValue(Tag,off0);
      until (i=_0ifdHeader.Interoperabil) or Eof(f) or(FileSize(f)<=FilePos(f)+12) ;

      if not Eof(f) and (FileSize(f)>FilePos(f)+4) then BlockRead(f,_1IfdOffset,4); {Offset of 2d IFD (IFD 1)} {2 ou 4???}
      if BigEndian then _1IfdOffset:=swap32(_1IfdOffset);
      if ExifIfdPtr>0 then begin
{        Seek(f,ExifIfdPtr+12+2);//12 - Size header before Exif, 2 - size Exif IFD Number}
        Seek(f,ExifIfdPtr+off0);//12 - Size header before Exif Header
        if not eof(f) and (FileSize(f)>FilePos(f)+2) then BlockRead(f,ExifIfdNb,2); if BigEndian then ExifIfdNb:=swap(ExifIfdNb);
        i:=0;
        repeat
          inc(i);
          if not eof(f) and (FileSize(f)>FilePos(f)+12) then BlockRead(f,tag,12); if BigEndian then Adapte_Tag(tag);
  {
          You may simple realize read this info:

          tag |Name of tag

          9A82 ExposureTime
          9D82 FNumber
          0090 ExifVersion
          0390 DateTimeOriginal
          0490 DateTimeDigitized
          0191 ComponentsConfiguration
          0292 CompressedBitsPerPixel
          0192 ShutterSpeedValue
          0292 ApertureValue
          0392 BrightnessValue
          0492 ExposureBiasValue
          0592 MaxApertureRatioValue
          0692 SubjectDistance
          0792 MeteringMode
          0892 LightSource
          0992 Flash
          0A92 FocalLength
          8692 UserComments
          9092 SubSecTime
          9192 SubSecTimeOriginal
          9292 SubSecTimeDigitized
          A000 FlashPixVersion
          A001 Colorspace
          A002 Pixel X Dimension
          A003 Pixel Y Dimension
  }

          //9A82 ExposureTime
          if tag.TagID=$829A then begin
            FExposureTime:=ReadIFDValue(Tag,off0);
          end;
          //9D82 FNumber
          if tag.TagID=$829D then begin
            FFNumber:=ReadIFDValue(Tag,off0);
          end;
          //2288 ExposureProgram
          if tag.TagID=$8822 then begin
            if (Tag.OffSet in [0..8]) then FExpProg:=ModeProgram[Tag.offSet]
                                      else FExpProg:=ModeProgram[0];
          end;
          //2788 ISO speed ratings
          if tag.TagID=$8827 then begin
            FISO:=ReadIFDValue(Tag,off0);
          end;
          //0090 ExifVersion
          if tag.TagID=$9000 then begin
            FExifVersion:=ReadIFDValue(Tag,off0);
          end;
          //0390 FDateTimeOriginal
          if tag.TagID=$9003 then FDateTimeOriginal:=ReadIFDValue(Tag,off0);
          //0490 DateTimeDigitized
          if tag.TagID=$9004 then FDateTimeDigitized:=ReadIFDValue(Tag,off0);
          //0191 ComponentsConfiguration
          //0292 CompressedBitsPerPixel
          //0192 ShutterSpeedValue
          //0292 ApertureValue
          //0392 BrightnessValue
          //0492 ExposureBiasValue
          //0592 MaxApertureRatioValue
          //0692 SubjectDistance
          if tag.TagID=$9206 then begin
            FSubjectDistance:=ReadIFDValue(Tag,off0);
          end;
          //0792 MeteringMode
          if tag.TagID=$9207 then begin
            if (Tag.OffSet in [0..6]) then FMeteringMode:=ModeMesure[Tag.offSet]
                                      else FMeteringMode:=ModeMesure[0];
          end;
          //0892 LightSource
          if tag.TagID=$9208 then begin
            if (Tag.OffSet in [0..3]) then FLightSource:=TypeLumiere[Tag.offSet]
            else if (Tag.OffSet in [17..22]) then FLightSource:=TypeLumiere[Tag.offSet-13]
                                               else FLightSource:=TypeLumiere[0];
          end;
          //0992 Flash
          if tag.TagID=$9209 then begin
            if Tag.OffSet=0 then FFlash:='Pas de flash'
            else if Tag.OffSet=1 then FFlash:='Flash'
            else if Tag.OffSet=5 then FFlash:='Flash (retour non détecté)'
            else if Tag.OffSet=7 then FFlash:='Flash (retour détecté)';
          end;
          //0A92 FocalLength
          if tag.TagID=$920A then begin
            FFocallength:=ReadIFDValue(Tag,off0);
            val(FFocallength,R,codeerr);
            if codeerr=0 then begin
              R:=R*4.875;
              FFocallength:=floattostrf(R,fffixed,3,0);
            end;
          end;
          //8692 UserComments
          if tag.TagID=$9286 then begin
            FUserComments:=ReadIFDValue(Tag,off0);
            FUserCommentOffset:=tag.OffSet+off0;
            FUserCommentLength:=tag.Count; {y compris 8 car type jeu caractere}
            if FUserCommentLength>8 then begin
              FUserCommentCarCode:=copy(FUserComments,1,8);
              FUserComments:=copy(FUserComments,9,FUserCommentLength-8);
              codeerr:=pos(chr(0),FUserComments);
              if codeerr<>0 then FUserComments:=copy(FUserComments,1,codeerr-1);
            end;

          end;
          //9092 SubSecTime
          //9192 SubSecTimeOriginal
          //9292 SubSecTimeDigitized
          //000A FlashPixVersion
          //01A0 Colorspace
          //02A0 Pixel X Dimension
          if tag.TagID=$A002 then begin
            FImageWidth:=ReadIFDValue(Tag,off0);
          end;
          //03A0 Pixel Y Dimension
          if tag.TagID=$A003 then begin
            FImageHeight:=ReadIFDValue(Tag,off0);
          end;
        until (i=ExifIfdNb);
      end;

      if _1IfdOffset>0 then begin
        if ((not eof(f)) and (_1IfdOffset+off0<FileSize(f))) then BEGIN
        Seek(f,_1IfdOffset+off0);

        END;
        if not eof(f) and (FileSize(f)>FilePos(f)+2) then BlockRead(f,_1IfdNb,2);
        if BigEndian then _1IfdNb:=swap(_1IfdNb);
        i:=0;
        repeat
          inc(i);
          if ((not eof(f)) and (_1IfdOffset+off0<FileSize(f))) then BlockRead(f,tag,12); if BigEndian then Adapte_Tag(tag);

          //0301 Compression
   //       if tag.TagID=$0103 then begin
   //         FCompression:=ReadIFDValue(Tag,off0);
   //         if strtoint(FCompression)=1 then FCompression:='Thumbnail non compressé'
   //         else if strtoint(FCompression)=6 then FCompression:='Thumbnail JPEG';
   //       end;
          //1A01 XResolution of thumbnail image; for primary (main) caract., see 0'th IFD
          if tag.TagID=$011A then begin
            FXResolThumb:=ReadIFDValue(Tag,off0);
            val(FXResolThumb,R,codeerr);
            if (CodeErr=0) and (round(R)=72) then FXResolThumb:='? (défaut=72)'
            else if (CodeErr<>0) then FXResolThumb:='?';
          end;
          //1B01 YResolution of thumbnail image; for primary (main) caract., see 0'th IFD
          if tag.TagID=$011B then begin
            FYResolThumb:=ReadIFDValue(Tag,off0);
            val(FYResolThumb,R,codeerr);
            if (CodeErr=0) and (round(R)=72) then FYResolThumb:='? (défaut=72)'
            else if (CodeErr<>0) then FYResolThumb:='?';
          end;
          //0102 Thumbnail JPEG Offset
          if tag.TagID=$0201 then begin
            FJPEG_OffsThumb:=ReadIFDValue(Tag,off0);
            val(FJPEG_OffsThumb,offx,codeerr);
            if (CodeErr=0) then FJPEG_OffsThumb:=FJPEG_OffsThumb+' ($'+inttohex(offx,4)+')';
          end;
          //0202 Thumbnail JPEG Length
          if tag.TagID=$0202 then begin
            FJPEG_LengThumb:=ReadIFDValue(Tag,off0);
          end;

        until (i=_1IfdNb) or eof(f) or (_1IfdOffset+off0>FileSize(f));
      end;
{
      SS:=inttostr(off0);
      SS:='$'+inttohex(filepos(f),8);
      WW:=$FFFF;
      while (WW<>$D8FF) and not(eof(f)) do BlockRead(f,WW,2);
      if WW=$D8FF then begin //Is this Jpeg
        SS:='$'+inttohex(filepos(f),8);
        WW:=$FFFF;
        while (WW<>$D9FF) and not(eof(f)) do BlockRead(f,WW,2);
        SS:='$'+inttohex(filepos(f),8);
        if not(eof(f)) then BlockRead(f,WW,2);
        while (WW<>$D9FF) and not(eof(f)) do BlockRead(f,WW,2);
        SS:='$'+inttohex(filepos(f),8);
        while not(eof(f)) do BlockRead(f,WW,2);
        SS:='$'+inttohex(filepos(f),8);
      end;
}
      Result:=true;
    end;
  end;
  CloseFile(f);
  FileMode:=FileModeDef;
end;

function ReadThumbFromFile(const FileName: AnsiString;var ThumbBMPImage : Tbitmap ):boolean;
var j: TMarker;
    _0ifdHeader: TIFDHeader;
    off0: Cardinal; //Null Exif Offset
    tag: TTag;
    i: Integer;
  SOI: Word; //2 bytes SOI marker. FF D8 (Start Of Image)
  FileModeDef:byte;
  PtrBuf:Pchar; SizeBuf:integer;
  Ifd1Offset         : cardinal;
  Ifd1Nb             : word;
  Found1,Found2:boolean;
  ThumbOffset:cardinal;
  f2:file;
  ThumbJPGImage:TJpegImage;
  TempStream : TMemoryStream;
  WW1,WW2:word;
  BigEndian:boolean;
begin
  Result:=false;
  if not FileExists(FileName) then exit;
  FileModeDef:=FileMode;
  FileMode:=0;

  AssignFile(f,FileName);
  reset(f,1);

  if not eof(f) and (FileSize(f)>FilePos(f)+2) then BlockRead(f,SOI,2);
  if SOI=$D8FF then begin //Is this Jpeg
    if not eof(f) and (FileSize(f)>FilePos(f)+10) then BlockRead(f,j,{9}10);

    if j.Marker=$E0FF then begin //JFIF Marker Found
      if not eof(f) then Seek(f,20); //Skip JFIF Header
      if not eof(f) and (FileSize(f)>FilePos(f)+10) then BlockRead(f,j,{9}10);
    end;

    if j.Marker=$E1FF then begin //If we found Exif Section. j.Indefin='Exif'.
      off0:=FilePos(f){+1};   //0'th offset Exif header
      if not eof(f) and (FileSize(f)>FilePos(f)+10) then BlockRead(f,_0ifdHeader,{11}10);  //Read IFD Header
      BigEndian:= (_0ifdHeader.ByteOrder=$4D4D);
      if BigEndian then with _0ifdHeader do begin //numeric data stored in reverse order
        IFD0offSet:=swap32(IFD0offSet);
        Interoperabil:= swap(Interoperabil);
      end;

      SizeBuf:=sizeof(TTag)*_0ifdHeader.Interoperabil;
      GetMem(PtrBuf, SizeBuf);
      if not eof(f) and (FileSize(f)>FilePos(f)+Sizebuf) then BlockRead(f,PtrBuf^,SizeBuf);
      FreeMem(PtrBuf);
{      for i:=1 to _0ifdHeader.Interoperabil do BlockRead(f,tag,12);}

      if not eof(f) and (FileSize(f)>FilePos(f)+4) then BlockRead(f,Ifd1Offset,4); {Offset of 2d IFD (IFD 1)} {2 ou 4???}
      if BigEndian then Ifd1Offset:=swap32(Ifd1Offset);
      if Ifd1Offset>0 then begin
        if not eof(f) then Seek(f,Ifd1Offset+off0);
        if not eof(f) and (FileSize(f)>FilePos(f)+2) then BlockRead(f,Ifd1Nb,2); if BigEndian then Ifd1Nb:=swap(Ifd1Nb);
        i:=0; Found1:=false;Found2:=false;
        repeat
          inc(i);
          if not eof(f) and (FileSize(f)>FilePos(f)+12) then BlockRead(f,tag,12); if BigEndian then Adapte_Tag(tag);
          //0102 Thumbnail JPEG Offset
          if tag.TagID=$0201 then begin
            ThumbOffset:=Tag.offset; Found1:=true;
          end;
          //0202 Thumbnail JPEG Length
          if tag.TagID=$0202 then begin
            Exif_ThumbLength:=Tag.offset; Found2:=true;
          end;

        until (i=Ifd1Nb) or (Found1 and Found2);

        if Found1 and Found2 then begin
          if not eof(f) then Seek(f,ThumbOffset+off0);
          GetMem(Exif_PtrThumb, Exif_ThumbLength);
          if not eof(f) and (FileSize(f)>FilePos(f)+Exif_ThumbLength) then BlockRead(f,Exif_PtrThumb^,Exif_ThumbLength);
          ThumbJPGImage := TJPEGImage.Create;
          TempStream := TMemoryStream.Create;
          TempStream.WriteBuffer(Exif_PtrThumb^,Exif_ThumbLength);
          TempStream.Position := 0;
          ThumbJPGImage.LoadFromStream(TempStream);
          ThumbBMPImage := Tbitmap.create;
          ThumbBMPImage.Height:=ThumbJPGImage.Height;
          ThumbBMPImage.Width:=ThumbJPGImage.Width;
          ThumbBMPImage.canvas.draw(0,0,ThumbJPGImage);
          ThumbJPGImage.Free;
          TempStream.free;
          FreeMem(Exif_PtrThumb);

{          Seek(f,ThumbOffset+off0);
          setlength(ExifS,Exif_ThumbLength);
          BlockRead(f,ExifS[1],Exif_ThumbLength);}

          Result:=true;

{          Clipboard.assign(
    assignfile(f2,FileName+'.thm'); rewrite(f2,1);
    blockwrite(f2,Exif_PtrThumb^,Exif_ThumbLength);
    closefile(f2);
    FreeMem(Exif_PtrThumb);
}
        end;
      end;
    end;
  end;
  CloseFile(f);
  FileMode:=FileModeDef;
end;

procedure SetCommentInFile(const FileName: AnsiString; AbsCommentOffset,AbsCommentlength:cardinal;
                                 UserComment:string);
var   FileModeDef:byte;
      AbsUserComment:string;
      i,FileAttribut:integer;
begin
  if not FileExists(FileName) then exit;
  UserComment:=copy(UserComment,1,AbsCommentlength-8);
  if length(UserComment)<AbsCommentlength-8 then
    for i:=length(UserComment)+1 to AbsCommentlength-8 do UserComment:=UserComment+' ';
  UserComment:='ASCII'+chr(0)+chr(0)+chr(0)+UserComment;

  FileModeDef:=FileMode;
  FileMode:=2;
  FileAttribut := FileGetAttr(FileName);

  try
    if FileAttribut and faReadOnly <> 0 then
      FileSetAttr(FileName, FileAttribut-faReadOnly);
  except
    FileMode:=FileModeDef;
    showmessage('ERREUR: le fichier n''a pas pu être modifié');
    exit;
  end;
  AssignFile(f,FileName);
  reset(f,1);
  if not eof(f) then Seek(f,AbsCommentOffset);
  blockwrite(f,UserComment[1],AbsCommentLength);
  CloseFile(f);
  FileSetAttr(FileName, FileAttribut);
  FileMode:=FileModeDef;
end;

procedure ReadCommentInFile(const FileName: AnsiString; AbsCommentOffset,AbsCommentlength:cardinal;
                            var UserCommentCarCode,UserComment:string);
var   FileModeDef:byte;
      AbsUserComment:string;
      i,pos0:integer;
begin
  if not FileExists(FileName) then exit;
  UserComment:='';
  SetLength(UserComment,AbsCommentlength);
  FileModeDef:=FileMode;
  FileMode:=0;
  AssignFile(f,FileName);
  reset(f,1);
  if not eof(f) then Seek(f,AbsCommentOffset);
  if not eof(f) and (FileSize(f)>FilePos(f)+AbsCommentLength) then blockread(f,UserComment[1],AbsCommentLength);

  UserCommentCarCode:=copy(UserComment,1,8);
  UserComment:=copy(UserComment,9,AbsCommentLength-8);
  pos0:=pos(chr(0),UserComment);
  if pos0<>0 then UserComment:=copy(UserComment,1,pos0-1);

  CloseFile(f);
  FileMode:=FileModeDef;
end;

end.

