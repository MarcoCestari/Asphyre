unit Asphyre.Bitmaps;
//---------------------------------------------------------------------------
// Handler for loading different bitmap types.
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
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, System.Classes, Asphyre.TypeDef, Asphyre.Surfaces;

//---------------------------------------------------------------------------
type
 TAsphyreCustomBitmap = class
 protected
  FDesc: StdString;
 public
  property Desc: StdString read FDesc;

  function LoadFromStream(const Extension: StdString; Stream: TStream;
   Dest: TSystemSurface): Boolean; virtual; abstract;
  function SaveToStream(const Extension: StdString; Stream: TStream;
   Source: TSystemSurface): Boolean; virtual; abstract;

  constructor Create();
 end;

//---------------------------------------------------------------------------
 TBitmapAssociation = record
  Extension: StdString;
  Handler  : TAsphyreCustomBitmap;
 end;

//---------------------------------------------------------------------------
 TAsphyreBitmapManager = class
 private
  Associations: array of TBitmapAssociation;

  function FindExtension(const Extension: StdString): Integer;
  procedure RemoveAssociation(AsIndex: Integer);
 public
  function RegisterExt(const Extension: StdString;
   Handler: TAsphyreCustomBitmap): Boolean;
  procedure UnregisterExt(const Extension: StdString);

  function AssociatedHandler(const Extension: StdString): TAsphyreCustomBitmap;

  function LoadFromStream(const Extension: StdString; Stream: TStream;
   Dest: TSystemSurface): Boolean;
  function SaveToStream(const Extension: StdString; Stream: TStream;
   Source: TSystemSurface): Boolean;

  function LoadFromFile(const FileName: StdString;
   Dest: TSystemSurface): Boolean;
  function SaveToFile(const FileName: StdString;
   Source: TSystemSurface): Boolean;

  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 BitmapManager: TAsphyreBitmapManager = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreCustomBitmap.Create();
begin
 inherited;

 FDesc:= 'Unknown Bitmap';
end;

//---------------------------------------------------------------------------
destructor TAsphyreBitmapManager.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.FindExtension(
 const Extension: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Associations) - 1 do
  if (SameText(Associations[i].Extension, Extension)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.RegisterExt(const Extension: StdString;
 Handler: TAsphyreCustomBitmap): Boolean;
var
 AsIndex: Integer;
begin
 AsIndex:= FindExtension(Extension);
 Result:= (AsIndex = -1);
 if (not Result) then Exit;

 AsIndex:= Length(Associations);
 SetLength(Associations, AsIndex + 1);
 Associations[AsIndex].Extension:= Extension;
 Associations[AsIndex].Handler  := Handler;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBitmapManager.RemoveAssociation(AsIndex: Integer);
var
 i: Integer;
begin
 for i:= AsIndex to Length(Associations) - 2 do
  Associations[i]:= Associations[i + 1];

 SetLength(Associations, Length(Associations) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBitmapManager.UnregisterExt(const Extension: StdString);
var
 AsIndex: Integer;
begin
 AsIndex:= FindExtension(Extension);

 if (AsIndex <> -1) then
  RemoveAssociation(AsIndex);
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.AssociatedHandler(
 const Extension: StdString): TAsphyreCustomBitmap;
var
 Index: Integer;
begin
 Result:= nil;

 Index:= FindExtension(Extension);

 if (Index <> -1) then 
  Result:= Associations[Index].Handler;
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.LoadFromStream(const Extension: StdString;
 Stream: TStream; Dest: TSystemSurface): Boolean;
var
 Handler: TAsphyreCustomBitmap;
begin
 Handler:= AssociatedHandler(Extension);
 if (not Assigned(Handler)) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= Handler.LoadFromStream(Extension, Stream, Dest);
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.SaveToStream(const Extension: StdString;
 Stream: TStream; Source: TSystemSurface): Boolean;
var
 Handler: TAsphyreCustomBitmap;
begin
 Handler:= AssociatedHandler(Extension);
 if (not Assigned(Handler)) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= Handler.SaveToStream(Extension, Stream, Source);
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.LoadFromFile(const FileName: StdString;
 Dest: TSystemSurface): Boolean;
var
 Handler: TAsphyreCustomBitmap;
 InSt   : TFileStream;
begin
 Handler:= AssociatedHandler(ExtractFileExt(FileName));
 if (not Assigned(Handler)) then
  begin
   Result:= False;
   Exit;
  end;

 try
  InSt:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
 except
  Result:= False;
  Exit;
 end;

 Result:= Handler.LoadFromStream(ExtractFileExt(FileName), InSt, Dest);
 FreeAndNil(InSt);
end;

//---------------------------------------------------------------------------
function TAsphyreBitmapManager.SaveToFile(const FileName: StdString;
 Source: TSystemSurface): Boolean;
var
 Handler: TAsphyreCustomBitmap;
 OutSt  : TFileStream;
begin
 Handler:= AssociatedHandler(ExtractFileExt(FileName));
 if (not Assigned(Handler)) then
  begin
   Result:= False;
   Exit;
  end;

 try
  OutSt:= TFileStream.Create(FileName, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 Result:= Handler.SaveToStream(ExtractFileExt(FileName), OutSt, Source);
 FreeAndNil(OutSt);
end;

//---------------------------------------------------------------------------
initialization
 BitmapManager:= TAsphyreBitmapManager.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(BitmapManager);

//---------------------------------------------------------------------------
end.
