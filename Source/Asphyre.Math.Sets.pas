unit Asphyre.Math.Sets;
//---------------------------------------------------------------------------
// Helper classes to aid the development of application logic.
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
{< Helper classes such as integer lists, points and rectangle lists, and
   probabilistic choices that aid the development of application logic. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, System.SysUtils, System.Classes, System.Math, Asphyre.TypeDef, 
 Asphyre.Math;

//---------------------------------------------------------------------------
type
{$REGION 'Integer List declaration'}

//---------------------------------------------------------------------------
 TIntegerList = class;

//---------------------------------------------------------------------------
{@exclude}
 TIntegerListEnumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} FList: TIntegerList;
  Index: Integer;

  function GetCurrent(): Integer;
 public
  property Current: Integer read GetCurrent;

  function MoveNext(): Boolean;

  constructor Create(const AList: TIntegerList);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ A list of 32-bit signed integers with many functions that include ordering,
  shuffling and analysis. This class can also be used in for ... in loops,
  e.g. "for IntVal in MyList do", where IntVal will iterate through all
  numbers in the list. }
 TIntegerList = class
 private
  Data: array of Integer;
  DataCount: Integer;

  function GetItem(Index: Integer): Integer;
  procedure SetItem(Index: Integer; const Value: Integer);
  procedure Request(NeedCapacity: Integer);
  function GetMemAddr(): Pointer;
  function GetIntAvg(): Integer;
  function GetIntSum(): Integer;
  function GetIntMax(): Integer;
  function GetIntMin(): Integer;
  function GetRandomValue(): Integer;
  procedure ListSwap(Index1, Index2: Integer); inline;
  function ListCompare(Value1, Value2: Integer): Integer;
  function ListSplit(Start, Stop: Integer): Integer;
  procedure ListSort(Start, Stop: Integer);
  procedure SetCount(const Value: Integer);
 public
  { The pointer to the first element in list or @italic(nil) if no elements
    are present. }
  property MemAddr: Pointer read GetMemAddr;

  { The number of elements in the list. }
  property Count: Integer read DataCount write SetCount;

  { This property allows accessing the individual integer members by using
    their index, which should be in [0..(Count - 1)] range. If the index is
    out of valid range, @italic(Low(Integer)) is returned. Setting values
    with index outside of valid range does nothing. }
  property Items[Index: Integer]: Integer read GetItem
   write SetItem; default;

  { Returns the sum of all numbers in the list or zero if the list is empty. }
  property IntSum: Integer read GetIntSum;

  { Returns the average of all numbers in the list or zero if the list is
    empty. }
  property IntAvg: Integer read GetIntAvg;

  { Returns the highest (maximum) number in the list or zero if the list is
    empty. }
  property IntMax: Integer read GetIntMax;

  { Returns the lowest (minimum) number in the list or zero if the list is
    empty. }
  property IntMin: Integer read GetIntMin;

  { Returns a random number from the list or zero if the list is empty. }
  property RandomValue: Integer read GetRandomValue;

  { Returns the index of the first occurrence of the specified number in the
    list. If the number does not exist, -1 is returned. }
  function IndexOf(Value: Integer): Integer;

  { Inserts the given number into the list and returns its index. The number
    is added to the end of the list. }
  function Insert(Value: Integer): Integer; overload;

  { Inserts the given number at the beginning of the list, shifting all
    elements by one. The index of the element is not returned because it is
    always zero. }
  procedure InsertFirst(Value: Integer);

  { Removes number at the specified index, shifting all elements from that
    index and further by one. If the index is invalid, this function does
    nothing. }
  procedure Remove(Index: Integer);

  { Removes all elements in the list. }
  procedure Clear();

  { Sorts all numbers in the list in ascending order. }
  procedure Sort();

  { Swaps two numbers at the corresponding indexes. For performance reasons,
    this function does not test if the indexes are valid, therefore this
    method should be used with caution. }
  procedure Swap(Index0, Index1: Integer);

  { Copies all numbers from the source list. This list becomes exact copy of
    the source list. }
  procedure CopyFrom(const Source: TIntegerList);

  { Adds all numbers from the source list at the end of this list. }
  procedure AddFrom(const Source: TIntegerList);

  { Add elements from a user list specified by typed pointer. }
  procedure AddFromPtr(Source: PInteger; ElementCount: Integer);

  { Includes the given number to the end of list. If the number already exists,
    the method does nothing. }
  procedure Include(Value: Integer);

  { Removes the first occurrence of the given number in this list. If the
    number does not exist, the method does nothing. }
  procedure Exclude(Value: Integer);

  { Returns @True if the given number exists in the list and @False otherwise. }
  function Exists(Value: Integer): Boolean;

  { Replaces the contents of the current list with a new series of numbers
    starting from 0 and ending with @italic(NumCount - 1). }
  procedure Series(NumCount: Integer);

  { Adds a repeating sequence of the specified number to the end of list. }
  procedure InsertRepeatValue(Value, ValCount: Integer);

  { Shuffles the elements in the list by exchanging randomly numbers at
    different locations. This method is fast but it does not guarantee
    proper random distribution in small lists (for such purposes it is better
    to use @link(BestShuffle). It works better for larger lists. }
  procedure Shuffle();

  { Shuffles the elements in the list by creating a new list and extracting
    numbers randomly from this one. This method is slow but it guarantees the
    proper random distribution. For a faster alternative, use @link(Shuffle). }
  procedure BestShuffle();

  { Removes duplicate numbers from the list so that the resulting list has
    only numbers that are unique. }
  procedure RemoveDuplicates();

  { Returns text representation of the string e.g. "21, 7, 14, 10, 20". }
  function ChainToString(): StdString;

  { Specifies the number at the given location. If the specified index is
    bigger than the number of elements, additional zeros are added to fill
    the unused space. For instance, if the list is empty, calling
    @italic(DefineValueAtIndex(4, 15)) will add five zeros and set the fifth
    one to 15, so the list will become "0, 0, 0, 0, 15". If index is below
    zero, this method does nothing. }
  procedure DefineValueAtIndex(Index, Value: Integer);

  { Increments the number at the given position by one. If the index is
    bigger than the number of elements, additional zeros are added to fill
    the unused space similarly to @link(DefineValueAtIndex). }
  procedure IncrementValueAtIndex(Index: Integer);

  { Returns the number at the specified index. If the index is outside of
    valid range, zero is returned. }
  function GetValueAtIndex(Index: Integer): Integer;

  { Checks whether this list is an exact copy of the other list. }
  function IsSameAs(const OtherList: TIntegerList): Boolean;

  {@exclude}function GetEnumerator(): TIntegerListEnumerator;

  { Saves the entire list to stream. Each value is saved as 32-bit integer
    with an additional 32-bit integer used to define the length. }
  procedure SaveToStream(const Stream: TStream);

  { Loads the entire list from stream that was previously saved by
    @link(SaveToStream) method. }
  procedure LoadFromStream(const Stream: TStream);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Point List declaration'}

//---------------------------------------------------------------------------
{ Reference to @link(TPointHolder). }
 PPointHolder = ^TPointHolder;
{ 2D integer point holder with an additional slot for custom user data. }
 TPointHolder = record
  { 2D integer point. }
  Point: TPoint2px;
  { Custom user data. This can be used to store a reference to some class or
    structure. It can also be used as an integer variable typecast to
    @link(SizeInt) type. }
  Data: Pointer;
 end;

//---------------------------------------------------------------------------
{ List of 2D integer point holders that in addition to the vector itself
  contain a pointer to custom user data each. This list can be used when
  an association is needed between 2D points and some sort of data. }
 TPointList = class
 private
  Data: array of TPointHolder;
  DataCount: Integer;

  function GetItem(Index: Integer): PPointHolder;
  procedure Request(NeedCapacity: Integer);
  function GetMemAddr(): Pointer;
  function GetPoint(Index: Integer): PPoint2px;
 public
  { Returns pointer to the first element in the list or @nil otherwise. }
  property MemAddr: Pointer read GetMemAddr;

  { The number of elements in the list. }
  property Count: Integer read DataCount;

  { This property gives access to individual elements in the list by returning
    a reference to element at the given index, which should be in range of
    @italic([0..(Count - 1)]). If the index is outside of valid range, @nil
    is returned. }
  property Item[Index: Integer]: PPointHolder read GetItem; default;

  { This property allows accessing individual 2D points in the list directly
    ignoring the custom user data field. }
  property Point[Index: Integer]: PPoint2px read GetPoint;

  { Inserts the specified 2D point and custom user data to the end of list,
    returning the index where they were placed. }
  function Insert(const APoint: TPoint2px;
   AData: Pointer = nil): Integer; overload;

  { Inserts a new 2D point specified using individual coordinates along with
    custom user data to the end of list, returning the index where they were
    placed. }
  function Insert(x, y: Integer;
   AData: Pointer = nil): Integer; overload;

  { Removes the element at given index, shifting all elements by one from that
    location and further. If the index is outside of valid range, this method
    does nothing. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure Clear();

  { Returns the first occurrence of the given 2D point in the list. If the
    given point is not found, this function returns -1. }
  function IndexOf(const APoint: TPoint2px): Integer;

  { Includes the given 2D point and custom user data to the list. This method
    checks if the 2D point with the given coordinates already exists and in
    this case, does nothing. The custom user data is not checked. }
  procedure Include(const APoint: TPoint2px; AData: Pointer = nil);

  { Excludes the first occurrence of the given 2D point from the list. }
  procedure Exclude(const APoint: TPoint2px);

  { Copies all elements from the source list to this one. The new list
    becomes the exact copy of the source one. }
  procedure CopyFrom(const Source: TPointList);

  { Adds all elements from the source list to this one at the end of the
    list. }
  procedure AddFrom(const Source: TPointList);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Rect List declaration'}

//---------------------------------------------------------------------------
 TRectList = class;

//---------------------------------------------------------------------------
{@exclude}
 TRectListEnumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} FList: TRectList;
  Index: Integer;

  function GetCurrent(): TRect;
 public
  property Current: TRect read GetCurrent;

  function MoveNext(): Boolean;

  constructor Create(const AList: TRectList);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ List of standard rectangles which can be iterated using "for..in" loops. }
 TRectList = class
 private
  Data: array of TRect;
  DataCount: Integer;

  function GetItem(Index: Integer): PRect;
  procedure Request(NeedCapacity: Integer);
  function GetMemAddr(): Pointer;
 public
  { Returns pointer to the first element in the list of @nil if the list is
    empty. }
  property MemAddr: Pointer read GetMemAddr;

  { The number of elements in the list. }
  property Count: Integer read DataCount;

  { Provides access to individual rectangles in the list returning the
    reference to the rectangle specified by its index, which should be
    specified in @italic([0..(Count-1)]) range. If index is outside of valid
    range, the returned value is @nil. }
  property Item[Index: Integer]: PRect read GetItem; default;

  { Adds the given rectangle to the end of list, returning its index. }
  function Add(const Rect: TRect): Integer; overload;

  { Adds rectangle specified by the given top left corner and dimensions to
    the list and returns the index of the new element. }
  function Add(x, y, Width, Height: Integer): Integer; overload;

  { Removes element specified by the given index from the list, shifting other
    elements from that position and further by one. If the index is outside of
    valid range, this method does nothing. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure Clear();

  { Copies elements from the source list to this one, overwriting existing
    elements. The resulting list is the exact copy of the source list. }
  procedure CopyFrom(const Source: TRectList);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(const Source: TRectList);

  {@exclude}function GetEnumerator(): TRectListEnumerator;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Integer Probablity List declaration'}

//---------------------------------------------------------------------------
{ Pointer to @link(TIntProbHolder) that is usually used to pass that
  structure by reference, usually within @link(TIntProbList). }
 PIntProbHolder = ^TIntProbHolder;

{ Probabilistic number structure. Contains number and its probability that
  can be used by @link(TIntProbList) for random probabilistic selections. }
 TIntProbHolder = record
  { Number element that has its associated probability. }
  Value: Integer;
  { The probability of the accompanying number. This basically determines how
    important it is to the others. It must not be zero. }
  Prob: Single;
 end;

//---------------------------------------------------------------------------
{ List of probabilistic numbers, where individual pairs of numbers and their
  probabilities are specified, which can then be used for random selection. }
 TIntProbList = class
 private
  Data: array of TIntProbHolder;
  DataCount: Integer;

  function GetMemAddr(): Pointer;
  function GetItem(Index: Integer): PIntProbHolder;
  procedure Request(NeedCapacity: Integer);
  function GetValue(Index: Integer): Integer;
  function GetProbability(AValue: Integer): Single;
  procedure SetProbability(AValue: Integer; const Prob: Single);
  function GetRandValue(): Integer;
 public
  { Returns pointer to the first element in the list. If the list has no
    elements, the returned value is @nil. }
  property MemAddr: Pointer read GetMemAddr;

  { The number of elements in the list. }
  property Count: Integer read DataCount;

  { Provides access to individual elements in the list by index, which should
    be specified within range of @italic([0..(Count-1)]). If index is outside
    of valid range, the returned value is @nil. }
  property Item[Index: Integer]: PIntProbHolder read GetItem;

  { Provides access directly to individual numbers in the list ignoring the
    probabilistic part by index, which should be specified within range of
    @italic([0..(Count-1)]). If index is outside of valid range, zero is
    returned. }
  property Value[Index: Integer]: Integer read GetValue;

  { This property allows accessing and modifying the probability of each
    individual numbers in the list. If there are two identical numbers, only
    the first occurrence is modified. Each time this property is used, a search
    is made for the specified value. If the number does not exist in the list,
    the returned probability is zero. Setting probability for a number that is
    not in the list will add this number to the list with the specified
    probability.  }
  property Probability[Value: Integer]: Single
   read GetProbability write SetProbability; default;

  { Returns a number chosen randomly from the list using the probability
    field of each individual element. If duplicates are present in the list,
    they are treated as individual elements for probabilistic selection as
    well. If no elements are present in the list, the returned value is zero. }
  property RandValue: Integer read GetRandValue;

  { Inserts the given number with its probability to the list. This function
    does not check if this number already exists, so it can create duplicates. }
  function Insert(AValue: Integer; Prob: Single = 1.0): Integer;

  { Removes the element at the specified index from the list, shifting the rest
    of the elements by one. If the index is outside of valid range, this
    method does nothing. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure Clear();

  { Returns the index of the given number in the list. If duplicates are
    present, the index of first occurrence is returned. If the number is not
    found, the returned value is -1. }
  function IndexOf(AValue: Integer): Integer;

  { Includes the specified number with its probability to the list. If such
    number already exists, its probability is adjusted by the one specified
    in this method. If more than one number exists, only the first occurrence
    is modified.}
  procedure Include(AValue: Integer; Prob: Single = 1.0);

  { Excludes the specified number from the list. If multiple instances of such
    number exist, only the first occurrence is removed. If the number does not
    exist, this method does nothing. }
  procedure Exclude(AValue: Integer);

  { Replaces the contents of current list with series of numbers starting from
    zero and up to (MaxValue - 1) all with the same specified probability. }
  procedure Series(MaxValue: Integer; Prob: Single = 1.0);

  { Returns @True if the specified number exists in the list and @False
    otherwise. }
  function Exists(AValue: Integer): Boolean;

  { Adjusts the probability of the specified number by the given coefficient.
    If multiple instances of the same number exist, only the first occurrence
    is adjusted. If the number does not exist, this method does nothing. }
  procedure ScaleProbability(AValue: Integer; Scale: Single);

  { Adjusts the probability of all elements in the list by the specified
    coefficient except those elements that have the given number. If such
    number does not exist, simply all elements have their probability
    multiplied. If the list is empty or contains only the given number, this
    method does nothing. }
  procedure ScaleProbExcept(AValue: Integer; Scale: Single);

  { Copies the entire contents from the source list to this one, creating an
    identical copy. }
  procedure CopyFrom(const Source: TIntProbList);

  { Adds elements from the source list to this one. This method does not check
    for duplicates, it simply adds each and all of the elements from the source
    list. }
  procedure AddFrom(const Source: TIntProbList);

  { Saves the contents of this probabilistic list to the stream. }
  procedure SaveToStream(const Stream: TStream);

  { Loads the contents of the list from the source stream, replacing previous
    list. The contents must have been saved to the stream previously by
    @link(SaveToStream) method. }
  procedure LoadFromStream(const Stream: TStream);

  { Extracts a number from the list using the probabilities of each individual
    element. If duplicates are present, each duplicate is treated as unique
    element. The returned number is removed from the list, but only its first
    occurrence, if multiple instances are present. If only one element is
    present, after returning it the list becomes empty. If the list is empty,
    zero is returned. }
  function ExtractRandValue(): Integer;

  { Adjusts the existing probability values by normalizing them in such way so
    they sum to one. }
  procedure NormalizeAll();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Streams;

//---------------------------------------------------------------------------
{$REGION 'General definitions'}

//---------------------------------------------------------------------------
const
 ListGrowIncrement = 8;
 ListGrowFraction = 4;
 CacheSize = 32;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Integer List implementation'}

//---------------------------------------------------------------------------
constructor TIntegerListEnumerator.Create(const AList: TIntegerList);
begin
 inherited Create();

 Inc(AsphyreClassInstances);

 FList:= AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
destructor TIntegerListEnumerator.Destroy();
begin
 Dec(AsphyreClassInstances);

 inherited;
end;

//---------------------------------------------------------------------------
function TIntegerListEnumerator.GetCurrent(): Integer;
begin
 Result:= FList[Index];
end;

//---------------------------------------------------------------------------
function TIntegerListEnumerator.MoveNext(): Boolean;
begin
 Result:= Index < FList.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
constructor TIntegerList.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TIntegerList.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TIntegerList.GetEnumerator(): TIntegerListEnumerator;
begin
 Result:= TIntegerListEnumerator.Create(Self);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TIntegerList.GetItem(Index: Integer): Integer;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= Data[Index]
  else Result:= Low(Integer);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.SetItem(Index: Integer;
 const Value: Integer);
begin
 if (Index >= 0)and(Index < DataCount) then
  Data[Index]:= Value;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Request(NeedCapacity: Integer);
var
 NewCapacity, Capacity: Integer;
begin
 if (NeedCapacity < 1) then Exit;

 Capacity:= Length(Data);

 if (Capacity < NeedCapacity) then
  begin
   NewCapacity:= ListGrowIncrement + Capacity + (Capacity div ListGrowFraction);

   if (NewCapacity < NeedCapacity) then
    NewCapacity:= ListGrowIncrement + NeedCapacity + (NeedCapacity div
     ListGrowFraction);

   SetLength(Data, NewCapacity);
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.SetCount(const Value: Integer);
begin
 Request(Value);
 DataCount:= Value;
end;

//---------------------------------------------------------------------------
function TIntegerList.Insert(Value: Integer): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Value;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.InsertFirst(Value: Integer);
var
 i: Integer;
begin
 Request(DataCount + 1);

 for i:= DataCount - 1 downto 1 do
  Data[i]:= Data[i - 1];

 Data[0]:= Value;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.CopyFrom(const Source: TIntegerList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.AddFrom(const Source: TIntegerList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.AddFromPtr(Source: PInteger; ElementCount: Integer);
var
 i: Integer;
 InpValue: PInteger;
begin
 Request(DataCount + ElementCount);

 InpValue:= Source;

 for i:= 0 to ElementCount - 1 do
  begin
   Data[i + DataCount]:= InpValue^;
   Inc(InpValue);
  end;

 Inc(DataCount, ElementCount);
end;

//---------------------------------------------------------------------------
function TIntegerList.IndexOf(Value: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i] = Value) then
   begin
    Result:= i;
    Exit;
   end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Include(Value: Integer);
begin
 if (IndexOf(Value) = -1) then Insert(Value);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Exclude(Value: Integer);
var
 Index: Integer;
begin
 Index:= IndexOf(Value);
 if (Index <> -1) then Remove(Index);
end;

//---------------------------------------------------------------------------
function TIntegerList.Exists(Value: Integer): Boolean;
begin
 Result:= (IndexOf(Value) <> -1);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.BestShuffle();
var
 Aux: TIntegerList;
 Index: Integer;
begin
 Aux:= TIntegerList.Create();
 Aux.CopyFrom(Self);

 Clear();

 while (Aux.Count > 0) do
  begin
   Index:= Random(Aux.Count);
   Insert(Aux[Index]);
   Aux.Remove(Index);
  end;

 FreeAndNil(Aux);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Shuffle();
var
 i, Index: Integer;
 Aux: Integer;
begin
 for i:= DataCount - 1 downto 1 do
  begin
   Index:= Random(i + 1);

   Aux:= Data[i];
   Data[i]:= Data[Index];
   Data[Index]:= Aux;
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Series(NumCount: Integer);
var
 i: Integer;
begin
 Request(NumCount);
 DataCount:= NumCount;

 for i:= 0 to DataCount - 1 do
  Data[i]:= i;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.InsertRepeatValue(Value: Integer;
 ValCount: Integer);
var
 i: Integer;
begin
 Request(DataCount + ValCount);

 for i:= 0 to ValCount - 1 do
  Data[DataCount + i]:= Value;

 Inc(DataCount, ValCount);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntSum(): Integer;
var
 i: Integer;
begin
 Result:= 0;

 for i:= 0 to DataCount - 1 do
  Inc(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntAvg(): Integer;
begin
 if (DataCount > 0) then
  Result:= GetIntSum() div DataCount
   else Result:= 0;
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntMax(): Integer;
var
 i: Integer;
begin
 if (DataCount < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];

 for i:= 1 to DataCount - 1 do
  Result:= Max2(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntMin(): Integer;
var
 i: Integer;
begin
 if (DataCount < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];

 for i:= 1 to Length(Data) - 1 do
  Result:= Min2(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetRandomValue(): Integer;
begin
 if (DataCount > 0) then
  begin
   Result:= Data[Random(DataCount)];
  end else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.ListSwap(Index1, Index2: Integer);
var
 Aux: Integer;
begin
 Aux:= Data[Index1];

 Data[Index1]:= Data[Index2];
 Data[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TIntegerList.ListCompare(Value1, Value2: Integer): Integer;
begin
 Result:= 0;

 if (Value1 < Value2) then Result:= -1;
 if (Value1 > Value2) then Result:= 1;
end;

//---------------------------------------------------------------------------
function TIntegerList.ListSplit(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: Integer;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Data[Start];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(ListCompare(Data[Left], Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(ListCompare(Data[Right], Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then ListSwap(Left, Right);
  end;

 ListSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.ListSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= ListSplit(Start, Stop);

   ListSort(Start, SplitPt - 1);
   ListSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Sort();
begin
 if (DataCount > 1) then
  ListSort(0, DataCount - 1);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Swap(Index0, Index1: Integer);
begin
 if (Index0 >= 0)and(Index0 < DataCount)and(Index1 >= 0)and
  (Index1 < DataCount) then
  ListSwap(Index0, Index1);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.SaveToStream(const Stream: TStream);
var
 i: Integer;
begin
 StreamPutLongInt(Stream, DataCount);

 for i:= 0 to DataCount - 1 do
  StreamPutLongInt(Stream, Data[i]);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.LoadFromStream(const Stream: TStream);
var
 Amount, i: Integer;
begin
 Amount:= StreamGetLongInt(Stream);
 Request(Amount);

 for i:= 0 to Amount - 1 do
  Data[i]:= StreamGetLongInt(Stream);

 DataCount:= Amount;
end;

//---------------------------------------------------------------------------
function TIntegerList.IsSameAs(const OtherList: TIntegerList): Boolean;
var
 i: Integer;
begin
 // (1) Check if the list points to itself or if both lists are empty.
 Result:= (Self = OtherList)or
  ((DataCount < 1)and(OtherList.DataCount < 1));
 if (Result) then Exit;

 // (2) If the lists have different number of elements, they are not equals.
 if (DataCount <> OtherList.DataCount) then Exit;

 // (3) Test element one by one.
 for i:= 0 to DataCount - 1 do
  if (Data[i] <> OtherList.Data[i]) then Exit;

 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.RemoveDuplicates();
var
 i, j: Integer;
begin
 for j:= DataCount - 1 downto 0 do
  for i:= 0 to j - 1 do
   if (Data[j] = Data[i]) then
    begin
     Remove(j);
     Break;
    end;
end;

//---------------------------------------------------------------------------
function TIntegerList.ChainToString(): StdString;
var
 i: Integer;
begin
 Result:= '';

 for i:= 0 to DataCount - 1 do
  begin
   Result:= Result + IntToStr(Data[i]);
   if (i < DataCount - 1) then Result:= Result + ', ';
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.DefineValueAtIndex(Index: Integer;
 Value: Integer);
var
 StartAt, i: Integer;
begin
 if (Index < 0) then Exit;
 if (Index >= DataCount) then
  begin
   StartAt:= DataCount;

   Request(Index + 1);

   for i:= StartAt to Index - 1 do
    Data[i]:= 0;

   DataCount:= Index + 1;
  end;

 Data[Index]:= Value;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.IncrementValueAtIndex(Index: Integer);
var
 StartAt, i: Integer;
begin
 if (Index < 0) then Exit;
 if (Index >= DataCount) then
  begin
   StartAt:= DataCount;

   Request(Index + 1);

   for i:= StartAt to Index do
    Data[i]:= 0;

   DataCount:= Index + 1;
  end;

 Inc(Data[Index]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetValueAtIndex(Index: Integer): Integer;
begin
 if (Index >= 0)and(Index < DataCount) then
  Result:= Data[Index] else Result:= 0;
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Point List implementation'}

//---------------------------------------------------------------------------
constructor TPointList.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPointList.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TPointList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TPointList.GetItem(Index: Integer): PPointHolder;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TPointList.GetPoint(Index: Integer): PPoint2px;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index].Point
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TPointList.Request(NeedCapacity: Integer);
var
 NewCapacity, Capacity: Integer;
begin
 if (NeedCapacity < 1) then Exit;

 Capacity:= Length(Data);

 if (Capacity < NeedCapacity) then
  begin
   NewCapacity:= ListGrowIncrement + Capacity + (Capacity div ListGrowFraction);

   if (NewCapacity < NeedCapacity) then
    NewCapacity:= ListGrowIncrement + NeedCapacity + (NeedCapacity div
     ListGrowFraction);

   SetLength(Data, NewCapacity);
  end;
end;

//---------------------------------------------------------------------------
function TPointList.Insert(const APoint: TPoint2px;
 AData: Pointer = nil): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Self.Data[Index].Point:= APoint;
 Self.Data[Index].Data := AData;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPointList.Insert(x, y: Integer; AData:
 Pointer = nil): Integer;
begin
 Result:= Insert(Point2px(x, y), AData);
end;

//---------------------------------------------------------------------------
procedure TPointList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
function TPointList.IndexOf(const APoint: TPoint2px): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i].Point = APoint) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TPointList.Include(const APoint: TPoint2px; AData: Pointer = nil);
begin
 if (IndexOf(APoint) = -1) then Insert(APoint, AData);
end;

//---------------------------------------------------------------------------
procedure TPointList.Exclude(const APoint: TPoint2px);
begin
 Remove(IndexOf(APoint));
end;

//---------------------------------------------------------------------------
procedure TPointList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPointList.CopyFrom(const Source: TPointList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPointList.AddFrom(const Source: TPointList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Rect List implementation'}

//---------------------------------------------------------------------------
constructor TRectListEnumerator.Create(const AList: TRectList);
begin
 inherited Create();

 Inc(AsphyreClassInstances);

 FList:= AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
destructor TRectListEnumerator.Destroy();
begin
 Dec(AsphyreClassInstances);

 inherited;
end;

//---------------------------------------------------------------------------
function TRectListEnumerator.GetCurrent(): TRect;
begin
 Result:= FList[Index]^;
end;

//---------------------------------------------------------------------------
function TRectListEnumerator.MoveNext(): Boolean;
begin
 Result:= Index < FList.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
constructor TRectList.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TRectList.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TRectList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TRectList.GetItem(Index: Integer): PRect;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TRectList.Request(NeedCapacity: Integer);
var
 NewCapacity, Capacity: Integer;
begin
 if (NeedCapacity < 1) then Exit;

 Capacity:= Length(Data);

 if (Capacity < NeedCapacity) then
  begin
   NewCapacity:= ListGrowIncrement + Capacity + (Capacity div ListGrowFraction);

   if (NewCapacity < NeedCapacity) then
    NewCapacity:= ListGrowIncrement + NeedCapacity + (NeedCapacity div
     ListGrowFraction);

   SetLength(Data, NewCapacity);
  end;
end;

//---------------------------------------------------------------------------
function TRectList.Add(const Rect: TRect): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Rect;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TRectList.Add(x, y, Width, Height: Integer): Integer;
begin
 Result:= Add(Bounds(x, y, Width, Height));
end;

//---------------------------------------------------------------------------
procedure TRectList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TRectList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TRectList.CopyFrom(const Source: TRectList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TRectList.AddFrom(const Source: TRectList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TRectList.GetEnumerator(): TRectListEnumerator;
begin
 Result:= TRectListEnumerator.Create(Self);
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Integer Probability List implementation'}

//---------------------------------------------------------------------------
constructor TIntProbList.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TIntProbList.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;


//---------------------------------------------------------------------------
function TIntProbList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TIntProbList.GetItem(Index: Integer): PIntProbHolder;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TIntProbList.GetValue(Index: Integer): Integer;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= Data[Index].Value
  else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Request(NeedCapacity: Integer);
var
 NewCapacity, Capacity: Integer;
begin
 if (NeedCapacity < 1) then Exit;

 Capacity:= Length(Data);

 if (Capacity < NeedCapacity) then
  begin
   NewCapacity:= ListGrowIncrement + Capacity + (Capacity div ListGrowFraction);

   if (NewCapacity < NeedCapacity) then
    NewCapacity:= ListGrowIncrement + NeedCapacity + (NeedCapacity div
     ListGrowFraction);

   SetLength(Data, NewCapacity);
  end;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
function TIntProbList.IndexOf(AValue: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i].Value = AValue) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TIntProbList.Insert(AValue: Integer;
 Prob: Single): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index].Value:= AValue;
 Data[Index].Prob := Prob;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Include(AValue: Integer; Prob: Single);
var
 Index: Integer;
begin
 Index:= IndexOf(AValue);
 if (Index <> -1) then Data[Index].Prob:= Prob
  else Insert(AValue, Prob);
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Exclude(AValue: Integer);
begin
 Remove(IndexOf(AValue));
end;

//---------------------------------------------------------------------------
function TIntProbList.Exists(AValue: Integer): Boolean;
begin
 Result:= IndexOf(AValue) <> -1;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TIntProbList.CopyFrom(const Source: TIntProbList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.AddFrom(const Source: TIntProbList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TIntProbList.GetProbability(AValue: Integer): Single;
var
 Index: Integer;
begin
 Index:= IndexOf(AValue);
 if (Index <> -1) then Result:= Data[Index].Prob else Result:= 0.0;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.SetProbability(AValue: Integer;
 const Prob: Single);
var
 Index: Integer;
begin
 Index:= IndexOf(AValue);

 if (Index <> -1) then Data[Index].Prob:= Prob
  else Insert(AValue, Prob);
end;

//---------------------------------------------------------------------------
procedure TIntProbList.Series(MaxValue: Integer; Prob: Single);
var
 i: Integer;
begin
 Clear();

 for i:= 0 to MaxValue - 1 do
  Insert(i, Prob);
end;

//---------------------------------------------------------------------------
function TIntProbList.GetRandValue(): Integer;
var
 Sample, SampleMax, SampleIn: Single;
 i: Integer;
begin
 Result:= 0;
 if (DataCount < 1) then Exit;

 SampleMax:= 0.0;

 for i:= 0 to DataCount - 1 do
  SampleMax:= SampleMax + Data[i].Prob;

 Sample:= Random() * SampleMax;

 SampleIn:= 0.0;
 for i:= 0 to DataCount - 1 do
  begin
   if (Sample >= SampleIn)and(Sample < SampleIn + Data[i].Prob) then
    begin
     Result:= Data[i].Value;
     Exit;
    end;

   SampleIn:= SampleIn + Data[i].Prob;
  end;
end;

//---------------------------------------------------------------------------
function TIntProbList.ExtractRandValue(): Integer;
var
 Sample, SampleMax, SampleIn: Single;
 i, SampleNo: Integer;
begin
 Result:= 0;
 if (DataCount < 1) then Exit;

 SampleMax:= 0.0;

 for i:= 0 to DataCount - 1 do
  SampleMax:= SampleMax + Data[i].Prob;

 Sample:= Random() * SampleMax;

 SampleIn:= 0.0;
 SampleNo:= -1;

 for i:= 0 to DataCount - 1 do
  begin
   if (Sample >= SampleIn)and(Sample < SampleIn + Data[i].Prob) then
    begin
     Result := Data[i].Value;
     SampleNo:= i;

     Break;
    end;

   SampleIn:= SampleIn + Data[i].Prob;
  end;

 if (SampleNo <> -1) then Remove(SampleNo);
end;

//---------------------------------------------------------------------------
procedure TIntProbList.SaveToStream(const Stream: TStream);
var
 i: Integer;
begin
 StreamPutLongInt(Stream, DataCount);

 for i:= 0 to DataCount - 1 do
  begin
   StreamPutLongInt(Stream, Data[i].Value);
   StreamPutSingle(Stream, Data[i].Prob);
  end;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.LoadFromStream(const Stream: TStream);
var
 i, Total: Integer;
begin
 Total:= StreamGetLongInt(Stream);

 Request(Total);

 for i:= 0 to Total - 1 do
  begin
   Data[i].Value:= StreamGetLongInt(Stream);
   Data[i].Prob := StreamGetSingle(Stream);
  end;

 DataCount:= Total;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.ScaleProbability(AValue: Integer;
 Scale: Single);
var
 Index: Integer;
begin
 Index:= IndexOf(AValue);
 if (Index <> -1) then Data[Index].Prob:= Data[Index].Prob * Scale;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.ScaleProbExcept(AValue: Integer;
 Scale: Single);
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  if (Data[i].Value <> AValue) then Data[i].Prob:= Data[i].Prob * Scale;
end;

//---------------------------------------------------------------------------
procedure TIntProbList.NormalizeAll();
var
 i: Integer;
 Total: Single;
begin
 Total:= 0.0;

 for i:= 0 to DataCount - 1 do
  Total:= Total + Data[i].Prob;

 if (Total <= 0.0) then Exit;

 for i:= 0 to DataCount - 1 do
  Data[i].Prob:= Data[i].Prob / Total;
end;

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
end.
