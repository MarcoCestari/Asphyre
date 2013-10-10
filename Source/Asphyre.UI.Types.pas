unit Asphyre.UI.Types;
//---------------------------------------------------------------------------
// General types and variables for Asphyre GUI framework.
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
{$if defined(Delphi) and defined(Windows)}
 Winapi.Windows, 
 
 {$ifdef FireMonkey}
  System.UITypes,
 {$else}
  Vcl.Controls,
 {$endif}
{$ifend}

{$if defined(FireMonkey) and (defined(MacOS) or defined(Android))}
 System.UITypes,
{$ifend}

{$ifdef fpc}
 LCLType, Controls,
{$endif}

{$ifndef fpc}
 System.Types, System.Classes, System.SysUtils,
{$else}
 Types, Classes, SysUtils,
{$endif}
 Asphyre.TypeDef,
 Asphyre.Math, Asphyre.Types, Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts;

//---------------------------------------------------------------------------
type
 TMouseEventType = (metDown, metUp, metMove, metClick, metDblClick, metEnter,
  metLeave, metWheelUp, metWheelDown);

//---------------------------------------------------------------------------
 TMouseButtonType = (mbtLeft, mbtRight, mbtMiddle, mbtNone);

//---------------------------------------------------------------------------
 TKeyEventType = (ketDown, ketUp, ketPress);

//---------------------------------------------------------------------------
 TGuiShiftState = set of (gssShift, gssAlt, gssCtrl);

//---------------------------------------------------------------------------
 TGuiMouseEvent = procedure(Sender: TObject; const MousePos: TPoint2px;
  Event: TMouseEventType; Button: TMouseButtonType;
  Shift: TGuiShiftState) of object;

//---------------------------------------------------------------------------
 TGuiKeyEvent = procedure(Sender: TObject; Key: Integer; Event: TKeyEventType;
  Shift: TGuiShiftState) of object;

//---------------------------------------------------------------------------
 PTextAlignType = ^TTextAlignType;
 TTextAlignType = (tatLeft, tatRight, tatCenter);

//---------------------------------------------------------------------------
 TGuiPropertyType = (gptUnknown, gptInteger, gptCardinal, gptFloat, gptString,
  gptBoolean, gptColor, gptStrings, gptColor2, gptColor4, gptAlignType);

//---------------------------------------------------------------------------
 TGuiPropertyFormat = (gpfUnknown, gpfShortInt, gpfByte, gpfSmallInt, gpfWord,
  gpfLongInt, gpfLongWord, gpfInteger, gpfCardinal, gpfSingle, gpfDouble,
  gpfReal, gpfShortString, gpfAnsiString, gpfStdString, gpfUniString,
  gpfByteBool, gpfWordBool, gpfLongBool, gpfBoolean, gpfInt64, gpfUInt64,
  gpfColor2, gpfColor4, gpfStrings, gpfAlignType);

//---------------------------------------------------------------------------
 TGuiPropertyRec = record
  Name    : StdString;
  PropType: TGuiPropertyType;
  Format  : TGuiPropertyFormat;
  DestPtr : Pointer;
  DestSize: Integer;
  PropTag : Integer;
 end;

//---------------------------------------------------------------------------
 TGuiObject = class
 private
  RefProps: array of TGuiPropertyRec;

  FieldTagCounter: Integer;

  function RetrieveInteger(const PropRec: TGuiPropertyRec): Integer;
  function RetrieveCardinal(const PropRec: TGuiPropertyRec): Cardinal;
  function RetrieveFloat(const PropRec: TGuiPropertyRec): Double;
  function RetrieveBoolean(const PropRec: TGuiPropertyRec): Boolean;
  function RetrieveString(const PropRec: TGuiPropertyRec): UniString;

  procedure StoreInteger(const PropRec: TGuiPropertyRec; Value: Integer);
  procedure StoreCardinal(const PropRec: TGuiPropertyRec; Value: Cardinal);
  procedure StoreFloat(const PropRec: TGuiPropertyRec; Value: Double);
  procedure StoreBoolean(const PropRec: TGuiPropertyRec; Value: Boolean);
  procedure StoreString(const PropRec: TGuiPropertyRec;
   const Value: UniString);

  function GetFieldCount(): Integer;
  function GetFieldName(Index: Integer): StdString;
  function GetFieldType(Index: Integer): TGuiPropertyType;

  function GetValueInteger(const Name: StdString): Integer;
  procedure SetValueInteger(const Name: StdString; Value: Integer);
  function GetValueCardinal(const Name: StdString): Cardinal;
  procedure SetValueCardinal(const Name: StdString; Value: Cardinal);
  function GetValueFloat(const Name: StdString): Double;
  procedure SetValueFloat(const Name: StdString; Value: Double);
  function GetValueBoolean(const Name: StdString): Boolean;
  procedure SetValueBoolean(const Name: StdString; Value: Boolean);
  function GetValueString(const Name: StdString): UniString;
  procedure SetValueString(const Name: StdString; const Value: UniString);
 protected
  FNameOfClass: StdString;

  procedure AddProperty(const Name: StdString; PropType: TGuiPropertyType;
   Format: TGuiPropertyFormat; DestPtr: Pointer; DestSize: Integer = 0;
   PropTag: Integer = 0);

  procedure SelfDescribe(); virtual;

  function NextFieldTag(): Integer;

  procedure BeforeChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer;
   var Proceed: Boolean); virtual;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); virtual;
 public
  property NameOfClass: StdString read FNameOfClass;

  property ValueInteger[const Name: StdString]: Integer read GetValueInteger
   write SetValueInteger;

  property ValueCardinal[const Name: StdString]: Cardinal read GetValueCardinal
   write SetValueCardinal;

  property ValueFloat[const Name: StdString]: Double read GetValueFloat
   write SetValueFloat;

  property ValueBoolean[const Name: StdString]: Boolean read GetValueBoolean
   write SetValueBoolean;

  property ValueString[const Name: StdString]: UniString read GetValueString
   write SetValueString;

  function GetCustomValue(const Name: StdString; Data: Pointer;
   DataSize: Integer): Boolean;

  function SetCustomValue(const Name: StdString; Data: Pointer;
   DataSize: Integer): Boolean;

  property FieldCount: Integer read GetFieldCount;
  property FieldName[Index: Integer]: StdString read GetFieldName;
  property FieldType[Index: Integer]: TGuiPropertyType read GetFieldType;

  function IndexOfProperty(const Name: StdString): Integer;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Asphyre virtual key codes.
//---------------------------------------------------------------------------
{$include Asphyre.UI.Keys.inc}

//---------------------------------------------------------------------------
// Globalized access to key Asphyre components.
//---------------------------------------------------------------------------
var
 GuiFonts : TAsphyreFonts  = nil;
 GuiImages: TAsphyreImages = nil;
 GuiCanvas: TAsphyreCanvas = nil;

 GuiPosGrid: TPoint2px = (x: 1; y: 1); // for moving GUI components
 GuiDesign : Boolean = False;          // whether GUI is in DESIGN mode

//---------------------------------------------------------------------------
function BooleanToStr(Value: Boolean): StdString;
function StrToBooleanDef(const Text: StdString;
 DefValue: Boolean = False): Boolean;

//---------------------------------------------------------------------------
function AlignTypeToStr(Value: TTextAlignType): StdString;
function StrToAlignTypeDef(const Value: StdString;
 DefValue: TTextAlignType = tatLeft): TTextAlignType;

//---------------------------------------------------------------------------
function ButtonToGui(Button: TMouseButton): TMouseButtonType;
function ShiftToGui(State: TShiftState): TGuiShiftState;
function ExchangeColors(const Colors: TColor4): TColor4;
function RectExtrude(const Rect: TRect): TPoint4;
function SineTheta(Theta: Single): Single;

//---------------------------------------------------------------------------
function GuiEncodeMousePos(const MousePos: TPoint2px): Integer;
function GuiDecodeMousePos(Value: Integer): TPoint2px;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.Math,
{$else}
 Math,
{$endif}
 Asphyre.Data;

//---------------------------------------------------------------------------
type
 PReal     = ^Real;
 PByteBool = ^ByteBool;
 PWordBool = ^WordBool;
 PLongBool = ^LongBool;
 PUInt64   = ^UInt64;

//---------------------------------------------------------------------------
var
 Base64Buf: packed array[0..65535] of Byte;

//---------------------------------------------------------------------------
function BooleanToStr(Value: Boolean): StdString;
begin
 if (Value) then
  Result:= 'true'
   else Result:= 'false';
end;

//---------------------------------------------------------------------------
function StrToBooleanDef(const Text: StdString;
 DefValue: Boolean = False): Boolean;
begin
 Result:= DefValue;

 if (SameText(Text, 'true'))or(SameText(Text, 'yes')) then
  begin
   Result:= True;
   Exit;
  end;

 if (Result)and((SameText(Text, 'false'))or(SameText(Text, 'no'))) then
  Result:= False;
end;

//---------------------------------------------------------------------------
function AlignTypeToStr(Value: TTextAlignType): StdString;
begin
 case Value of
  tatLeft  : Result:= 'tatLeft';
  tatRight : Result:= 'tatRight';
  tatCenter: Result:= 'tatCenter';
  else Result:= '';
 end;
end;

//---------------------------------------------------------------------------
function StrToAlignTypeDef(const Value: StdString;
 DefValue: TTextAlignType = tatLeft): TTextAlignType;
begin
 Result:= DefValue;

 if (SameText(Value, 'tatLeft')) then Result:= tatLeft;
 if (SameText(Value, 'tatRight')) then Result:= tatRight;
 if (SameText(Value, 'tatCenter')) then Result:= tatCenter;
end;

//---------------------------------------------------------------------------
function CardinalMin(Value, MinValue: Cardinal): Cardinal;
begin
 Result:= Value;
 if (Result > MinValue) then Result:= MinValue;
end;

//---------------------------------------------------------------------------
{$ifdef StandardStringsOnly}
procedure SafeBase64Binary(Source: StdString; Dest: Pointer; MaxDestSize: Integer);
{$else}
procedure SafeBase64Binary(Source: AnsiString; Dest: Pointer;
 MaxDestSize: Integer);
{$endif}
var
 MaxSrcSize, SrcSize: Integer;
begin
 MaxSrcSize:= Ceil(MaxDestSize / 3.0) * 4 + 3;

 if (Length(Source) > MaxSrcSize) then
  SetLength(Source, MaxSrcSize);

 if (MaxDestSize < 65536) then
  begin
   FillChar(Dest^, MaxDestSize, 0);

   SrcSize:= Base64Binary(Source, @Base64Buf[0]);
   Move(Base64Buf[0], Dest^, Min2(SrcSize, MaxDestSize));
  end else
  begin
   FillChar(Dest^, MaxDestSize, 0);
   Base64Binary(Source, Dest);
  end;
end;

//---------------------------------------------------------------------------
function ButtonToGui(Button: TMouseButton): TMouseButtonType;
begin
 Result:= mbtNone;
 case Button of
 {$ifdef FireMonkey}
  TMouseButton.mbLeft  : Result:= mbtLeft;
  TMouseButton.mbRight : Result:= mbtRight;
  TMouseButton.mbMiddle: Result:= mbtMiddle;
 {$else}
  mbLeft  : Result:= mbtLeft;
  mbRight : Result:= mbtRight;
  mbMiddle: Result:= mbtMiddle;
 {$endif}
 end;
end;

//---------------------------------------------------------------------------
function ShiftToGui(State: TShiftState): TGuiShiftState;
begin
 Result:= [];

 if (ssShift in State) then Result:= Result + [gssShift];
 if (ssCtrl in State) then Result:= Result + [gssCtrl];
 if (ssAlt in State) then Result:= Result + [gssAlt];
end;

//---------------------------------------------------------------------------
function ExchangeColors(const Colors: TColor4): TColor4;
begin
 Result[0]:= Colors[3];
 Result[1]:= Colors[2];
 Result[2]:= Colors[1];
 Result[3]:= Colors[0];
end;

//---------------------------------------------------------------------------
function RectExtrude(const Rect: TRect): TPoint4;
begin
 Result:= pBounds4(Rect.Left + 1, Rect.Top + 1, (Rect.Right - Rect.Left) - 2,
  (Rect.Bottom - Rect.Top) - 2);
end;

//---------------------------------------------------------------------------
function SineTheta(Theta: Single): Single;
begin
 Result:= (Sin(Theta * Pi - Pi * 0.5) + 1.0) * 0.5;
end;

//---------------------------------------------------------------------------
function GuiEncodeMousePos(const MousePos: TPoint2px): Integer;
begin
 Cardinal(Result):=
  Cardinal(MinMax2(MousePos.x + 32768, 0, 65535)) or
  Cardinal(MinMax2(MousePos.y + 32768, 0, 65535) shl 16);
end;

//---------------------------------------------------------------------------
function GuiDecodeMousePos(Value: Integer): TPoint2px;
begin
 Result.x:= Integer(Cardinal(Value) and $FFFF) - 32768;
 Result.y:= Integer(Cardinal(Value) shr 16) - 32768;
end;

//---------------------------------------------------------------------------
constructor TGuiObject.Create();
begin
 inherited;

 FieldTagCounter:= 1;
 SelfDescribe();
end;

//---------------------------------------------------------------------------
destructor TGuiObject.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiObject.IndexOfProperty(const Name: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(RefProps) - 1 do
  if (SameText(RefProps[i].Name, Name)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TGuiObject.NextFieldTag(): Integer;
begin
 Result:= FieldTagCounter;
 Inc(FieldTagCounter);
end;

//---------------------------------------------------------------------------
procedure TGuiObject.AddProperty(const Name: StdString;
 PropType: TGuiPropertyType; Format: TGuiPropertyFormat; DestPtr: Pointer;
 DestSize: Integer = 0; PropTag: Integer = 0);
var
 Index: Integer;
begin
 if (not Assigned(DestPtr)) then Exit;

 Index:= IndexOfProperty(Name);
 if (Index = -1) then
  begin
   Index:= Length(RefProps);
   SetLength(RefProps, Index + 1);
  end;

 RefProps[Index].Name    := Name;
 RefProps[Index].PropType:= PropType;
 RefProps[Index].Format  := Format;
 RefProps[Index].DestPtr := DestPtr;
 RefProps[Index].DestSize:= DestSize;
 RefProps[Index].PropTag := PropTag;
end;

//---------------------------------------------------------------------------
function TGuiObject.RetrieveInteger(const PropRec: TGuiPropertyRec): Integer;
begin
 Result:= 0;

 case PropRec.Format of
  gpfShortInt: Result:= PShortInt(PropRec.DestPtr)^;
  gpfByte: Result:= PByte(PropRec.DestPtr)^;
  gpfSmallInt: Result:= PSmallInt(PropRec.DestPtr)^;
  gpfWord: Result:= PWord(PropRec.DestPtr)^;
  gpfLongInt : Result:= PLongInt(PropRec.DestPtr)^;
  gpfLongWord: Result:= Integer(PLongWord(PropRec.DestPtr)^);
  gpfInteger : Result:= PInteger(PropRec.DestPtr)^;
  gpfCardinal: Result:= Integer(PCardinal(PropRec.DestPtr)^);
  gpfSingle  : Result:= Round(PSingle(PropRec.DestPtr)^);
  gpfDouble  : Result:= Round(PDouble(PropRec.DestPtr)^);
  gpfReal    : Result:= Round(PReal(PropRec.DestPtr)^);

 {$ifndef StandardStringsOnly}
  gpfShortString:
   Result:= StrToIntDef(StdString(PShortString(PropRec.DestPtr)^), 0);

  gpfAnsiString:
   Result:= StrToIntDef(StdString(PAnsiString(PropRec.DestPtr)^), 0);
 {$endif}

  gpfStdString:
   Result:= StrToIntDef(PStdString(PropRec.DestPtr)^, 0);

  gpfUniString:
   Result:= StrToIntDef(PUniString(PropRec.DestPtr)^, 0);

  gpfByteBool: Result:= Ord(PByteBool(PropRec.DestPtr)^);
  gpfWordBool: Result:= Ord(PWordBool(PropRec.DestPtr)^);
  gpfLongBool: Result:= Ord(PLongBool(PropRec.DestPtr)^);
  gpfBoolean : Result:= Ord(PBoolean(PropRec.DestPtr)^);
  gpfInt64 : Result:= Integer(PInt64(PropRec.DestPtr)^);
  gpfUInt64: Result:= Integer(PUInt64(PropRec.DestPtr)^);

  gpfColor2:
   Result:= Integer(Cardinal(AvgPixels(PColor2(PropRec.DestPtr)[0],
    PColor2(PropRec.DestPtr)[1])));

  gpfColor4:
   Result:= Integer(Cardinal(AvgFourPixels(PColor4(PropRec.DestPtr)[0],
    PColor4(PropRec.DestPtr)[1], PColor4(PropRec.DestPtr)[2],
    PColor4(PropRec.DestPtr)[3])));

  gpfStrings: Result:= StrToIntDef(TStrings(PropRec.DestPtr).Text, 0);

  gpfAlignType: Result:= Integer(PTextAlignType(PropRec.DestPtr)^);

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: Result:= PByte(PropRec.DestPtr)^;
      2: Result:= PWord(PropRec.DestPtr)^;
      3: Result:=
       Integer(PWord(PropRec.DestPtr)^) or
       (Integer(PByte(Integer(PropRec.DestPtr) + 2)^) shl 16);
      4: Result:= PInteger(PropRec.DestPtr)^;
     end else Result:= PInteger(PropRec.DestPtr)^;
   end;
 end;
end;

//---------------------------------------------------------------------------
function TGuiObject.RetrieveCardinal(const PropRec: TGuiPropertyRec): Cardinal;
begin
 Result:= 0;

 case PropRec.Format of
  gpfShortInt: Result:= Byte(PShortInt(PropRec.DestPtr)^);
  gpfByte: Result:= PByte(PropRec.DestPtr)^;
  gpfSmallInt: Result:= Word(PSmallInt(PropRec.DestPtr)^);
  gpfWord: Result:= PWord(PropRec.DestPtr)^;
  gpfLongInt : Result:= LongWord(PLongInt(PropRec.DestPtr)^);
  gpfLongWord: Result:= PLongWord(PropRec.DestPtr)^;
  gpfInteger : Result:= Cardinal(PInteger(PropRec.DestPtr)^);
  gpfCardinal: Result:= PCardinal(PropRec.DestPtr)^;
  gpfSingle  : Result:= Round(PSingle(PropRec.DestPtr)^);
  gpfDouble  : Result:= Round(PDouble(PropRec.DestPtr)^);
  gpfReal    : Result:= Round(PReal(PropRec.DestPtr)^);

 {$ifndef StandardStringsOnly}
  gpfShortString:
   Result:= StrToIntDef(StdString(PShortString(PropRec.DestPtr)^), 0);

  gpfAnsiString:
   Result:= StrToIntDef(StdString(PAnsiString(PropRec.DestPtr)^), 0);
 {$endif}

  gpfStdString: Result:= StrToIntDef(PStdString(PropRec.DestPtr)^, 0);
  gpfUniString: Result:= StrToIntDef(PUniString(PropRec.DestPtr)^, 0);

  gpfByteBool: Result:= Ord(PByteBool(PropRec.DestPtr)^);
  gpfWordBool: Result:= Ord(PWordBool(PropRec.DestPtr)^);
  gpfLongBool: Result:= Ord(PLongBool(PropRec.DestPtr)^);
  gpfBoolean : Result:= Ord(PBoolean(PropRec.DestPtr)^);

  gpfInt64 : Result:= Cardinal(PInt64(PropRec.DestPtr)^);
  gpfUInt64: Result:= Cardinal(PUInt64(PropRec.DestPtr)^);

  gpfColor2:
   Result:= AvgPixels(PColor2(PropRec.DestPtr)[0], PColor2(PropRec.DestPtr)[1]);

  gpfColor4:
   Result:= AvgFourPixels(PColor4(PropRec.DestPtr)[0],
    PColor4(PropRec.DestPtr)[1], PColor4(PropRec.DestPtr)[2],
    PColor4(PropRec.DestPtr)[3]);

  gpfStrings: Result:= StrToIntDef(TStrings(PropRec.DestPtr).Text, 0);

  gpfAlignType: Result:= Cardinal(PTextAlignType(PropRec.DestPtr)^);

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: Result:= PByte(PropRec.DestPtr)^;
      2: Result:= PWord(PropRec.DestPtr)^;
      3: Result:=
       Cardinal(PWord(PropRec.DestPtr)^) or
       (Cardinal(PByte(Integer(PropRec.DestPtr) + 2)^) shl 16);
      4: Result:= PCardinal(PropRec.DestPtr)^;
     end else Result:= PCardinal(PropRec.DestPtr)^
   end;
 end;
end;

//---------------------------------------------------------------------------
function TGuiObject.RetrieveFloat(const PropRec: TGuiPropertyRec): Double;
begin
 Result:= 0.0;

 case PropRec.Format of
  gpfShortInt: Result:= PShortInt(PropRec.DestPtr)^;
  gpfByte: Result:= PByte(PropRec.DestPtr)^;
  gpfSmallInt: Result:= PSmallInt(PropRec.DestPtr)^;
  gpfWord: Result:= PWord(PropRec.DestPtr)^;
  gpfLongInt : Result:= PLongInt(PropRec.DestPtr)^;
  gpfLongWord: Result:= PLongWord(PropRec.DestPtr)^;
  gpfInteger : Result:= PInteger(PropRec.DestPtr)^;
  gpfCardinal: Result:= PCardinal(PropRec.DestPtr)^;
  gpfSingle  : Result:= PSingle(PropRec.DestPtr)^;
  gpfDouble  : Result:= PDouble(PropRec.DestPtr)^;
  gpfReal    : Result:= PReal(PropRec.DestPtr)^;

 {$ifndef StandardStringsOnly}
  gpfShortString:
   Result:= StrToFloatDef(StdString(PShortString(PropRec.DestPtr)^), 0.0);

  gpfAnsiString:
   Result:= StrToFloatDef(StdString(PAnsiString(PropRec.DestPtr)^), 0.0);
 {$endif}

  gpfStdString: Result:= StrToFloatDef(PStdString(PropRec.DestPtr)^, 0.0);
  gpfUniString: Result:= StrToFloatDef(PUniString(PropRec.DestPtr)^, 0.0);

  gpfByteBool: Result:= Ord(PByteBool(PropRec.DestPtr)^);
  gpfWordBool: Result:= Ord(PWordBool(PropRec.DestPtr)^);
  gpfLongBool: Result:= Ord(PLongBool(PropRec.DestPtr)^);
  gpfBoolean : Result:= Ord(PBoolean(PropRec.DestPtr)^);

  gpfInt64 : Result:= PInt64(PropRec.DestPtr)^;
  gpfUInt64: Result:= PUInt64(PropRec.DestPtr)^;

  gpfColor2:
   Result:= PixelToGrayEx(AvgPixels(PColor2(PropRec.DestPtr)[0],
    PColor2(PropRec.DestPtr)[1]));

  gpfColor4:
   Result:= PixelToGrayEx(AvgFourPixels(PColor4(PropRec.DestPtr)[0],
    PColor4(PropRec.DestPtr)[1], PColor4(PropRec.DestPtr)[2],
    PColor4(PropRec.DestPtr)[3]));

  gpfStrings: Result:= StrToFloatDef(TStrings(PropRec.DestPtr).Text, 0.0);

  gpfAlignType: Result:= Integer(PTextAlignType(PropRec.DestPtr)^);

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: Result:= PByte(PropRec.DestPtr)^;
      2: Result:= PWord(PropRec.DestPtr)^;
      3: Result:=
       Cardinal(PWord(PropRec.DestPtr)^) or
       (Cardinal(PByte(Integer(PropRec.DestPtr) + 2)^) shl 16);
      4: Result:= PCardinal(PropRec.DestPtr)^;
     end else Result:= PCardinal(PropRec.DestPtr)^
   end;
 end;
end;

//---------------------------------------------------------------------------
function TGuiObject.RetrieveBoolean(const PropRec: TGuiPropertyRec): Boolean;
begin
 Result:= False;

 case PropRec.Format of
  gpfShortInt,
  gpfByte,
  gpfSmallInt,
  gpfWord,
  gpfLongInt,
  gpfLongWord,
  gpfInteger,
  gpfCardinal,
  gpfInt64,
  gpfUInt64,
  gpfAlignType,
  gpfUnknown:
   Result:= RetrieveInteger(PropRec) <> 0;

  gpfSingle,
  gpfDouble,
  gpfReal:
   Result:= RetrieveCardinal(PropRec) <> 0.0;

  gpfShortString,
  gpfAnsiString,
  gpfStdString,
  gpfUniString,
  gpfStrings:
   Result:= StrToBooleanDef(RetrieveString(PropRec));

  gpfByteBool: Result:= PByteBool(PropRec.DestPtr)^;
  gpfWordBool: Result:= PWordBool(PropRec.DestPtr)^;
  gpfLongBool: Result:= PLongBool(PropRec.DestPtr)^;
  gpfBoolean : Result:= PBoolean(PropRec.DestPtr)^;

  gpfColor2:
   Result:=
    (PColor2(PropRec.DestPtr)[0] <> 0)and
    (PColor2(PropRec.DestPtr)[1] <> 0);

  gpfColor4:
   Result:=
    (PColor4(PropRec.DestPtr)[0] <> 0)and
    (PColor4(PropRec.DestPtr)[1] <> 0)and
    (PColor4(PropRec.DestPtr)[2] <> 0)and
    (PColor4(PropRec.DestPtr)[3] <> 0);
 end;
end;

//---------------------------------------------------------------------------
function TGuiObject.RetrieveString(const PropRec: TGuiPropertyRec): UniString;
begin
 Result:= '';

 case PropRec.Format of
  gpfShortInt: Result:= '$' + IntToHex(PShortInt(PropRec.DestPtr)^, 2);
  gpfByte: Result:= '$' + IntToHex(PByte(PropRec.DestPtr)^, 2);
  gpfSmallInt: Result:= '$' + IntToHex(PSmallInt(PropRec.DestPtr)^, 4);
  gpfWord: Result:= '$' + IntToHex(PWord(PropRec.DestPtr)^, 4);
  gpfLongInt : Result:= '$' + IntToHex(PLongInt(PropRec.DestPtr)^, 8);
  gpfLongWord: Result:= '$' + IntToHex(PLongWord(PropRec.DestPtr)^, 8);
  gpfInteger : Result:= '$' + IntToHex(PInteger(PropRec.DestPtr)^, 8);
  gpfCardinal: Result:= '$' + IntToHex(PCardinal(PropRec.DestPtr)^, 8);

  gpfSingle  : Result:= FloatToStr(PSingle(PropRec.DestPtr)^);     
  gpfDouble  : Result:= FloatToStr(PDouble(PropRec.DestPtr)^);
  gpfReal    : Result:= FloatToStr(PReal(PropRec.DestPtr)^);

 {$ifndef StandardStringsOnly}
  gpfShortString: Result:= StdString(PShortString(PropRec.DestPtr)^);
  gpfAnsiString : Result:= StdString(PAnsiString(PropRec.DestPtr)^);
 {$endif}

  gpfStdString: Result:= PStdString(PropRec.DestPtr)^;
  gpfUniString: Result:= PUniString(PropRec.DestPtr)^;

  gpfBoolean : Result:= BooleanToStr(PBoolean(PropRec.DestPtr)^);
  gpfByteBool: Result:= BooleanToStr(PByteBool(PropRec.DestPtr)^);
  gpfWordBool: Result:= BooleanToStr(PWordBool(PropRec.DestPtr)^);
  gpfLongBool: Result:= BooleanToStr(PLongBool(PropRec.DestPtr)^);
  gpfInt64 : Result:= '$' + IntToHex(PInt64(PropRec.DestPtr)^, 16);
  gpfUInt64: Result:= '$' + IntToHex(PUInt64(PropRec.DestPtr)^, 16);

  gpfColor2:
   Result:= StdString(Base64String(PropRec.DestPtr, SizeOf(TColor2)));

  gpfColor4:
   Result:= StdString(Base64String(PropRec.DestPtr, SizeOf(TColor4)));

  gpfStrings: Result:= TStrings(PropRec.DestPtr).Text;

  gpfAlignType: Result:= AlignTypeToStr(PTextAlignType(PropRec.DestPtr)^);

  gpfUnknown:
   Result:= StdString(Base64String(PropRec.DestPtr, PropRec.DestSize));
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.StoreInteger(const PropRec: TGuiPropertyRec;
 Value: Integer);
begin
 case PropRec.Format of
  gpfShortInt: PShortInt(PropRec.DestPtr)^:= MinMax2(Value, -128, 127);
  gpfByte: PByte(PropRec.DestPtr)^:= MinMax2(Value, 0, 255);
  gpfSmallInt: PSmallInt(PropRec.DestPtr)^:= MinMax2(Value, -32768, 32767);
  gpfWord: PWord(PropRec.DestPtr)^:= MinMax2(Value, 0, 65535);
  gpfLongInt : PLongInt(PropRec.DestPtr)^:= LongInt(Value);
  gpfLongWord: PLongWord(PropRec.DestPtr)^:= LongWord(Value);
  gpfInteger : PInteger(PropRec.DestPtr)^:= Value;
  gpfCardinal: PCardinal(PropRec.DestPtr)^:= Cardinal(Value);
  gpfSingle  : PSingle(PropRec.DestPtr)^:= Value;
  gpfDouble  : PDouble(PropRec.DestPtr)^:= Value;
  gpfReal    : PReal(PropRec.DestPtr)^:= Value;

 {$ifndef StandardStringsOnly}
  gpfShortString:
   PShortString(PropRec.DestPtr)^:= ShortString('$' + IntToHex(Value, 0));

  gpfAnsiString:
   PAnsiString(PropRec.DestPtr)^:= AnsiString('$' + IntToHex(Value, 0));
 {$endif}

  gpfStdString: PStdString(PropRec.DestPtr)^:= '$' + IntToHex(Value, 0);
  gpfUniString: PUniString(PropRec.DestPtr)^:= '$' + IntToHex(Value, 0);

  gpfByteBool: PByteBool(PropRec.DestPtr)^:= Value <> 0;
  gpfWordBool: PWordBool(PropRec.DestPtr)^:= Value <> 0;
  gpfLongBool: PLongBool(PropRec.DestPtr)^:= Value <> 0;
  gpfBoolean : PBoolean(PropRec.DestPtr)^:= Value <> 0;

  gpfInt64 : PInt64(PropRec.DestPtr)^:= Value;
  gpfUInt64: PUInt64(PropRec.DestPtr)^:= Value;

  gpfColor2:
   begin
    PColor2(PropRec.DestPtr)[0]:= Cardinal(Value);
    PColor2(PropRec.DestPtr)[1]:= Cardinal(Value);
   end;

  gpfColor4:
   begin
    PColor4(PropRec.DestPtr)[0]:= Cardinal(Value);
    PColor4(PropRec.DestPtr)[1]:= Cardinal(Value);
    PColor4(PropRec.DestPtr)[2]:= Cardinal(Value);
    PColor4(PropRec.DestPtr)[3]:= Cardinal(Value);
   end;

  gpfStrings: TStrings(PropRec.DestPtr).Text:= '$' + IntToHex(Value, 0);

  gpfAlignType: PTextAlignType(PropRec.DestPtr)^:=
   TTextAlignType(MinMax2(Value, 0, Integer(High(TTextAlignType))));

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: PByte(PropRec.DestPtr)^:= MinMax2(Value, 0, 255);
      2: PWord(PropRec.DestPtr)^:= MinMax2(Value, 0, 65535);
      3: // 24-bits
       begin
        Value:= MinMax2(Value, 0, 16777215);
        Move(Value, PropRec.DestPtr^, 3);
       end;
      4: PInteger(PropRec.DestPtr)^:= Value;
     end else
     begin
      FillChar(PropRec.DestPtr^, PropRec.DestSize, 0);
      PInteger(PropRec.DestPtr)^:= Value;
     end;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.StoreCardinal(const PropRec: TGuiPropertyRec;
 Value: Cardinal);
begin
 case PropRec.Format of
  gpfShortInt: PShortInt(PropRec.DestPtr)^:= CardinalMin(Value, 127);
  gpfByte: PByte(PropRec.DestPtr)^:= CardinalMin(Value, 255);
  gpfSmallInt: PSmallInt(PropRec.DestPtr)^:= CardinalMin(Value, 32767);
  gpfWord: PWord(PropRec.DestPtr)^:= CardinalMin(Value, 65535);
  gpfLongInt : PLongInt(PropRec.DestPtr)^:= LongInt(Value);
  gpfLongWord: PLongWord(PropRec.DestPtr)^:= LongWord(Value);
  gpfInteger : PInteger(PropRec.DestPtr)^:= Integer(Value);
  gpfCardinal: PCardinal(PropRec.DestPtr)^:= Value;
  gpfSingle  : PSingle(PropRec.DestPtr)^:= Value;
  gpfDouble  : PDouble(PropRec.DestPtr)^:= Value;
  gpfReal    : PReal(PropRec.DestPtr)^:= Value;

 {$ifndef StandardStringsOnly}
  gpfShortString:
   PShortString(PropRec.DestPtr)^:= ShortString('$' + IntToHex(Value, 0));

  gpfAnsiString:
   PAnsiString(PropRec.DestPtr)^:= AnsiString('$' + IntToHex(Value, 0));
 {$endif}

  gpfStdString: PStdString(PropRec.DestPtr)^:= '$' + IntToHex(Value, 0);
  gpfUniString: PStdString(PropRec.DestPtr)^:= '$' + IntToHex(Value, 0);

  gpfBoolean : PBoolean(PropRec.DestPtr)^:= Value <> 0;
  gpfByteBool: PByteBool(PropRec.DestPtr)^:= Value <> 0;
  gpfWordBool: PWordBool(PropRec.DestPtr)^:= Value <> 0;
  gpfLongBool: PLongBool(PropRec.DestPtr)^:= Value <> 0;
  gpfInt64 : PInt64(PropRec.DestPtr)^:= Value;
  gpfUInt64: PUInt64(PropRec.DestPtr)^:= Value;

  gpfColor2:
   begin
    PColor2(PropRec.DestPtr)[0]:= Value;
    PColor2(PropRec.DestPtr)[1]:= Value;
   end;

  gpfColor4:
   begin
    PColor4(PropRec.DestPtr)[0]:= Value;
    PColor4(PropRec.DestPtr)[1]:= Value;
    PColor4(PropRec.DestPtr)[2]:= Value;
    PColor4(PropRec.DestPtr)[3]:= Value;
   end;

  gpfStrings: TStrings(PropRec.DestPtr).Text:= '$' + IntToHex(Value, 0);

  gpfAlignType: PTextAlignType(PropRec.DestPtr)^:=
   TTextAlignType(MinMax2(Value, 0, Cardinal(High(TTextAlignType))));

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: PByte(PropRec.DestPtr)^:= CardinalMin(Value, 255);
      2: PWord(PropRec.DestPtr)^:= CardinalMin(Value, 65535);
      3: // 24-bits
       begin
        Value:= MinMax2(Value, 0, 16777215);
        Move(Value, PropRec.DestPtr^, 3);
       end;
      4: PCardinal(PropRec.DestPtr)^:= Value;
     end else
     begin
      FillChar(PropRec.DestPtr^, PropRec.DestSize, 0);
      PCardinal(PropRec.DestPtr)^:= Value;
     end;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.StoreFloat(const PropRec: TGuiPropertyRec; Value: Double);
var
 Value24: Integer;
 ColorValue: Cardinal;
begin
 case PropRec.Format of
  gpfShortInt: PShortInt(PropRec.DestPtr)^:= MinMax2(Round(Value), -128, 127);
  gpfByte: PByte(PropRec.DestPtr)^:= MinMax2(Round(Value), 0, 255);

  gpfSmallInt:
   PSmallInt(PropRec.DestPtr)^:= MinMax2(Round(Value), -32768, 32767);

  gpfWord: PWord(PropRec.DestPtr)^:= MinMax2(Round(Value), 0, 65535);
  gpfLongInt : PLongInt(PropRec.DestPtr)^:= Round(Value);
  gpfLongWord: PLongWord(PropRec.DestPtr)^:= Round(Value);
  gpfInteger : PInteger(PropRec.DestPtr)^:= Round(Value);
  gpfCardinal: PCardinal(PropRec.DestPtr)^:= Round(Value);

  gpfSingle  : PSingle(PropRec.DestPtr)^:= Value;
  gpfDouble  : PDouble(PropRec.DestPtr)^:= Value;
  gpfReal    : PReal(PropRec.DestPtr)^:= Value;

 {$ifndef StandardStringsOnly}
  gpfShortString:
   PShortString(PropRec.DestPtr)^:= ShortString(FloatToStr(Value));

  gpfAnsiString:
   PAnsiString(PropRec.DestPtr)^:= AnsiString(FloatToStr(Value));
 {$endif}

  gpfStdString: PStdString(PropRec.DestPtr)^:= FloatToStr(Value);
  gpfUniString: PStdString(PropRec.DestPtr)^:= FloatToStr(Value);

  gpfByteBool: PByteBool(PropRec.DestPtr)^:= Value <> 0.0;
  gpfWordBool: PWordBool(PropRec.DestPtr)^:= Value <> 0.0;
  gpfLongBool: PLongBool(PropRec.DestPtr)^:= Value <> 0.0;
  gpfBoolean : PBoolean(PropRec.DestPtr)^:= Value <> 0.0;

  gpfInt64 : PInt64(PropRec.DestPtr)^:= Round(Value);
  gpfUInt64: PUInt64(PropRec.DestPtr)^:= Round(Value);

  gpfColor2:
   begin
    ColorValue:= Round(Value * 255.0);
    ColorValue:= ColorValue or (ColorValue shl 8) or (ColorValue shl 16) or
     $FF000000;

    PColor2(PropRec.DestPtr)[0]:= ColorValue;
    PColor2(PropRec.DestPtr)[1]:= ColorValue;
   end;

  gpfColor4:
   begin
    ColorValue:= Round(Value * 255.0);
    ColorValue:= ColorValue or (ColorValue shl 8) or (ColorValue shl 16) or
     $FF000000;

    PColor4(PropRec.DestPtr)[0]:= ColorValue;
    PColor4(PropRec.DestPtr)[1]:= ColorValue;
    PColor4(PropRec.DestPtr)[2]:= ColorValue;
    PColor4(PropRec.DestPtr)[3]:= ColorValue;
   end;

  gpfStrings: TStrings(PropRec.DestPtr).Text:= FloatToStr(Value);

  gpfAlignType: PTextAlignType(PropRec.DestPtr)^:=
   TTextAlignType(MinMax2(Round(Value), 0, Integer(High(TTextAlignType))));

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: PByte(PropRec.DestPtr)^:= MinMax2(Round(Value), 0, 255);
      2: PWord(PropRec.DestPtr)^:= MinMax2(Round(Value), 0, 65535);
      3: // 24-bits
       begin
        Value24:= MinMax2(Round(Value), 0, 16777215);
        Move(Value24, PropRec.DestPtr^, 3);
       end;
      4: PSingle(PropRec.DestPtr)^:= Value;
     end else
     begin
      FillChar(PropRec.DestPtr^, PropRec.DestSize, 0);
      PSingle(PropRec.DestPtr)^:= Value;
     end;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.StoreBoolean(const PropRec: TGuiPropertyRec;
 Value: Boolean);
var
 Color  : Cardinal;
 Value24: LongBool;
begin
 case PropRec.Format of
  gpfShortInt,
  gpfByte,
  gpfSmallInt,
  gpfWord,
  gpfLongInt,
  gpfLongWord,
  gpfInteger,
  gpfCardinal,
  gpfInt64,
  gpfUInt64,
  gpfAlignType:
   StoreInteger(PropRec, Ord(Value));

  gpfSingle,
  gpfDouble,
  gpfReal:
   StoreFloat(PropRec, Ord(Value));

 {$ifndef StandardStringsOnly}
  gpfShortString:
   PShortString(PropRec.DestPtr)^:= ShortString(BooleanToStr(Value));

  gpfAnsiString:
   PAnsiString(PropRec.DestPtr)^:= AnsiString(BooleanToStr(Value));
 {$endif}

  gpfStdString: PStdString(PropRec.DestPtr)^:= BooleanToStr(Value);
  gpfUniString: PUniString(PropRec.DestPtr)^:= BooleanToStr(Value);

  gpfByteBool: PByteBool(PropRec.DestPtr)^:= Value;
  gpfWordBool: PWordBool(PropRec.DestPtr)^:= Value;
  gpfLongBool: PLongBool(PropRec.DestPtr)^:= Value;
  gpfBoolean : PBoolean(PropRec.DestPtr)^:= Value;

  gpfColor2:
   begin
    if (Value) then Color:= $FFFFFFFF else Color:= 0;

    PColor2(PropRec.DestPtr)[0]:= Color;
    PColor2(PropRec.DestPtr)[1]:= Color;
   end;

  gpfColor4:
   begin
    if (Value) then Color:= $FFFFFFFF else Color:= 0;

    PColor4(PropRec.DestPtr)[0]:= Color;
    PColor4(PropRec.DestPtr)[1]:= Color;
    PColor4(PropRec.DestPtr)[2]:= Color;
    PColor4(PropRec.DestPtr)[3]:= Color;
   end;

  gpfStrings: TStrings(PropRec.DestPtr).Text:= BooleanToStr(Value);

  gpfUnknown:
   begin
    if (PropRec.DestSize <= 4) then
     case PropRec.DestSize of
      1: PByteBool(PropRec.DestPtr)^:= Value;
      2: PWordBool(PropRec.DestPtr)^:= Value;
      3: // 24-bits
       begin
        Value24:= LongBool(Value);
        Move(Value24, PropRec.DestPtr^, 3);
       end;
      4: PLongBool(PropRec.DestPtr)^:= Value;
     end else
     begin
      FillChar(PropRec.DestPtr^, PropRec.DestSize, 0);
      PLongBool(PropRec.DestPtr)^:= Value;
     end;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.StoreString(const PropRec: TGuiPropertyRec;
 const Value: UniString);
begin
 case PropRec.Format of
  gpfShortInt,
  gpfByte,
  gpfSmallInt,
  gpfWord,
  gpfLongInt,
  gpfLongWord,
  gpfInteger,
  gpfCardinal,
  gpfInt64,
  gpfUInt64:
   StoreInteger(PropRec, StrToIntDef(Value, 0));

  gpfSingle,
  gpfDouble,
  gpfReal:
   StoreFloat(PropRec, StrToFloatDef(Value, 0.0));

 {$ifndef StandardStringsOnly}
  gpfShortString: PShortString(PropRec.DestPtr)^:= ShortString(Value);
  gpfAnsiString : PAnsiString(PropRec.DestPtr)^:= AnsiString(Value);
 {$endif}

  gpfStdString  : PStdString(PropRec.DestPtr)^:= Value;
  gpfUniString  : PUniString(PropRec.DestPtr)^:= Value;

  gpfByteBool: PByteBool(PropRec.DestPtr)^:= StrToBooleanDef(Value);
  gpfWordBool: PWordBool(PropRec.DestPtr)^:= StrToBooleanDef(Value);
  gpfLongBool: PLongBool(PropRec.DestPtr)^:= StrToBooleanDef(Value);
  gpfBoolean : PBoolean(PropRec.DestPtr)^:= StrToBooleanDef(Value);

 {$ifndef StandardStringsOnly}
  gpfColor2:
   SafeBase64Binary(AnsiString(Value), PropRec.DestPtr, SizeOf(TColor2));

  gpfColor4:
   SafeBase64Binary(AnsiString(Value), PropRec.DestPtr, SizeOf(TColor4));
 {$else}
  gpfColor2:
   SafeBase64Binary(StdString(Value), PropRec.DestPtr, SizeOf(TColor2));

  gpfColor4:
   SafeBase64Binary(StdString(Value), PropRec.DestPtr, SizeOf(TColor4));
 {$endif}

  gpfStrings: TStrings(PropRec.DestPtr).Text:= Value;

  gpfAlignType: PTextAlignType(PropRec.DestPtr)^:= StrToAlignTypeDef(Value);

  gpfUnknown:
 {$ifndef StandardStringsOnly}
   SafeBase64Binary(AnsiString(Value), PropRec.DestPtr, PropRec.DestSize);
 {$else}
   SafeBase64Binary(StdString(Value), PropRec.DestPtr, PropRec.DestSize);
 {$endif}
 end;
end;

//---------------------------------------------------------------------------
function TGuiObject.GetFieldCount(): Integer;
begin
 Result:= Length(RefProps);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetFieldName(Index: Integer): StdString;
begin
 if (Index >= 0)and(Index < Length(RefProps)) then
  Result:= RefProps[Index].Name
   else Result:= '';
end;

//---------------------------------------------------------------------------
function TGuiObject.GetFieldType(Index: Integer): TGuiPropertyType;
begin
 if (Index >= 0)and(Index < Length(RefProps)) then
  Result:= RefProps[Index].PropType
   else Result:= gptUnknown;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiObject.BeforeChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer;
 var Proceed: Boolean);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SelfDescribe();
begin
 FNameOfClass:= 'TGuiObject';

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiObject.GetValueInteger(const Name: StdString): Integer;
var
 Index: Integer;
begin
 Index:= IndexOfProperty(Name);

 if (Index <> -1) then
  Result:= RetrieveInteger(RefProps[Index])
   else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetValueInteger(const Name: StdString;
 Value: Integer);
var
 Index: Integer;
 Proceed: Boolean;
begin
 Index:= IndexOfProperty(Name);
 if (Index = -1) then Exit;

 Proceed:= True;

 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 StoreInteger(RefProps[Index], Value);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetValueCardinal(const Name: StdString): Cardinal;
var
 Index: Integer;
begin
 Index:= IndexOfProperty(Name);

 if (Index <> -1) then
  Result:= RetrieveCardinal(RefProps[Index])
   else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetValueCardinal(const Name: StdString;
 Value: Cardinal);
var
 Index: Integer;
 Proceed: Boolean;
begin
 Index:= IndexOfProperty(Name);
 if (Index = -1) then Exit;

 Proceed:= True;

 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 StoreCardinal(RefProps[Index], Value);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetValueFloat(const Name: StdString): Double;
var
 Index: Integer;
begin
 Index:= IndexOfProperty(Name);

 if (Index <> -1) then
  Result:= RetrieveFloat(RefProps[Index])
   else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetValueFloat(const Name: StdString;
 Value: Double);
var
 Index: Integer;
 Proceed: Boolean;
begin
 Index:= IndexOfProperty(Name);
 if (Index = -1) then Exit;

 Proceed:= True;

 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 StoreFloat(RefProps[Index], Value);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetValueBoolean(const Name: StdString): Boolean;
var
 Index: Integer;
begin
 Index:= IndexOfProperty(Name);

 if (Index <> -1) then
  Result:= RetrieveBoolean(RefProps[Index])
   else Result:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetValueBoolean(const Name: StdString;
 Value: Boolean);
var
 Index: Integer;
 Proceed: Boolean;
begin
 Index:= IndexOfProperty(Name);
 if (Index = -1) then Exit;

 Proceed:= True;

 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 StoreBoolean(RefProps[Index], Value);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetValueString(const Name: StdString): UniString;
var
 Index: Integer;
begin
 Index:= IndexOfProperty(Name);

 if (Index <> -1) then
  Result:= RetrieveString(RefProps[Index])
   else Result:= '';
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetValueString(const Name: StdString;
 const Value: UniString);
var
 Index: Integer;
 Proceed: Boolean;
begin
 Index:= IndexOfProperty(Name);
 if (Index = -1) then Exit;

 Proceed:= True;
 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 StoreString(RefProps[Index], Value);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetCustomValue(const Name: StdString; Data: Pointer;
 DataSize: Integer): Boolean;
var
 Index, MinCopy: Integer;
 Proceed: Boolean;
begin
 Result:= False;
 if (not Assigned(Data))or(DataSize < 1) then Exit;

 Index:= IndexOfProperty(Name);
 if (Index <> -1) then Exit;

 MinCopy:= Min2(RefProps[Index].DestSize, DataSize);
 if (MinCopy < 1) then Exit;

 Proceed:= True;
 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 Move(RefProps[Index].DestPtr^, Data^, MinCopy);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
 Result:= True;
end;

//---------------------------------------------------------------------------
function TGuiObject.SetCustomValue(const Name: StdString; Data: Pointer;
 DataSize: Integer): Boolean;
var
 Index, MinCopy: Integer;
 Proceed: Boolean;
begin
 Result:= False;
 if (not Assigned(Data))or(DataSize < 1) then Exit;

 Index:= IndexOfProperty(Name);
 if (Index <> -1) then Exit;

 MinCopy:= Min2(RefProps[Index].DestSize, DataSize);
 if (MinCopy < 1) then Exit;

 Proceed:= True;
 BeforeChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag, Proceed);

 if (not Proceed) then Exit;

 Move(Data^, RefProps[Index].DestPtr^, MinCopy);

 AfterChange(Name, RefProps[Index].PropType, RefProps[Index].PropTag);
 Result:= True;
end;

//---------------------------------------------------------------------------
end.

