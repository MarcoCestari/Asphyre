unit GameObjects;
//---------------------------------------------------------------------------
// GameObjects.pas
//---------------------------------------------------------------------------
//
// This unit describes abstract game objects that move in 3D space and each
// one is rendered separately.
//
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Math, Vectors2px, Vectors3, Vectors4, Matrices4, GameTypes, GameMeshes,
 GameEvents, GameEventPriorities;

//---------------------------------------------------------------------------
const
 UnknownID = High(Cardinal);

//---------------------------------------------------------------------------
type
 TGameObjects = class;

//---------------------------------------------------------------------------
 TGameObject = class
 private
  FID   : Cardinal;
  FNext : TGameObject;
  FPrev : TGameObject;
  FOwner: TGameObjects;

  Disposed : Boolean;
  NoExclude: Boolean;

  FSomeTicks: Integer;

  function GetLocalTime(const Theta: Single): Single;
  function GetProjPos(Depth: Single): TPoint2px;
 protected
  FPosition: TVector3;

  procedure DoMove(); virtual;
  procedure PostDraw(); virtual;
 public
  property ID   : Cardinal read FID;
  property Prev : TGameObject read FPrev write FPrev;
  property Next : TGameObject read FNext write FNext;
  property Owner: TGameObjects read FOwner;

  // Local time for the object using specified scale for seconds.
  //  -> with Theta = 1.0, the resulting value is number of seconds.
  property LocalTime[const Theta: Single]: Single read GetLocalTime;

  // A randomized tick counter.
  property SomeTicks: Integer read FSomeTicks;

  // Object position in 3D space.
  property Position: TVector3 read FPosition write FPosition;

  // Projected object position to screen.
  property ProjPos[Depth: Single]: TPoint2px read GetProjPos;

  procedure Dispose();
  procedure Draw(); virtual; abstract;
  procedure Move();

  constructor Create(AOwner: TGameObjects);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TGameObjects = class
 private
  FFirstNode: TGameObject;
  FLastNode : TGameObject;

  SearchList : array of TGameObject;
  SearchCount: Integer;
  SearchDirty: Boolean;

  CurrentID: Cardinal;

  MoveHandle    : Cardinal;
  DrawHandle    : Cardinal;
  PostDrawHandle: Cardinal;
  ResetHandle   : Cardinal;

  function GenerateID(): Integer; virtual;

  procedure Include(NewNode: TGameObject); virtual;
  procedure Exclude(Node: TGameObject); virtual;

  procedure ApplySearchList(Amount: Integer);
  procedure InitSearchList();
  procedure SortSearchList(Left, Right: Integer);
  procedure MakeSearchList();
  function FindByID(ID: Cardinal): TGameObject;
  function GetCount(): Integer;

  procedure DoMove(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
  procedure DoDraw(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
  procedure DoPostDraw(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
  procedure DoGameReset(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
 public
  property FirstNode: TGameObject read FFirstNode;
  property LastNode : TGameObject read FLastNode;

  property Items[ID: Cardinal]: TGameObject read FindByID; default;
  property Count: Integer read GetCount;

  procedure RemoveAll();

  procedure Move();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 Objects: TGameObjects = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 GameScene;

//---------------------------------------------------------------------------
const
 // the rounding cache for object ordering
 DirtyCache = 64;

//---------------------------------------------------------------------------
constructor TGameObject.Create(AOwner: TGameObjects);
begin
 inherited Create();

 FPrev := nil;
 FNext := nil;
 FOwner:= AOwner;

 NoExclude:= False;
 Disposed := False;

 FSomeTicks:= Random(65536);

 if (FOwner <> nil) then
  begin
   FID:= FOwner.GenerateID();
   FOwner.Include(Self);
  end;
end;

//---------------------------------------------------------------------------
destructor TGameObject.Destroy();
begin
 if (not NoExclude)and(FOwner <> nil) then FOwner.Exclude(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGameObject.Dispose();
begin
 Disposed:= True;
end;

//---------------------------------------------------------------------------
procedure TGameObject.DoMove();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGameObject.Move();
begin
 DoMove();

 Inc(FSomeTicks);
end;

//---------------------------------------------------------------------------
procedure TGameObject.PostDraw();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TGameObject.GetLocalTime(const Theta: Single): Single;
const
 Norm = 1.0 / 60.0;
begin
 Result:= FSomeTicks * Theta * Norm;
end;

//---------------------------------------------------------------------------
function TGameObject.GetProjPos(Depth: Single): TPoint2px;
var
 ProjVec: TVector4;
begin
 ProjVec:= FPosition;
 ProjVec.z:= ProjVec.z + Depth;
 ProjVec:= ProjVec * Scene.ViewMtx.RawMtx^;
 ProjVec:= ProjVec * Scene.ProjMtx.RawMtx^;
 if (ProjVec.z < Scene.NearPlane) then
  begin
   Result:= InfPoint2px;
   Exit;
  end;

 ProjVec:= ProjVec / ProjVec.w;

 Result.x:= Round((ProjVec.x + 1.0) * DisplaySize.x * 0.5);
 Result.y:= Round((1.0 - ProjVec.y) * DisplaySize.y * 0.5);

 if (Result.x < 0)or(Result.x >= DisplaySize.x)or(Result.y < 0)or
  (Result.y >= DisplaySize.y) then Result:= InfPoint2px;
end;

//---------------------------------------------------------------------------
constructor TGameObjects.Create();
begin
 inherited;

 FFirstNode:= nil;
 FLastNode := nil;

 SearchDirty:= False;
 SearchCount:= 0;

 CurrentID:= 0;

 ResetHandle   := EventGameReset.Subscribe(DoGameReset, -1);
 MoveHandle    := EventSceneMove.Subscribe(DoMove, PriorityMoveObjects);
 DrawHandle    := EventSceneDraw.Subscribe(DoDraw, PrioritySceneDrawObjects);
 PostDrawHandle:= EventPostDraw.Subscribe(DoPostDraw, PriorityPostDrawObjects);
end;

//---------------------------------------------------------------------------
destructor TGameObjects.Destroy();
begin
 RemoveAll();

 EventPostDraw.Unsubscribe(PostDrawHandle);
 EventSceneDraw.Unsubscribe(DrawHandle);
 EventSceneMove.Unsubscribe(MoveHandle);
 EventGameReset.Unsubscribe(ResetHandle);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.DoGameReset(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 RemoveAll();
end;

//---------------------------------------------------------------------------
function TGameObjects.GenerateID(): Integer;
begin
 if (CurrentID = High(Cardinal)) then Inc(CurrentiD);

 Result:= CurrentID;
 Inc(CurrentID);
end;

//---------------------------------------------------------------------------
procedure TGameObjects.RemoveAll();
var
 Node, Temp: TGameObject;
begin
 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   Temp:= Node;
   Node:= Node.Next;

   Temp.NoExclude:= True;
   Temp.Free();
  end;

 FFirstNode:= nil;
 FLastNode := nil;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.Include(NewNode: TGameObject);
begin
 SearchDirty:= True;

 if (FFirstNode = nil) then
  begin
   FFirstNode:= NewNode;
   FLastNode := NewNode;
   NewNode.Prev:= nil;
   NewNode.Next:= nil;
  end else
  begin
   NewNode.Next:= FFirstNode;
   NewNode.Prev:= nil;

   FFirstNode.Prev:= NewNode;
   FFirstNode:= NewNode;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.Exclude(Node: TGameObject);
begin
 SearchDirty:= True;

 if (Node.Prev = nil) then FFirstNode:= Node.Next
  else Node.Prev.Next:= Node.Next;

 if (Node.Next = nil) then FLastNode:= Node.Prev
  else Node.Next.Prev:= Node.Prev;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.ApplySearchList(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / DirtyCache) * DirtyCache;
 if (Length(SearchList) < Required) then SetLength(SearchList, Required);
end;

//---------------------------------------------------------------------------
procedure TGameObjects.InitSearchList();
var
 Index: Integer;
 Aux: TGameObject;
begin
 Index:= 0;
 Aux  := FFirstNode;
 while (Aux <> nil) do
  begin
   // ask for more data storage
   if (Length(SearchList) <= Index) then ApplySearchList(Index + 1);

   // add element to the array
   SearchList[Index]:= Aux;
   Inc(Index);

   // advance in the array
   Aux:= Aux.Next;
  end;

 SearchCount:= Index;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.SortSearchList(Left, Right: Integer);
var
 Lo, Hi  : Integer;
 TempObj : TGameObject;
 MidValue: Cardinal;
begin
 Lo:= Left;
 Hi:= Right;
 MidValue:= SearchList[(Left + Right) div 2].ID;

 repeat
  while (SearchList[Lo].ID < MidValue) do Inc(Lo);
  while (SearchList[Hi].ID > MidValue) do Dec(Hi);

  if (Lo <= Hi) then
   begin
    TempObj:= SearchList[Lo];
    SearchList[Lo]:= SearchList[Hi];
    SearchList[Hi]:= TempObj;

    Inc(Lo);
    Dec(Hi);
   end;
 until (Lo > Hi);

 if (Left < Hi) then SortSearchList(Left, Hi);
 if (Lo < Right) then SortSearchList(Lo, Right);
end;

//---------------------------------------------------------------------------
procedure TGameObjects.MakeSearchList();
begin
 InitSearchList();
 if (SearchCount > 1) then SortSearchList(0, SearchCount - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TGameObjects.FindByID(ID: Cardinal): TGameObject;
var
 Lo, Hi, Mid: Integer;
begin
 if (SearchDirty) then MakeSearchList();

 Result:= nil;

 Lo:= 0;
 Hi:= SearchCount - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;

   if (SearchList[Mid].ID = ID) then
    begin
     Result:= SearchList[Mid];
     Break;
    end;

   if (SearchList[Mid].ID > ID) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
function TGameObjects.GetCount(): Integer;
begin
 if (SearchDirty) then MakeSearchList();
 Result:= SearchCount;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.Move();
var
 Node, Temp: TGameObject;
begin
 // Move non-disposed nodes.
 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   if (not Node.Disposed) then Node.Move();
   Node:= Node.Next;
  end;

 // Free the disposed nodes.
 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   if (Node.Disposed) then
    begin
     Temp:= Node;
     Node:= Node.Next;

     Temp.Free();
    end else Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.DoMove(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 if (GameState <> gsPlaying)or(GamePaused) then Exit;

 Move();

 if (TurboMode) then
  begin
   Move();
   Move();
   Move();
  end;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.DoDraw(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
var
 Node: TGameObject;
begin
 if (GameState <> gsPlaying) then Exit;

 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   Node.Draw();
   Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameObjects.DoPostDraw(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
var
 Node: TGameObject;
begin
 if (GameState <> gsPlaying) then Exit;

 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   Node.PostDraw();
   Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
initialization
 Objects:= TGameObjects.Create();

//---------------------------------------------------------------------------
finalization
 Objects.Free();
 Objects:= nil;

//---------------------------------------------------------------------------
end.
