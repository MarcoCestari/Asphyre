unit Asphyre.Fonts;
//---------------------------------------------------------------------------
// Asphyre bitmap fonts with unicode support.
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
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------
{< Bitmap fonts used natively in Asphyre supporting Unicode, pre-rendered
   text effects such as border and shadow, customized spacing between
   individual letter pairs, rendering using vertical color gradient and
   formatted text. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, System.SysUtils, System.Classes, System.Math, Asphyre.TypeDef, 
 Asphyre.Math, Asphyre.Math.Sets, Asphyre.Types, Asphyre.XML, Asphyre.Images, 
 Asphyre.Canvas;

//---------------------------------------------------------------------------
{$REGION 'Misc Types and Constants Declarations'}

//---------------------------------------------------------------------------
const
// This is the maximum size of font's style stack used by SaveState/LoadState.
{@exclude}
 FontStackSize = 16;

//---------------------------------------------------------------------------
type
{ The hashed list of individual letter spacings used in Asphyre fonts for
  pixel-perfect text rendering. The list stores values between ANSI letters
  quickly using hash table; for Unicode characters a linear list is used. }
 TFontLetterGroups = class
 private
  HashArray: packed array[0..255, 0..255] of ShortInt;
  ExtArray : TPointList;

  function GetShift(Code1, Code2: Integer): Integer;
 public
  { Returns the spacing between two given character codes. If there is no
    registry for the given combination of characters, zero is returned. }
  property Shift[Code1, Code2: Integer]: Integer read GetShift; default;

  { Modifies the spacing value for the given pair of character codes. If the
    registry for this combination of characters does not exist, it will be
    created; it if does exist, it will be replaced by the spacing value. }
  procedure Spec(Code1, Code2, AShift: Integer); overload;

  { Modifies the spacing value for the given pair of ANSI character codes. If
    the registry for this combination of characters does not exist, it will be
    created; it if does exist, it will be replaced by the spacing value. }
  procedure Spec(Code1, Code2: Char; AShift: Integer); overload;

  { Copies the spacing information from the given list of 2D integer points,
    where @code(X) and @code(Y) are considered character codes and @code(Data)
    field as integer representation of spacing between the given characters.
    The existing registry entries in the current list are not deleted, but
    replaced when needed. }
  procedure CopyFrom(const Source: TPointList);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{@exclude}PLetterEntry = ^TLetterEntry;
{@exclude}TLetterEntry = record
  Top : Integer;
  Pos : TPoint2px;
  Size: TPoint2px;
  Leading : Integer;
  Trailing: Integer;
 end;

//---------------------------------------------------------------------------
 TAsphyreFonts = class;

//---------------------------------------------------------------------------
{@exclude}PFontStyle = ^TFontStyle;
{@exclude}TFontStyle = record
  Colors: array[0..1] of Cardinal;
  Style : Cardinal;
 end;

//---------------------------------------------------------------------------
{@exclude}PFontTag = ^TFontTag;
{@exclude}TFontTag = record
  Name  : UniString;
  Colors: TColor2;
  Style : Cardinal;
 end;

//---------------------------------------------------------------------------
{@exclude}PFontState = ^TFontState;
{@exclude}TFontState = record
  ImageIndex: Integer;
  FontSize  : TPoint2px;
  DivSet    : UniString;
  ParaSet   : UniString;
  Scale     : Single;
  Kerning   : Single;
  Whitespace: Single;
  Linespace : Single;
 end;

//---------------------------------------------------------------------------
{@exclude}PParagraphWord = ^TParagraphWord;
{@exclude}TParagraphWord = record
  Text: UniString;
  ParaNum: Integer;
 end;

//---------------------------------------------------------------------------
{ This is custom text rendering event callback that is passed to
  @code(CustomOut) function of Asphyre font. This event is called for each
  letter that is to be displayed. The rendering should be made inside this
  event. It can be used for applying effects to individual letters and
  for scheduling visual effects.
   @param(Sender The sender class of the font that is used in the rendering.)
   @param(Image The source font image that should be used for displaying the
    individual letters.)
   @param(SrcRect The source letter rectangle that should be taken from the
    image for drawing the current letter.)
   @param(DestRect The destination rectangle where the letter should be
    rendered at.)
   @param(Colors The colors that should be used for rendering the destination
    letter rectangle. These colors include proper interpolation for displaying
    vertical color gradient properly.)
   @param(User The user data pointer that was specified when calling
    @code(CustomOut) method.) }
 TCustomTextEvent = procedure(Sender: TObject; Image: TAsphyreImage;
  const SrcRect, DestRect: TRect; const Colors: TColor4; User: Pointer);

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Asphyre Font Declaration'}

//---------------------------------------------------------------------------
{ Asphyre native font implementation that supports Unicode, pre-rendered
  text effects such as border and shadow, customized spacing between
  individual letter pairs, rendering using vertical color gradient and
  formatted text. }
 TAsphyreFont = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif}FOwner: TAsphyreFonts;
  FName : StdString;

  FKernings: TFontLetterGroups;

  Entries: array[0..65535] of TLetterEntry;
  FImageIndex: Integer;

  StyleStack: array[0..FontStackSize - 1] of TFontStyle;
  StyleCount: Integer;

  StateStack: array[0..FontStackSize - 1] of TFontState;
  StateCount: Integer;

  Words: array of TParagraphWord;

  FParaSet : UniString;
  FDivSet  : UniString;
  FFontSize: TPoint2px;

  FScale     : Single;
  FKerning   : Single;
  FWhitespace: Single;
  FLinespace : Single;

  procedure ClearWords();
  function AddWord(const Text: UniString; ParaNum: Integer): Integer;

  function ParseTag(const Text: UniString; var CurPos: Integer;
   NoStyle: Boolean): Boolean;

  procedure ParseEntry(const Node: TXMLNode);
  procedure ClearStyles();
  procedure PushStyle(const Colors: TColor2; Style: Cardinal);
  function PeekStyle(): PFontStyle;
  procedure PopStyle();
  procedure DisplayText(const Pos: TPoint2; const Text: UniString;
   Alpha: Single);

  function IsDivChar(Ch: WideChar): Boolean;
  function ExtractWord(const Text: UniString; var Step: Integer;
   var Para: Integer; out Segment: UniString): Boolean;
  procedure SplitText(const Text: UniString);
 public
  //.........................................................................
  { The owner of current font that points to the valid instance of
    @link(TAsphyreFonts) where shared data such as color tags will be taken
    from.}
  property Owner: TAsphyreFonts read FOwner;

  //.........................................................................
  { The list of spacings between the individual letter pairs for
    pixel-perfect text rendering. }
  property Kernings: TFontLetterGroups read FKernings;

  //.........................................................................
  { The unique name of the font that will be used for accessing this font
    from the owner list by using its name. }
  property Name: StdString read FName write FName;

  //.........................................................................
  { The index of image that contains letters to be rendered on the screen.
    This index refers to @code(Images) property of the owner and must be
    property specified for displaying text. }
  property ImageIndex: Integer read FImageIndex write FImageIndex;

  //.........................................................................
  { The maximum size of letter box that covers all letters. This is
    originally set in Asphyre's FontTool and is used for rendering vertical
    text gradients properly. }
  property FontSize: TPoint2px read FFontSize write FFontSize;

  //.........................................................................
  { The list of dividing characters used to split text into words when using
    @link(TextRect) for drawing formatted text. }
  property DivSet: UniString read FDivSet write FDivSet;

  //.........................................................................
  { The list of paragraph-identifying characters that indicate the beginning
    of new paragraph when using @link(TextRect) for drawing formatted text. }
  property ParaSet: UniString read FParaSet write FParaSet;

  //.........................................................................
  { The scale of the rendered font, specifying how big the letters should
    appear. By default this parameter is set to one; using other values will
    make the text appear bigger or smaller, but the result may be blurred
    because of letter image stretching. }
  property Scale: Single read FScale write FScale;

  //.........................................................................
  { This value is an additional space (in pixels) added to every character's
    width; it can be used to compress or expand the rendered text. }
  property Kerning: Single read FKerning write FKerning;

  //.........................................................................
  { The width in pixels that should be used for blank characters (space is
    one of them). }
  property Whitespace: Single read FWhitespace write FWhitespace;

  //.........................................................................
  { The space added between individual text lines drawn using @link(TextRect)
    when drawing formatted text. }
  property Linespace: Single read FLinespace write FLinespace;

  //.........................................................................
  //--- Miscellaneous -------------------------------------------------------
  //.........................................................................

  //.........................................................................
  { Loads the font description from the specified link, which can point
    either to Asphyre archive (e.g. "MyMedia.asvf | SomeFont.xml") or
    external file on disk. }
  function ParseLink(const Link: UniString): Boolean;

  //.........................................................................
  { Saves the state of most font properties such as scale, kerning and so
    on. This can be useful when modifying font parameters for drawing text
    so that they can be later restored without breaking the rest of text
    rendering code that relies on default font parameters. }
  procedure SaveState();

  //.........................................................................
  { Restores the state of most font properties such as scale, kerning and so
    on that were previously saved by @link(SaveState) method. }
  procedure RestoreState();

  //.........................................................................
  { Removes all states that were previously saved by @link(SaveState). This
    can be useful in certain circumstances where the stack should be cleared. }
  procedure ClearStates();

  //.........................................................................
  //--- Text Rendering ------------------------------------------------------
  //.........................................................................

  //.........................................................................
  { Draws the text starting at the given top-left position with the specified
    alpha-transparency and vertical color gradient. }
  procedure TextOut(const Pos: TPoint2; const Text: UniString;
   const Colors: TColor2; Alpha: Single = 1.0); overload;

  //.........................................................................
  { Custom font drawing function that calls the specified event for every
    letter that should be drawn. The text is supposedly drawn at the given
    top-left position with the specified alpha-transparency and vertical
    color gradient. The provided event is actually responsible for drawing
    each of the letters. }
  procedure CustomOut(const Pos: TPoint2; const Text: UniString;
   const Color: TColor2; Alpha: Single; Event: TCustomTextEvent;
   User: Pointer);

  //.........................................................................
  { Draws the text centered horizontally at the given position with the
    specified alpha-transparency and vertical color gradient. The text is not
    centered vertically, it starts from the top of the given position. }
  procedure TextMidH(const Pos: TPoint2px; const Text: UniString;
   const Colors: TColor2; Alpha: Single = 1.0);

  //.........................................................................
  { Draws the text centered both horizontally and vertically at the given
    position with the specified alpha-transparency and vertical color
    gradient. }
  procedure TextMid(const Pos: TPoint2px; const Text: UniString;
   const Colors: TColor2; Alpha: Single = 1.0);

  //.........................................................................
  { Draws the text centered both horizontally and vertically at the given
    position with the specified alpha-transparency and vertical color
    gradient. The provided 2D floating-point vector is rounded to nearest
    integer to avoid drawing blurred text; to prevent this, use
    @link(TextMidFF) instead. }
  procedure TextMidF(const Pos: TPoint2; const Text: UniString;
   const Colors: TColor2; Alpha: Single = 1.0);

  //.........................................................................
  { Draws the text centered both horizontally and vertically at the given
    position with the specified alpha-transparency and vertical color
    gradient. The text is drawn at the given 2D floating-point position. }
  procedure TextMidFF(const Pos: TPoint2; const Text: UniString;
   const Colors: TColor2; Alpha: Single = 1.0);

  //.........................................................................
  { Calculates horizontal and vertical dimensions of the provided text that
    will be occupied when drawing this text on the screen. }
  function TextExtent(const Text: UniString): TPoint2;

  //.........................................................................
  { Calculates the horizontal size of the provided text that will be occupied
    when this text is rendered on the screen. }
  function TextWidth(const Text: UniString): Single;

  //.........................................................................
  { Calculates the vertical size of the provided text that will be occupied
    when this text is rendered on the screen. }
  function TextHeight(const Text: UniString): Single;

  //.........................................................................
  { Calculates the vertical size of the provided text that will be occupied
    when this text is rendered on the screen. The resulting size is rounded
    to the nearest integer. If more precision is required, @link(TextExtent)
    should be used instead. }
  function TexExtent(const Text: UniString): TPoint2px;

  //.........................................................................
  { Calculates the horizontal size of the provided text that will be occupied
    when this text is rendered on the screen. The result is rounded to the
    nearest integer.  If more precision is required, @link(TextWidth)
    should be used instead. }
  function TexWidth(const Text: UniString): Integer;

  //.........................................................................
  { Calculates the vertical size of the provided text that will be occupied
    when this text is rendered on the screen. The result is rounded to the
    nearest integer.  If more precision is required, @link(TextHeight)
    should be used instead. }
  function TexHeight(const Text: UniString): Integer;

  //.........................................................................
  { Draws formatted text that is justified horizontally using variable
    horizontal spacing between individual words (using separation characters
    set in @link(DivSet). The text is fitted to the provided rectangle. If a
    paragraph character is found (as defined by @link(ParaSet), the text is
    rendered from the next line with paragraph space added both vertically and
    horizontally. The rendering stops when the requested text reaches the
    bottom of the rendered rectangle. }
  procedure TextRect(const Pos, Size, Paragraph: TPoint2;
   const Text: UniString; const Colors: TColor2; Alpha: Single = 1.0);

  //.........................................................................
  { Estimates the size and position of individual letter rectangles if they
    are rendered on the screen. The resulting rectangles are saved to the
    specified list. If the text is empty, the list will also be empty. }
  procedure TextRects(const Text: UniString; List: TRectList);

  {@exclude}constructor Create(AOwner: TAsphyreFonts);
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Asphyre Fonts Declaration'}

//---------------------------------------------------------------------------
{ The list of Asphyre native bitmap fonts supporting Unicode, pre-rendered
  text effects such as border and shadow, customized spacing between
  individual letter pairs, rendering using vertical color gradient and
  formatted text. }
 TAsphyreFonts = class
 private
  Fonts: array of TAsphyreFont;
  Tags : array of TFontTag;
  TagsDirty: Boolean;

  {$ifdef DelphiNextGen}[weak]{$endif}FImages: TAsphyreImages;
  {$ifdef DelphiNextGen}[weak]{$endif}FCanvas: TAsphyreCanvas;

  FOnItemLoad: TResourceProcessEvent;
  FOnItemFail: TResourceProcessEvent;

  procedure DeviceDestroy(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);

  function GetCount(): Integer;
  function GetItem(Index: Integer): TAsphyreFont;

  function InsertFont(): Integer;
  function IndexOfTag(const Name: UniString): Integer;
  procedure DeleteTag(Index: Integer);

  procedure SortSwapTags(Index1, Index2: Integer);
  function SortSplitTags(Start, Stop: Integer): Integer;
  procedure QuicksortTags(Start, Stop: Integer);
  function GetFont(const AFontName: StdString): TAsphyreFont;
 public
  { The reference to image list that contains one or more font images used for
    text rendering. Each of the fonts will be referring to this list for
    drawing individual letters. This property must be set before loading and
    using fonts. }
  property Images: TAsphyreImages read FImages write FImages;

  { The reference to 2D canvas where the letters will be drawn on. This
    property must be set before drawing text with any of the fonts. }
  property Canvas: TAsphyreCanvas read FCanvas write FCanvas;

  //.........................................................................
  { The number of fonts in the list. }
  property Count: Integer read GetCount;

  { The access to individual fonts in the list by using index that is specified
    in range of [0..(Count - 1)]. If the index is outside of valid range,
    @nil is returned. }
  property Items[Index: Integer]: TAsphyreFont read GetItem; default;

  //.........................................................................
  { Returns the font with the given name (not case sensitive). This method
    uses binary search for quickly finding the required font. If the wanted
    font is not found in the list, @nil is returned. }
  property Font[const AFontName: StdString]: TAsphyreFont read GetFont;

  //.........................................................................
  { This event occurs when a new font is being loaded on request inside
    @link(Resolve) function. }
  property OnItemLoad: TResourceProcessEvent read FOnItemLoad write FOnItemLoad;

  { This event occurs when the requested font could not be loaded inside
    @link(Resolve) function either because its meta-data is not found or
    because it could not be loaded from its specified location. }
  property OnItemFail: TResourceProcessEvent read FOnItemFail write FOnItemFail;

  //.........................................................................
  { Adds a new font to the list and loads its letter data from the specified
    link that can be either Asphyre archive (e.g. "MyMedia.asvf | SomeFont.xml")
    or external file, with the specified image name. The image must be loaded
    before this function is used. @code(Resolve) method is used for obtaining
    the image, so meta-data can be used for loading font images on request.
    If the method succeeds, the index of newly added font is returned;
    otherwise, the returned value will be -1. }
  function Insert(const DescLink, ImageName: StdString): Integer;

  //.........................................................................
  { Returns the index of the font having the specified name (not case
    sensitive) in the list. This function uses binary search for quickly
    locating the wanted font. If the font with given name is not found, -1
    is returned. }
  function IndexOf(const AFontName: StdString): Integer;

  //.........................................................................
  { Removes font at the specified index and releases its memory. The index must
    be specified in [0..(ItemCount - 1)] range. If the specified index is
    outside of valid range, this method does nothing. }
  procedure RemoveFont(Index: Integer);

  { Removes all fonts from the list and releases them from memory. }
  procedure RemoveAll();

  //.........................................................................
  { Inserts new font color tag with the given name to local registry. The
    color tag can be used when drawing text using <tagname></> tags
    (e.g. "Some text <MyColor>colored text</> other text").  The tags can
    be used both in normal and preformatted text. All fonts in the list
    have access to existing color tags. }
  procedure InsertTag(const Name: UniString; const Colors: TColor2;
   Style: Cardinal = 0);

  { Remove all font color tags from the local registry. }
  procedure RemoveTags();

  { Removes font color tag with the specified name from the local registry.
    If the tag with given name does not exist, this method does nothing. }
  procedure RemoveTag(const Name: UniString);

  {@exclude}function FindTag(const Name: UniString): PFontTag;

  //.........................................................................
  { Resolves the unique font name and returns its index in the list. This
    function uses meta-data describing all fonts available to the application
    and if the specified font name is not found among the existing fonts,
    the font is loaded from disk using its meta-data specification.
    @link(OnItemLoad) event is called when the font is about to be loaded and
    @link(OnItemFail) is called when the font is either not found in the
    meta-data or cannot be loaded with the specified information. If the
    method succeeds, the index of existing (or loaded) font is returned and
    -1 is returned otherwise. }
  function Resolve(const FontName: StdString): Integer;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Events.Types, Asphyre.Events, Asphyre.Media.Fonts, Asphyre.Strings,
 Asphyre.Media.Utils;

//---------------------------------------------------------------------------
{$REGION 'Global Functions'}

//---------------------------------------------------------------------------
function GetTextCharAt(const Text: UniString;
 CharPos: Integer): UniChar; inline;
begin
{$ifdef DelphiNextGen}
 Result:= Text.Chars[CharPos - 1];
{$else}
 Result:= Text[CharPos];
{$endif}
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Font Letter Groups'}

//---------------------------------------------------------------------------
constructor TFontLetterGroups.Create();
begin
 inherited;

 ExtArray:= TPointList.Create();

 FillChar(HashArray, SizeOf(HashArray), 0);
end;

//---------------------------------------------------------------------------
destructor TFontLetterGroups.Destroy();
begin
 FreeAndNil(ExtArray);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TFontLetterGroups.Spec(Code1, Code2, AShift: Integer);
var
 Pos: TPoint2px;
 Index: Integer;
begin
 if (Code1 < 0)or(Code2 < 0) then Exit;

 AShift:= MinMax2(AShift, -128, 127);

 if (Code1 <= 255)and(Code2 <= 255) then
  begin
   HashArray[Code1, Code2]:= AShift;
   Exit;
  end;

 Pos.x:= Code1;
 Pos.y:= Code2;

 Index:= ExtArray.IndexOf(Pos);
 if (Index = -1) then Index:= ExtArray.Insert(Pos);

 ExtArray[Index].Data:= Pointer(AShift);
end;

//---------------------------------------------------------------------------
function TFontLetterGroups.GetShift(Code1, Code2: Integer): Integer;
var
 Index: Integer;
begin
 Result:= 0;
 if (Code1 < 0)or(Code2 < 0) then Exit;

 if (Code1 <= 255)and(Code2 <= 255) then
  begin
   Result:= HashArray[Code1, Code2];
   Exit;
  end;

 Index:= ExtArray.IndexOf(Point2px(Code1, Code2));

 if (Index <> -1) then
  Result:= PtrInt(ExtArray[Index].Data);
end;

//---------------------------------------------------------------------------
procedure TFontLetterGroups.Spec(Code1, Code2: Char; AShift: Integer);
begin
 Spec(Integer(Code1), Integer(Code2), AShift);
end;

//---------------------------------------------------------------------------
procedure TFontLetterGroups.CopyFrom(const Source: TPointList);
var
 i: Integer;
 Holder: PPointHolder;
begin
 for i:= 0 to Source.Count - 1 do
  begin
   Holder:= Source.Item[i];
   if (not Assigned(Holder)) then Continue;

   Spec(Holder.Point.x, Holder.Point.y, PtrInt(Holder.Data));
  end;
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Asphyre Font'}

//---------------------------------------------------------------------------
constructor TAsphyreFont.Create(AOwner: TAsphyreFonts);
begin
 inherited Create();

 FOwner:= AOwner;
 FName := '';

 FKernings:= TFontLetterGroups.Create();

 FillChar(StyleStack, SizeOf(StyleStack), 0);
 FillChar(StateStack, SizeOf(StateStack), 0);
 StyleCount:= 0;
 StateCount:= 0;

 FImageIndex:= -1;
 FScale     := 1.0;
 FKerning   := -1.0;
 FWhitespace:= 5.0;
 FLinespace := 2.0;

 FParaSet:= #10;
 FDivSet := #13 + #32 + #8;
end;

//---------------------------------------------------------------------------
destructor TAsphyreFont.Destroy();
begin
 ClearStates();
 ClearStyles();

 FreeAndNil(FKernings);
 ClearWords();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.ClearWords();
begin
 SetLength(Words, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.AddWord(const Text: UniString; ParaNum: Integer): Integer;
begin
 Result:= Length(Words);
 SetLength(Words, Result + 1);

 Words[Result].Text:= Text;
 Words[Result].ParaNum:= ParaNum;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.ParseEntry(const Node: TXMLNode);
var
 CharCode: Integer;
begin
 CharCode:= ParseInt(Node.FieldValue['ascii'], -1);
 if (CharCode < 0)or(CharCode > 255) then
  begin
   CharCode:= ParseInt(Node.FieldValue['ucode'], -1);
   if (CharCode < 0) then Exit;
  end;

 with Entries[CharCode] do
  begin
   Top   := ParseInt(Node.FieldValue['top'], 0);
   Pos.x := ParseInt(Node.FieldValue['x'], 0);
   Pos.y := ParseInt(Node.FieldValue['y'], 0);
   Size.x:= ParseInt(Node.FieldValue['width'], 0);
   Size.y:= ParseInt(Node.FieldValue['height'], 0);
   Leading := ParseInt(Node.FieldValue['leading'], 0);
   Trailing:= ParseInt(Node.FieldValue['trailing'], 0);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.ParseLink(const Link: UniString): Boolean;
var
 Node, Child: TXMLNode;
begin
 Node:= LoadLinkXML(Link);

 Result:= Assigned(Node);
 if (not Result) then Exit;

 FFontSize.x:= ParseInt(Node.FieldValue['width'], 0);
 FFontSize.y:= ParseInt(Node.FieldValue['height'], 0);

 for Child in Node do
  if (SameText(Child.Name, 'item')) then ParseEntry(Child);

 FreeAndNil(Node);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.ClearStyles();
begin
 StyleCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.PushStyle(const Colors: TColor2; Style: Cardinal);
begin
 if (StyleCount < FontStackSize) then
  begin
   StyleStack[StyleCount].Colors[0]:= Colors[0];
   StyleStack[StyleCount].Colors[1]:= Colors[1];
   StyleStack[StyleCount].Style:= Style;
  end;

 Inc(StyleCount);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.PeekStyle(): PFontStyle;
begin
 if (StyleCount > 0)and(StyleCount <= FontStackSize) then
  Result:= @StyleStack[StyleCount - 1]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.PopStyle();
begin
 if (StyleCount > 0) then Dec(StyleCount);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.ClearStates();
begin
 StateCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.SaveState();
begin
 if (StateCount < FontStackSize) then
  begin
   StateStack[StateCount].ImageIndex:= FImageIndex;
   StateStack[StateCount].FontSize  := FFontSize;
   StateStack[StateCount].DivSet    := FDivSet;
   StateStack[StateCount].ParaSet   := FParaSet;
   StateStack[StateCount].Scale     := FScale;
   StateStack[StateCount].Kerning   := FKerning;
   StateStack[StateCount].Whitespace:= FWhitespace;
   StateStack[StateCount].Linespace := FLinespace;
  end;

 Inc(StateCount);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.RestoreState();
begin
 if (StateCount > 0) then
  begin
   Dec(StateCount);

   FImageIndex:= StateStack[StateCount].ImageIndex;
   FFontSize  := StateStack[StateCount].FontSize;
   FDivSet    := StateStack[StateCount].DivSet;
   FParaSet   := StateStack[StateCount].ParaSet;
   FScale     := StateStack[StateCount].Scale;
   FKerning   := StateStack[StateCount].Kerning;
   FWhitespace:= StateStack[StateCount].Whitespace;
   FLinespace := StateStack[StateCount].Linespace;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.ParseTag(const Text: UniString; var CurPos: Integer;
 NoStyle: Boolean): Boolean;
var
 TagPos, TagSize, PreCurPos: Integer;
 TagName: UniString;
 Tag: PFontTag;
begin
 PreCurPos:= CurPos;

 // -> Check whether there is a tag.
 Result:= GetTextCharAt(Text, CurPos) = '<';
 if (not Result) then Exit;

 // -> Check for invalid "<" tag at the end of string.
 if (CurPos >= Length(Text)) then
  begin
   Result:= False;
   Exit;
  end;

 // -> Mark the beginning of tag text.
 Inc(CurPos);

 TagPos := CurPos;
 TagSize:= 0;

 // -> Scan for the end of the tag.
 while (CurPos <= Length(Text))and(GetTextCharAt(Text, CurPos) <> '>') do
  begin
   Inc(TagSize);
   Inc(CurPos);
  end;

 // -> Check if tag was not closed at the end of string.
 if (CurPos > Length(Text)) then
  begin
   Result:= False;
   CurPos:= PreCurPos;
   Exit;
  end;

 // -> Skip ">" letter.
 Inc(CurPos);
 if (NoStyle) then Exit;

 // -> Extract tag name from the string.
 TagName:= Copy(Text, TagPos, TagSize);

 if (TagName = '/') then
  begin
   PopStyle();
   Exit;
  end;

 Tag:= FOwner.FindTag(TagName);
 if (Assigned(Tag)) then PushStyle(Tag.Colors, Tag.Style);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.DisplayText(const Pos: TPoint2; const Text: UniString;
 Alpha: Single);
var
 CharNo: Integer;
 PeCode: Integer;
 uCode : Integer;
 xPos  : Single;
 Style : PFontStyle;
 Entry : PLetterEntry;
 Image : TAsphyreImage;
 Canvas: TAsphyreCanvas;
 iAlpha: Integer;
 DrawPos : TPoint2;
 DrawSize: TPoint2;
 Colors  : TColor2;
begin
 if (not Assigned(FOwner.Images))or(not Assigned(FOwner.Canvas)) then Exit;

 Image:= FOwner.Images[FImageIndex];
 if (not Assigned(Image)) then Exit;

 Canvas:= FOwner.Canvas;

 // -> Start processing text.
 xPos  := Pos.x;
 CharNo:= 1;
 iAlpha:= MinMax2(Round(Alpha * 255.0), 0, 255);
 PeCode:= -1;

 while (CharNo <= Length(Text)) do
  begin
   // -> Check if there are any tags in the text.
   if (ParseTag(Text, CharNo, False)) then Continue;

   // -> retrieve letter, its numerical code, and the current style.
   uCode:= Word(GetTextCharAt(Text, CharNo));
   Entry:= @Entries[uCode];
   Style:= PeekStyle();

   // -> Check whether the letter has its drawing information.
   if (Entry.Size.x < 1)or(Entry.Size.y < 1)or(not Assigned(Style)) then
    begin
     Inc(CharNo);
     xPos:= xPos + FWhitespace * FScale;
     Continue;
    end;

   if (not Assigned(Style)) then Continue;

   // -> Include letter group interlave. 
   xPos:= xPos + FKernings[PeCode, uCode];
   PeCode:= uCode;

   // -> Include leading space.
   xPos:= xPos + Entry.Leading * FScale;

   // -> Compute drawing position and size.
   DrawPos.x := xPos;
   DrawPos.y := Pos.y + (Entry.Top * FScale);

   DrawSize.x:= Entry.Size.x * FScale;
   DrawSize.y:= Entry.Size.y * FScale;

   // -> Interpolate drawing colors.
   Colors[0]:= LerpPixels(Style.Colors[0], Style.Colors[1], Entry.Top /
    FFontSize.y);

   Colors[1]:= LerpPixels(Style.Colors[0], Style.Colors[1], (Entry.Top +
    Entry.Size.y) / FFontSize.y);

   // -> Display the letter.
   Canvas.UseImagePx(Image, pBounds4(Entry.Pos.x, Entry.Pos.y,
    Entry.Size.x, Entry.Size.y));

   Canvas.TexMap(
    pBounds4(DrawPos.x, DrawPos.y, DrawSize.x, DrawSize.y),
    cColorAlpha4(Colors[0], Colors[0], Colors[1], Colors[1],
     iAlpha, iAlpha, iAlpha, iAlpha));

   // -> Keep going horizontally.
   Inc(CharNo);
   xPos:= xPos + (Entry.Size.x + Entry.Trailing + FKerning) * FScale;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.CustomOut(const Pos: TPoint2; const Text: UniString;
 const Color: TColor2; Alpha: Single; Event: TCustomTextEvent;
 User: Pointer);
var
 CharNo: Integer;
 PeCode: Integer;
 Ascii : Integer;
 xPos  : Single;
 Style : PFontStyle;
 Entry : PLetterEntry;
 Image : TAsphyreImage;
 iAlpha: Integer;
 DrawPos : TPoint2;
 DrawSize: TPoint2;
 Colors  : TColor2;
begin
 if (not Assigned(FOwner.Images))or(not Assigned(FOwner.Canvas)) then Exit;

 ClearStyles();
 PushStyle(Color, 0);

 Image:= FOwner.Images[FImageIndex];
 if (not Assigned(Image)) then Exit;

 xPos  := Pos.x;
 CharNo:= 1;
 iAlpha:= MinMax2(Round(Alpha * 255.0), 0, 255);
 PeCode:= -1;

 while (CharNo <= Length(Text)) do
  begin
   if (ParseTag(Text, CharNo, False)) then Continue;

   Ascii:= Ord(GetTextCharAt(Text, CharNo));
   Entry:= @Entries[Ascii];
   Style:= PeekStyle();

   if (Entry.Size.x < 1)or(Entry.Size.y < 1)or(not Assigned(Style)) then
    begin
     Inc(CharNo);
     xPos:= xPos + FWhitespace * FScale;
     Continue;
    end;

   if (not Assigned(Style)) then Continue;

   xPos:= xPos + FKernings[PeCode, Ascii];
   PeCode:= Ascii;

   xPos:= xPos + Entry.Leading * FScale;

   DrawPos.x := xPos;
   DrawPos.y := Pos.y + (Entry.Top * FScale);

   DrawSize.x:= Entry.Size.x * FScale;
   DrawSize.y:= Entry.Size.y * FScale;

   Colors[0]:= LerpPixels(Style.Colors[0], Style.Colors[1], Entry.Top /
    FFontSize.y);

   Colors[1]:= LerpPixels(Style.Colors[0], Style.Colors[1], (Entry.Top +
    Entry.Size.y) / FFontSize.y);

   Event(Self, Image,
    Bounds(
     Entry.Pos.x, Entry.Pos.y,
     Entry.Size.x, Entry.Size.y),
    Bounds(
     Round(DrawPos.x), Round(DrawPos.y),
     Round(DrawSize.x), Round(DrawSize.y)),
    cColorAlpha4(
     Colors[0], Colors[0], Colors[1], Colors[1],
     iAlpha, iAlpha, iAlpha, iAlpha),
    User);

   Inc(CharNo);
   xPos:= xPos + (Entry.Size.x + Entry.Trailing + FKerning) * FScale;
  end;

 ClearStyles();
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TextExtent(const Text: UniString): TPoint2;
var
 CharNo : Integer;
 Ascii  : Integer;
 PeCode : Integer;
 Entry  : PLetterEntry;
 KernSub: Single;
begin
 CharNo:= 1;
 PeCode:= -1;

 Result.x:= 0.0;
 Result.y:= FFontSize.y * FScale;
 KernSub := 0.0;

 while (CharNo <= Length(Text)) do
  begin
   if (ParseTag(Text, CharNo, True)) then Continue;

   Ascii:= Ord(GetTextCharAt(Text, CharNo));
   Entry:= @Entries[Ascii];

   if (Entry.Size.x < 1)or(Entry.Size.y < 1) then
    begin
     Inc(CharNo);

     Result.x:= Result.x + FWhitespace * FScale;
     Continue;
    end;

   Inc(CharNo);

   Result.x:= Result.x + FKernings[PeCode, Ascii];
   PeCode:= Ascii;

   Result.x:= Result.x + (Entry.Size.x + Entry.Leading + Entry.Trailing +
    FKerning) * FScale;
   KernSub := FKerning * FScale;
  end;

 Result.x:= Result.x - KernSub; 
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextRects(const Text: UniString; List: TRectList);
var
 CharNo: Integer;
 uCode : Integer;
 PeCode: Integer;
 xPos  : Single;
 Entry : PLetterEntry;
 Rect  : TRect;
begin
 xPos  := 0;
 CharNo:= 1;
 PeCode:= -1;

 Rect.Top   := 0;
 Rect.Bottom:= Round(FFontSize.y * FScale);

 while (CharNo <= Length(Text)) do
  begin
   if (ParseTag(Text, CharNo, False)) then Continue;

   uCode:= Word(GetTextCharAt(Text, CharNo));
   Entry:= @Entries[uCode];

   if (Entry.Size.x < 1)or(Entry.Size.y < 1) then
    begin
     Inc(CharNo);

     Rect.Left := Round(xPos);
     Rect.Right:= Round(xPos + FWhitespace * FScale);
     List.Add(Rect);

     xPos:= xPos + FWhitespace * FScale;
     Continue;
    end;

   xPos:= xPos + FKernings[PeCode, uCode];
   PeCode:= uCode;

   xPos:= xPos + Entry.Leading * FScale;

   Rect.Left := Round(xPos);
   Rect.Right:= Round(xPos + (Entry.Size.x + Entry.Trailing) * FScale) + 1;
   List.Add(Rect);

   // -> Keep going horizontally.
   Inc(CharNo);
   xPos:= xPos + (Entry.Size.x + Entry.Trailing + FKerning) * FScale;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TextWidth(const Text: UniString): Single;
begin
 Result:= TextExtent(Text).x;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TextHeight(const Text: UniString): Single;
begin
 Result:= TextExtent(Text).y;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TexExtent(const Text: UniString): TPoint2px;
var
 Ext: TPoint2;
begin
 Ext:= TextExtent(Text);

 Result.x:= Round(Ext.x);
 Result.y:= Round(Ext.y);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TexWidth(const Text: UniString): Integer;
begin
 Result:= TexExtent(Text).x;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TexHeight(const Text: UniString): Integer;
begin
 Result:= TexExtent(Text).y;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextOut(const Pos: TPoint2; const Text: UniString;
 const Colors: TColor2; Alpha: Single);
begin
 ClearStyles();
 PushStyle(Colors, 0);

 DisplayText(Pos, Text, Alpha);

 ClearStyles();
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextMid(const Pos: TPoint2px;
 const Text: UniString; const Colors: TColor2; Alpha: Single);
var
 TextSize: TPoint2;
 DrawPos : TPoint2px;
begin
 TextSize:= TextExtent(Text);

 DrawPos.x:= Pos.x - Round(TextSize.x * 0.5);
 DrawPos.y:= Pos.y - Round(TextSize.y * 0.5);

 TextOut(DrawPos, Text, Colors, Alpha);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextMidH(const Pos: TPoint2px; const Text: UniString;
 const Colors: TColor2; Alpha: Single);
var
 TextSize: TPoint2;
 DrawPos : TPoint2px;
begin
 TextSize:= TextExtent(Text);

 DrawPos.x:= Pos.x - Round(TextSize.x * 0.5);
 DrawPos.y:= Pos.y;

 TextOut(DrawPos, Text, Colors, Alpha);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextMidF(const Pos: TPoint2; const Text: UniString;
 const Colors: TColor2; Alpha: Single);
var
 TextSize: TPoint2;
 DrawPos : TPoint2;
begin
 TextSize:= TextExtent(Text);

 DrawPos.x:= Pos.x - Round(TextSize.x * 0.5);
 DrawPos.y:= Pos.y - Round(TextSize.y * 0.5);

 TextOut(DrawPos, Text, Colors, Alpha);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextMidFF(const Pos: TPoint2; const Text: UniString;
 const Colors: TColor2; Alpha: Single);
var
 TextSize: TPoint2;
 DrawPos : TPoint2;
begin
 TextSize:= TextExtent(Text);

 DrawPos.x:= Pos.x - TextSize.x * 0.5;
 DrawPos.y:= Pos.y - TextSize.y * 0.5;

 TextOut(DrawPos, Text, Colors, Alpha);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.IsDivChar(Ch: WideChar): Boolean;
var
 IsDiv: Boolean;
begin
 IsDiv:= Pos(Ch, FDivSet) <> 0;

 Result:= (IsDiv)or(Ch = #32);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.ExtractWord(const Text: UniString;
var Step: Integer; var Para: Integer; out Segment: UniString): Boolean;
var
 SegPos, SegSize: Integer;
begin
 Segment:= '';

 // -> Skip all unused characters.
 while (Step <= Length(Text))and(IsDivChar(GetTextCharAt(Text, Step))) do Inc(Step);

 // -> Check for end of text.
 if (Step > Length(Text)) then
  begin
   Result:= False;
   Exit;
  end;

 // -> Check for next paragraph.
 if (Pos(GetTextCharAt(Text, Step), FParaSet) <> 0) then
  begin
   Inc(Para);
   Inc(Step);
   Result:= True;
   Exit;
  end;

 // -> Start parsing the word.
 SegPos := Step;
 SegSize:= 0;

 while (Step <= Length(Text))and(Pos(GetTextCharAt(Text, Step), FDivSet) = 0) do
  begin
   Inc(Step);
   Inc(SegSize);
  end;

 // -> Extract text segment.
 Segment:= Copy(Text, SegPos, SegSize);

 Result:= (SegSize > 0);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.SplitText(const Text: UniString);
var
 Step: Integer;
 Para: Integer;
 Segment: UniString;
begin
 ClearWords();

 Step:= 1;
 Para:= 0;

 while (ExtractWord(Text, Step, Para, Segment)) do
  if (Length(Segment) > 0) then
   AddWord(Segment, Para);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextRect(const Pos, Size, Paragraph: TPoint2;
 const Text: UniString; const Colors: TColor2; Alpha: Single);
const
 NoScaleTreshold = 0.025;
var
 Para, ParaTo: Integer;
 WordNo, WordTo, NoWords, Index: Integer;
 PreSize, CurSize, BlnkSpace, MaxSize, Ident, Height, PosAdd: Single;
 CurPos, TextSize, PlaceAt: TPoint2;
 RoundScale: Single;
begin
 if (not Assigned(FOwner.Canvas)) then Exit;

 RoundScale:= FOwner.Canvas.ExternalScale / FOwner.Canvas.DeviceScale;
 if (Frac(RoundScale) >= NoScaleTreshold) then RoundScale:= 1.0;

 SplitText(Text);

 Para  := -1;
 WordNo:= 0;

 ClearStyles();
 PushStyle(Colors, 0);

 CurPos.x:= Pos.x;

 while (WordNo < Length(Words)) do
  begin
   PreSize  := 0.0;
   CurSize  := 0.0;
   BlnkSpace:= 0.0;
   MaxSize  := Size.x - (CurPos.x - Pos.x);

   WordTo:= WordNo;
   ParaTo:= Para;
   while (CurSize + BlnkSpace < MaxSize)and(WordTo < Length(Words))and
    (ParaTo = Para) do
    begin
     PreSize  := CurSize;
     CurSize  := CurSize + TextWidth(Words[WordTo].Text);
     BlnkSpace:= BlnkSpace + FWhitespace * FScale;
     ParaTo   := Words[WordTo].ParaNum;

     Inc(WordTo);
    end;

   NoWords:= (WordTo - WordNo) - 1;
   if (WordTo >= Length(Words))and(CurSize + BlnkSpace < MaxSize) then
    begin
     Inc(NoWords);
     PreSize:= CurSize;
    end;

   if (NoWords < 1) then
    begin
     // Case 1. New paragraph.
     if (ParaTo <> Para) then
      begin
       CurPos.x:= Pos.x + Paragraph.x;
       if (WordNo < 1) then CurPos.y:= Pos.y
        else CurPos.y:= CurPos.y + Paragraph.y;

       Para:= ParaTo;

       Continue;
      end else
     // Case 2. Exhausted words or size doesn't fit.
       Break;
    end;

   if (NoWords > 1) then
    Ident:= (MaxSize - PreSize) / (NoWords - 1)
     else Ident:= 0.0;

   if ((ParaTo <> Para)and(NoWords > 1))or
    (WordNo + NoWords >= Length(Words)) then
    Ident:= FWhitespace * FScale;

   Height:= 0;
   PosAdd:= 0.0;
   for Index:= WordNo to WordNo + NoWords - 1 do
    begin
     if (RoundScale > 1.0) then
      begin
       PlaceAt.x:= Round((CurPos.x + PosAdd) / RoundScale) * RoundScale;
       PlaceAt.y:= Round(CurPos.y / RoundScale) * RoundScale;

       DisplayText(PlaceAt, Words[Index].Text, Alpha);
      end else
       DisplayText(Point2(CurPos.x + Round(PosAdd), CurPos.y),
        Words[Index].Text, Alpha);

     TextSize:= TextExtent(Words[Index].Text);

     PosAdd:= PosAdd + TextSize.x + Ident;
     Height:= Max(Height, TextSize.y);
    end;

   CurPos.x:= Pos.x;
   CurPos.y:= CurPos.y + Height + FLineSpace;

   Inc(WordNo, NoWords);
  end;

 ClearStyles();
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Asphyre Fonts'}

//---------------------------------------------------------------------------
constructor TAsphyreFonts.Create();
begin
 inherited;

 EventDeviceDestroy.Subscribe(ClassName, DeviceDestroy);

 TagsDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreFonts.Destroy();
begin
 EventProviders.Unsubscribe(ClassName);

 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.DeviceDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 RemoveAll();
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.GetCount(): Integer;
begin
 Result:= Length(Fonts);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.GetItem(Index: Integer): TAsphyreFont;
begin
 if (Index >= 0)and(Index < Length(Fonts)) then
  Result:= Fonts[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Fonts) - 1 do
  if (Assigned(Fonts[i])) then FreeAndNil(Fonts[i]);

 SetLength(Fonts, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.InsertFont(): Integer;
begin
 Result:= Length(Fonts);
 SetLength(Fonts, Result + 1);

 Fonts[Result]:= TAsphyreFont.Create(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.RemoveFont(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Fonts)) then Exit;

 FreeAndNil(Fonts[Index]);

 for i:= Index to Length(Fonts) - 2 do
  Fonts[i]:= Fonts[i + 1];

 SetLength(Fonts, Length(Fonts) - 1);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.Insert(const DescLink, ImageName: StdString): Integer;
var
 ImageIndex: Integer;
begin
 Result:= -1;

 // (1) Check whether a valid image list is provided.
 if (not Assigned(FImages)) then Exit;

 // (2) Resolve the bitmap font's graphics.
 ImageIndex:= FImages.Resolve(ImageName);
 if (ImageIndex = -1) then Exit;

 // (3) Create new font and try to parse its description.
 Result:= InsertFont();
 if (not Fonts[Result].ParseLink(DescLink)) then
  begin
   RemoveFont(Result);
   Result:= -1;
   Exit;
  end;

 // (4) Assign font attributes.
 Fonts[Result].ImageIndex:= ImageIndex;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.InsertTag(const Name: UniString;
 const Colors: TColor2; Style: Cardinal);
var
 Index: Integer;
begin
 Index:= Length(Tags);
 SetLength(Tags, Index + 1);

 Tags[Index].Name  := Name;
 Tags[Index].Colors:= Colors;
 Tags[Index].Style := Style;

 TagsDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.RemoveTags();
begin
 SetLength(Tags, 0);

 TagsDirty:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.DeleteTag(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Tags)) then Exit;

 for i:= Index to Length(Tags) - 2 do
  Tags[i]:= Tags[i + 1];

 SetLength(Tags, Length(Tags) - 1);

 TagsDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.SortSwapTags(Index1, Index2: Integer);
var
 Aux: TFontTag;
begin
 Aux:= Tags[Index1];

 Tags[Index1]:= Tags[Index2];
 Tags[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.SortSplitTags(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: UniString;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Tags[Start].Name;

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(UniCompareText(Tags[Left].Name, Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(UniCompareText(Tags[Right].Name, Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then SortSwapTags(Left, Right);
  end;

 SortSwapTags(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.QuicksortTags(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= SortSplitTags(Start, Stop);

   QuicksortTags(Start, SplitPt - 1);
   QuicksortTags(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.IndexOfTag(const Name: UniString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (TagsDirty) then
  begin
   QuicksortTags(0, Length(Tags) - 1);
   TagsDirty:= False;
  end;

 Result:= -1;

 Lo:= 0;
 Hi:= Length(Tags) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= UniCompareText(Tags[Mid].Name, Name);

   if (Res = 0) then
    begin
     Result:= Mid;
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.RemoveTag(const Name: UniString);
begin
 DeleteTag(IndexOfTag(Name));
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.FindTag(const Name: UniString): PFontTag;
var
 Index: Integer;
begin
 Index:= IndexOfTag(Name);

 if (Index <> -1) then
  Result:= @Tags[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.IndexOf(const AFontName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Fonts) - 1 do
  if (SameText(Fonts[i].Name, AFontName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.GetFont(const AFontName: StdString): TAsphyreFont;
var
 Index: Integer;
begin
 Result:= nil;

 Index:= IndexOf(AFontName);
 if (Index = -1) then Exit;

 Result:= Fonts[Index];
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.Resolve(const FontName: StdString): Integer;
var
 Desc: TFontDesc;
begin
 Result:= IndexOf(FontName);
 if (Result <> -1) then Exit;

 Desc:= FontGroups.FindFont(FontName);
 if (not Assigned(Desc)) then
  begin
   if (Assigned(FOnItemFail)) then FOnItemFail(Self, FontName, '');
   Exit;
  end;

 if (Assigned(FOnItemLoad)) then
  FOnItemLoad(Self, FontName, Desc.DataLink);

 Result:= Insert(Desc.DataLink, Desc.ImageName);
 if (Result = -1) then
  begin
   if (Assigned(FOnItemFail)) then
    FOnItemFail(Self, FontName, Desc.DataLink);
    
   Exit;
  end;

 Fonts[Result].Name      := Desc.FontName;
 Fonts[Result].Kerning   := Desc.Kerning;
 Fonts[Result].Whitespace:= Desc.Whitespace;
 Fonts[Result].Linespace := Desc.Linespace;
 Fonts[Result].Kernings.CopyFrom(Desc.LetterShifts);
end;

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
end.
