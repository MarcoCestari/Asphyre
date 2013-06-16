unit Asphyre.Events.Types;
//---------------------------------------------------------------------------
// Asphyre Event System implementing observer pattern.
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
{< Event foundations for Asphyre based on observer pattern using subscription
   mechanism. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils, System.Classes,
{$else}
 SysUtils, Classes,
{$endif}
 Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
{ Event callback function used by the majority of Asphyre events.
   @param(Sender Sender class used in event invocation, in certain situations
    this parameter may be set to @nil.)
   @param(Param Event-specific parameter that may be optionally passed by
    the notifier class. In most cases this parameter has value of @nil.)
   @param(Handled Determines whether to continue sending event to all other
    subscribed classes. If this parameter is set to @True, the event handling
    will be finished and further subscribers will not be notified.) }
 TEventCallbackType = procedure(const Sender: TObject; const Param: Pointer;
  var Handled: Boolean) of object;

//---------------------------------------------------------------------------
{@exclude}PEventRecord = ^TEventRecord;
{@exclude}TEventRecord = record
  EventId  : Integer;
  Callback : TEventCallbackType;
  ClassName: StdString;
  Priority1: Integer;
  Priority2: Integer;
 end;

//---------------------------------------------------------------------------
 TEventProvider  = class;
 TEventProviders = class;

//---------------------------------------------------------------------------
{ Event validation callback function. This function is called to filter
  subscribers that should or should not receive the current event. For
  instance, when some button is clicked, only the class handling the active
  window should receive and handle the event; such validation should be done
  inside this event.
   @param(Provider Reference to the provider that was used in event
    invocation.)
   @param(Sender Sender class that called the event. For instance, when a
    button is clicked, the sender will be the button class itself. In some
    cases, this parameter may be @nil.)
   @param(Param Application-specific parameter sent by the caller class. This
    parameter is typically set to @nil.)
   @param(ClassName The name of the subscriber class that is currently being
    validated to receive the event.)
   @param(Allowed Determines whether the class that is currently being
    validated should receive the event or not. This parameter is by default
    set to @True; setting it to @False inside this event will skip the
    class identified by @code(ClassName) for the current event.) }
 TEventValidatorType = procedure(Provider: TEventProvider; Sender: TObject;
  Param: Pointer; const ClassName: StdString; var Allowed: Boolean) of object;

//---------------------------------------------------------------------------
{ Event subscription class implementing observer pattern. Recipient classes
  are added to the subscriber list to receive notifactions of events sent by
  other classes. }
 TEventProvider = class
 private
  Data: array of TEventRecord;
  {$ifdef DelphiNextGen}[weak]{$endif}FOwner: TEventProviders;
  EventListDirty: Boolean;

  FEventValidator: TEventValidatorType;

  function NextEventId(): Integer;
  function IndexOfId(EventId: Integer): Integer;

  procedure EventListSwap(Index1, Index2: Integer);
  function EventListCompare(Index1, Index2: Integer): Integer;
  function EventListSplit(Start, Stop: Integer): Integer;
  procedure EventListSort(Start, Stop: Integer);
  procedure UpdateEventList();
  procedure RemoveAll();
  procedure Remove(Index: Integer);
 public
  { The owner class that contains the list of all existing providers. }
  property Owner: TEventProviders read FOwner;

  { Event validation callback that filters which events should be received
    by which classes depending on different circumstances. }
  property EventValidator: TEventValidatorType read FEventValidator
   write FEventValidator;

  { Subscribes the given class and its event handling callback to receive all
    events sent from this provider. If the priority is set, the class will
    receive events depending on the list of priorities either after or
    before other events depending on priority settings. This function returns
    the identification number of the subscribed function, which can later be
    used to unsubscribe from this provider using @link(Unsubscribe) method. }
  function Subscribe(const AClassName: StdString;
   const Callback: TEventCallbackType; const Priority: Integer = -1): Integer;

  { Unsubscribes the event callback function registered using the specified
    ID, which is usually returned by @link(Subscribe) function. }
  procedure Unsubscribe(const EventId: Integer);

  { Unsubscribes all event callbacks registered to the specified class. }
  procedure UnsubscribeClass(const AClassName: StdString);

  { Sets the secondary priority of all event callback functions registered to
    the specified class. This secondary priority is used after the first
    primary priority is applied (the one passed to @link(Subscribe)
    function). }
  function SetClassPriority(const AClassName: StdString;
   const Priority: Integer): Boolean;

  { Marks the priority list of all event callback functions dirty, so it is
    refreshed next time an event occurs. This should be called after changing
    the priority of some class. }
  procedure MarkEventListDirty();

  { Send event notification to all subscribed classes and their callback
    functions, filtered through @link(EventValidator) event. }
  function Notify(const Sender: TObject; const Param: Pointer = nil): Boolean;

  {@exclude}constructor Create(const AOwner: TEventProviders);
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ List of all available event providers based on observer pattern where
  subscriber classes are notified of the events sent by other classes. }
 TEventProviders = class
 private
  ExecOrder: TStringList;
  EventListsDirty: Boolean;

  Data: array of TEventProvider;
  ListSemaphore: Boolean;

  function GetItem(Index: Integer): TEventProvider;
  function GetItemCount(): Integer;
 protected
  { Includes the specified provider to the list. }
  function Include(AProvider: TEventProvider): Integer;

  { Excludes the specified provider from the list. }
  procedure Exclude(AProvider: TEventProvider);

  { Specifies new priority list for all providers and their callback functions
    using the list given by the sequence of @link(AddExecOrder) function
    calls. }
  procedure CheckEventLists();
 public
  { Number of registered provider classes in the list. }
  property ItemCount: Integer read GetItemCount;

  { Access to individual provider classes in the list.}
  property Items[Index: Integer]: TEventProvider read GetItem; default;

  { Defines the next execution order for all event callback functions of in all
    existing providers for the given class. This method should be called in a
    sequence for all registered classes to define in which order they should
    receive events. }
  procedure AddExecOrder(const AClassName: StdString);

  { Clears all the event ordering initially specified by @link(AddExecOrder)
    for all classes and callback functions. }
  procedure ClearExecOrder();

  { Removes all providers from the list. }
  procedure Clear();

  { Returns the index of the specified provider in the list. }
  function IndexOf(AProvider: TEventProvider): Integer;

  { Removes provider at the specified index from the list. }
  procedure Remove(Index: Integer);

  { Inserts a new provider to the end of the list and returns its index. }
  function Insert(): Integer;

  { Adds a new provider to the end of the list and returns the reference to
    its class. }
  function Add(): TEventProvider;

  { Notifies all providers that their event priority list is dirty and should
    be updated the next time an event occurs. This can occur when the ordering
    list has been changed. }
  procedure MarkEventListsDirty();

  { Unsubscribes all existing event callback functions for the specified class
    from all existing providers. }
  procedure Unsubscribe(const AClassName: StdString);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ List of all existing Asphyre event providers implementing observer pattern.
  This class is an instance of @link(TEventProviders) which is ready to use
  in the application. }
 EventProviders: TEventProviders{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
var
 GlobEventId: Integer = 0;

//---------------------------------------------------------------------------
constructor TEventProvider.Create(const AOwner: TEventProviders);
begin
 inherited Create();

 Inc(AsphyreClassInstances);

 FOwner:= AOwner;
 if (Assigned(FOwner)) then FOwner.Include(Self);

 EventListDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TEventProvider.Destroy();
begin
 Dec(AsphyreClassInstances);

 RemoveAll();
 if (Assigned(FOwner)) then FOwner.Exclude(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TEventProvider.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data)) then Exit;

 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
 MarkEventListDirty();
end;

//---------------------------------------------------------------------------
procedure TEventProvider.RemoveAll();
begin
 SetLength(Data, 0);
 MarkEventListDirty();
end;

//---------------------------------------------------------------------------
function TEventProvider.NextEventId(): Integer;
begin
 Result:= GlobEventId;
 Inc(GlobEventId);
end;

//---------------------------------------------------------------------------
function TEventProvider.Subscribe(const AClassName: StdString;
 const Callback: TEventCallbackType; const Priority: Integer = -1): Integer;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index].EventId  := NextEventId();
 Data[Index].Callback := Callback;
 Data[Index].ClassName:= AClassName;
 Data[Index].Priority1:= Priority;
 Data[Index].Priority2:= -1;

 MarkEventListDirty();

 Result:= Data[Index].EventId;
end;

//---------------------------------------------------------------------------
function TEventProvider.IndexOfId(EventId: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].EventId = EventId) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TEventProvider.Unsubscribe(const EventId: Integer);
var
 Index: Integer;
begin
 Index:= IndexOfId(EventId);
 if (Index = -1) then Exit;

 Remove(Index);
end;

//---------------------------------------------------------------------------
procedure TEventProvider.MarkEventListDirty();
begin
 EventListDirty:= True;
 if (Assigned(FOwner)) then FOwner.MarkEventListsDirty();
end;

//---------------------------------------------------------------------------
procedure TEventProvider.UnsubscribeClass(const AClassName: StdString);
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  if (SameText(Data[i].ClassName, AClassName)) then
   Remove(i);
end;

//---------------------------------------------------------------------------
function TEventProvider.SetClassPriority(const AClassName: StdString;
 const Priority: Integer): Boolean;
var
 i: Integer;
begin
 Result:= False;

 for i:= 0 to Length(Data) - 1 do
  if (SameText(Data[i].ClassName, AClassName)) then
   begin
    Data[i].Priority2:= Priority;
    EventListDirty:= True;
    Result:= True;
   end;
end;

//---------------------------------------------------------------------------
procedure TEventProvider.EventListSwap(Index1, Index2: Integer);
var
 Aux: TEventRecord;
begin
 Aux:= Data[Index1];

 Data[Index1]:= Data[Index2];
 Data[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TEventProvider.EventListCompare(Index1, Index2: Integer): Integer;
begin
 Result:= 0;

 if (Data[Index1].Priority1 > Data[Index2].Priority1) then Result:= 1;
 if (Data[Index1].Priority1 < Data[Index2].Priority1) then Result:= -1;

 if (Result = 0) then
  begin
   if (Data[Index1].Priority2 > Data[Index2].Priority2) then Result:= 1;
   if (Data[Index1].Priority2 < Data[Index2].Priority2) then Result:= -1;
  end;

 if (Result = 0) then
  Result:= CompareText(Data[Index1].ClassName, Data[Index2].ClassName);

 if (Result = 0) then
  begin
   if (Data[Index1].EventId > Data[Index2].EventId) then Result:= 1;
   if (Data[Index1].EventId < Data[Index2].EventId) then Result:= -1;
  end;
end;

//---------------------------------------------------------------------------
function TEventProvider.EventListSplit(Start, Stop: Integer): Integer;
var
 Left, Right, Pivot: Integer;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Start;

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(EventListCompare(Left, Pivot) < 0) do Inc(Left);
   while (Right > Start)and(EventListCompare(Right, Pivot) >= 0) do Dec(Right);

   if (Left < Right) then EventListSwap(Left, Right);
  end;

 EventListSwap(Start, Right);
 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TEventProvider.EventListSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= EventListSplit(Start, Stop);

   EventListSort(Start, SplitPt - 1);
   EventListSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TEventProvider.UpdateEventList();
begin
 if (Length(Data) > 1) then
  EventListSort(0, Length(Data) - 1);

 EventListDirty:= False;
end;

//---------------------------------------------------------------------------
function TEventProvider.Notify(const Sender: TObject;
 const Param: Pointer = nil): Boolean;
var
 i: Integer;
 Allowed: Boolean;
begin
 if (Assigned(FOwner)) then FOwner.CheckEventLists();
 if (EventListDirty) then UpdateEventList();

 Result:= False;
 for i:= 0 to Length(Data) - 1 do
  begin
   if (Assigned(FEventValidator)) then
    begin
     Allowed:= True;
     FEventValidator(Self, Sender, Param, Data[i].ClassName, Allowed);
     if (not Allowed) then Continue;
    end;

   Data[i].Callback(Sender, Param, Result);
   if (Result) then Break;
  end;
end;

//---------------------------------------------------------------------------
constructor TEventProviders.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 ExecOrder:= TStringList.Create();
 EventListsDirty:= False;

 ListSemaphore:= False;
end;

//---------------------------------------------------------------------------
destructor TEventProviders.Destroy();
begin
 Dec(AsphyreClassInstances);

 Clear();
 FreeAndNil(ExecOrder);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.AddExecOrder(const AClassName: StdString);
var
 Index: Integer;
begin
 Index:= ExecOrder.IndexOf(AClassName);
 if (Index <> -1) then ExecOrder.Delete(Index);

 ExecOrder.Append(AClassName);
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.ClearExecOrder();
begin
 ExecOrder.Clear();
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
function TEventProviders.GetItemCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TEventProviders.GetItem(Index: Integer): TEventProvider;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= Data[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.Clear();
var
 i: Integer;
begin
 if (ListSemaphore) then Exit;
 ListSemaphore:= True;

 for i:= Length(Data) - 1 downto 0 do
  if (Assigned(Data[i])) then FreeAndNil(Data[i]);

 SetLength(Data, 0);

 ListSemaphore:= False;
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
function TEventProviders.IndexOf(AProvider: TEventProvider): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = AProvider) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data))or(ListSemaphore) then Exit;

 ListSemaphore:= True;

 if (Assigned(Data[Index])) then FreeAndNil(Data[Index]);

 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);

 ListSemaphore:= False;
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
function TEventProviders.Include(AProvider: TEventProvider): Integer;
begin
 if (ListSemaphore) then
  begin
   Result:= -1;
   Exit;
  end;

 Result:= IndexOf(AProvider);
 if (Result = -1) then
  begin
   Result:= Length(Data);
   SetLength(Data, Result + 1);

   Data[Result]:= AProvider;
  end;

 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.Exclude(AProvider: TEventProvider);
var
 Index, i: Integer;
begin
 if (ListSemaphore) then Exit;

 Index:= IndexOf(AProvider);
 if (Index = -1) then Exit;

 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
function TEventProviders.Insert(): Integer;
begin
 if (ListSemaphore) then
  begin
   Result:= -1;
   Exit;
  end;

 ListSemaphore:= True;

 Result:= Length(Data);
 SetLength(Data, Result + 1);

 Data[Result]:= TEventProvider.Create(Self);

 ListSemaphore:= False;
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
function TEventProviders.Add(): TEventProvider;
begin
 Result:= GetItem(Insert());
end;

//---------------------------------------------------------------------------
procedure TEventProviders.MarkEventListsDirty();
begin
 EventListsDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.CheckEventLists();
var
 AClassName : StdString;
 CurPriority: Integer;
 Processed: Boolean;
 i: Integer;
begin
 if (not EventListsDirty) then Exit;

 CurPriority:= 1;

 for AClassName in ExecOrder do
  begin
   Processed:= False;

   for i:= 0 to Length(Data) - 1 do
    if (Data[i].SetClassPriority(AClassName, CurPriority)) then
     Processed:= True;

   if (Processed) then Inc(CurPriority);
  end;

 EventListsDirty:= False;
end;

//---------------------------------------------------------------------------
procedure TEventProviders.Unsubscribe(const AClassName: StdString);
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  Data[i].UnsubscribeClass(AClassName);
end;

//---------------------------------------------------------------------------
initialization
 EventProviders:= TEventProviders.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(EventProviders);

//---------------------------------------------------------------------------
end.
