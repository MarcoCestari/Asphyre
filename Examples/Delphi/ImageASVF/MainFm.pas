unit MainFm;
//---------------------------------------------------------------------------
// MainFm.pas
// Example on how to add images to ASVF at run-time.
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Asphyre.Archives,
  Asphyre.Types, pxfm;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    OpenDialog1: TOpenDialog;
    BitBtn1: TBitBtn;
    Bevel1: TBevel;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    Edit3: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Edit4: TEdit;
    Edit5: TEdit;
    Bevel2: TBevel;
    Label6: TLabel;
    Edit6: TEdit;
    BitBtn2: TBitBtn;
    Bevel3: TBevel;
    BitBtn3: TBitBtn;
    SaveDialog1: TSaveDialog;
    CheckBox1: TCheckBox;
    Label7: TLabel;
    Shape1: TShape;
    ColorDialog1: TColorDialog;
    Label8: TLabel;
    Edit7: TEdit;
    Bevel4: TBevel;
    Label9: TLabel;
    Edit8: TEdit;
    procedure Shape1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    Archive: TAsphyreArchive;
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
uses
 Asphyre.Math, Asphyre.Bitmaps, Asphyre.Bitmaps.TGA, Asphyre.Bitmaps.BMP,
 Asphyre.Bitmaps.PNG, Asphyre.Surfaces;
{$R *.dfm}

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 Archive:= TAsphyreArchive.Create();
 Archive.OpenMode:= aomUpdate;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 FreeAndNil(Archive);
end;

//---------------------------------------------------------------------------
procedure TMainForm.BitBtn1Click(Sender: TObject);
begin
 if (OpenDialog1.Execute()) then
  Edit1.Text:= OpenDialog1.FileName;
end;

//---------------------------------------------------------------------------
procedure TMainForm.BitBtn2Click(Sender: TObject);
begin
 if (SaveDialog1.Execute()) then
  Edit6.Text:= SaveDialog1.FileName;
end;

//---------------------------------------------------------------------------
procedure TMainForm.Shape1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 ColorDialog1.Color:= Shape1.Brush.Color;

 if (ColorDialog1.Execute()) then
  Shape1.Brush.Color:= ColorDialog1.Color;
end;

//---------------------------------------------------------------------------
procedure TMainForm.BitBtn3Click(Sender: TObject);
var
 PxFm     : TPxFm;
 pSize    : TPoint2px;
 Image    : TSystemSurface;
 Dest     : TSystemSurface;
 Tolerance: Integer;
 MaskColor: Cardinal;
 IsMasked : Boolean;
 Stream   : TMemoryStream;
begin
 // update ASVF archive
 if (not Archive.OpenFile(Edit6.Text)) then
  begin
   ShowMessage('Failed opening ASVF archive!');
   Exit;
  end;

 // Change the following format, if necessary.
 // -> E.g. you can try "apf_R5G6B5".
 PxFm.Format:= apf_A8R8G8B8;

 // retreive Texture Size from edit boxes
 PxFm.TextureWidth := StrToIntDef(Edit2.Text, 256);
 PxFm.TextureHeight:= StrToIntDef(Edit3.Text, 256);

 // retreive Pattern Size from edit boxes
 PxFm.PatternWidth := StrToIntDef(Edit4.Text, 32);
 PxFm.PatternHeight:= StrToIntDef(Edit5.Text, 32);

 // this variable is used for better readability only
 pSize:= Point2px(PxFm.PatternWidth, PxFm.PatternHeight);

 // this size can be smaller than pattern size to add padding
 PxFm.VisibleWidth := PxFm.PatternWidth;
 PxFm.VisibleHeight:= PxFm.PatternHeight;

 // retreive mask color and tolerance
 IsMasked:= CheckBox1.Checked;
 MaskColor:= Shape1.Brush.Color and $FFFFFF;
 Tolerance:= StrToIntDef(Edit7.Text, 15);

 // load source bitmap
 Image:= TSystemSurface.Create();
 if (not BitmapManager.LoadFromFile(Edit1.Text, Image)) then
  begin
   ShowMessage('Failed loading source bitmap!');
   FreeAndNil(Image);
   Exit;
  end;

 // update some attributes
 PxFm.PatternCount:= (Image.Width div pSize.x) * (Image.Height div pSize.y);

 // create destination bitmap
 Dest:= TSystemSurface.Create();
 TileBitmap(Dest, Image, Point2px(PxFm.TextureWidth, PxFm.TextureHeight),
  pSize, pSize, IsMasked, MaskColor, Tolerance);

 // we don't need source image anymore
 FreeAndNil(Image);

 // calculate number of textures created
 PxFm.TextureCount:= Dest.Height div PxFm.TextureHeight;

 // create auxiliary stream to write PxFm-formatted image data
 Stream:= TMemoryStream.Create();
 WriteBitmapPxFm(Stream, Dest, PxFm);

 // we don't need destination image anymore
 FreeAndNil(Dest);

 // position to the beginning of our stream
 Stream.Seek(0, soFromBeginning);

 // write PxFm-formatted image data to Archive
 if (not Archive.WriteStream(Edit8.Text, Stream, artImage)) then
  begin
   ShowMessage('Failed writing stream to ASDb archive.');
  end else ShowMessage(Edit8.Text + ' key added!');

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
end.
