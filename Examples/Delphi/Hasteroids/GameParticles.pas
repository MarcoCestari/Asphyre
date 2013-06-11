unit GameParticles;
//---------------------------------------------------------------------------
// GameParticles.pas
//---------------------------------------------------------------------------
//
// This unit describes abstract game particles that move in 3D space and each
// one is rendered separately.
//
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Vectors3, Matrices4, AsphyreUtils, GameMath, GameEvents, GameEventPriorities;

//---------------------------------------------------------------------------
type
 TGameParticles = class;

//---------------------------------------------------------------------------
 TGameParticle = class
 private
  FNext : TGameParticle;
  FPrev : TGameParticle;
  FOwner: TGameParticles;

  FCurLife  : Integer;
  FMaxLife  : Integer;
  FSomeTicks: Integer;

  FCurWait: Integer;
  FMaxWait: Integer;

  NoExclude: Boolean;
 protected
  procedure Setup(); virtual;
  procedure DoMove(); virtual; abstract;
  procedure DoDraw(Alpha: Single); virtual; abstract;
 public
  property Prev : TGameParticle read FPrev write FPrev;
  property Next : TGameParticle read FNext write FNext;
  property Owner: TGameParticles read FOwner;

  property CurLife: Integer read FCurLife write FCurLife;
  property MaxLife: Integer read FMaxLife write FMaxLife;

  property CurWait: Integer read FCurWait write FCurWait;
  property MaxWait: Integer read FMaxWait write FMaxWait;

  // Localized version of GameTicks (starts off some random number)
  property SomeTicks: Integer read FSomeTicks;

  procedure Move(); virtual;
  procedure Draw(); virtual;

  constructor Create(AOwner: TGameParticles);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TVisualParticle = class(TGameParticle)
 private
  FColor   : Cardinal;
  FImagePhi: Single;
 public
  property Color: Cardinal read FColor write FColor;
  property ImagePhi: Single read FImagePhi write FImagePhi;

  constructor Create(AOwner: TGameParticles);
 end;

//---------------------------------------------------------------------------
 TDirectedParticle = class(TVisualParticle)
 private
 protected
  FPosition: TVector3;
  FVelocity: TVector3;

  procedure DoMove(); override;
 public
  property Position: TVector3 read FPosition write FPosition;
  property Velocity: TVector3 read FVelocity write FVelocity;

  constructor Create(AOwner: TGameParticles);
 end;

//---------------------------------------------------------------------------
 TRadialParticle = class(TVisualParticle)
 private
  FOrigin: TVector3;
  FRadius: Single;
  FRadial: TVector3;
  FAngle : Single;
  FSpeed : Single;
  FCurPos: TVector3;

  HaveMoved: Boolean;

  procedure UpdateCurPos();
 protected
  procedure DoMove(); override;
 public
  property Origin: TVector3 read FOrigin write FOrigin;
  property Radius: Single read FRadius write FRadius;
  property Radial: TVector3 read FRadial write FRadial;
  property Angle : Single read FAngle write FAngle;
  property Speed : Single read FSpeed write FSpeed;
  property CurPos: TVector3 read FCurPos;

  procedure Draw(); override;

  constructor Create(AOwner: TGameParticles);
 end;

//---------------------------------------------------------------------------
 TTornadoParticle = class(TVisualParticle)
 private
  FCurPos   : TVector3;
  FRadius   : Single;
  FRadiusVel: Single;
  FAngle    : Single;
  FAngleVel : Single;
  FAltitude : Single;
  FAltVel   : Single;
  HaveMoved : Boolean;

  procedure UpdateCurPos();
 protected
  FOrigin: TVector3;

  procedure DoMove(); override;
 public
  property CurPos   : TVector3 read FCurPos;
  property Origin   : TVector3 read FOrigin write FOrigin;
  property Radius   : Single read FRadius write FRadius;
  property RadiusVel: Single read FRadiusVel write FRadiusVel;

  property Angle    : Single read FAngle write FAngle;
  property AngleVel : Single read FAngleVel write FAngleVel;

  property Altitude : Single read FAltitude write FAltitude;
  property AltVel   : Single read FAltVel write FAltVel;

  procedure Draw(); override;

  constructor Create(AOwner: TGameParticles);
 end;

//---------------------------------------------------------------------------
 TGameParticles = class
 private
  FFirstNode: TGameParticle;
  FLastNode : TGameParticle;

  MoveHandle : Cardinal;
  DrawHandle : Cardinal;
  ResetHandle: Cardinal;

  procedure Include(NewNode: TGameParticle); virtual;
  procedure Exclude(Node: TGameParticle); virtual;
  function GetCount(): Integer;

  procedure DoGameReset(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
  procedure DoMove(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
  procedure DoDraw(const Sender: TObject; const Param: Pointer; var Handled: Boolean);
 public
  property FirstNode: TGameParticle read FFirstNode;
  property LastNode : TGameParticle read FLastNode;

  property Count: Integer read GetCount;

  procedure RemoveAll();

  procedure Draw();
  procedure Move();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 Particles: TGameParticles = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 GameTypes;

//---------------------------------------------------------------------------
constructor TGameParticle.Create(AOwner: TGameParticles);
begin
 inherited Create();

 FOwner:= AOwner;
 NoExclude:= False;

 FCurLife:= 0;
 FMaxLife:= 0;

 FCurWait:= 0;
 FMaxWait:= 0;

 FSomeTicks:= Random(65536);

 if (FOwner <> nil) then FOwner.Include(Self);
end;

//---------------------------------------------------------------------------
destructor TGameParticle.Destroy();
begin
 if (not NoExclude)and(FOwner <> nil) then FOwner.Exclude(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGameParticle.Move();
begin
 FCurWait:= Min2(FMaxWait, FCurWait + 1);

 if (FCurWait >= FMaxWait) then
  begin
   DoMove();

   FCurLife:= Min2(FMaxLife, FCurLife + 1);
   Inc(FSomeTicks);
  end;
end;

//---------------------------------------------------------------------------
procedure TGameParticle.Setup();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGameParticle.Draw();
begin
 if (FCurWait >= FMaxWait) then
  DoDraw(1.0 - (FCurLife / FMaxLife));
end;

//---------------------------------------------------------------------------
constructor TVisualParticle.Create(AOwner: TGameParticles);
begin
 FImagePhi:= 2.0 * Random();
 FColor   := $FFFFFFFF;

 inherited;
end;

//---------------------------------------------------------------------------
constructor TDirectedParticle.Create(AOwner: TGameParticles);
begin
 inherited;

 FVelocity:= ZeroVec3;

 Setup();
end;

//---------------------------------------------------------------------------
procedure TDirectedParticle.DoMove();
begin
 if (FPosition.y < 0.0)and(FVelocity.y < 0.0) then
  FVelocity.y:= -FVelocity.y;

 FPosition:= FPosition + FVelocity;
end;

//---------------------------------------------------------------------------
constructor TRadialParticle.Create(AOwner: TGameParticles);
begin
 inherited;

 FRadial:= RandConstVec3(2.0 * Pi);
 FAngle := 0.0;

 HaveMoved:= False;

 Setup();
end;

//---------------------------------------------------------------------------
procedure TRadialParticle.UpdateCurPos();
begin
 FCurPos:= FOrigin + Vector3(FRadius, 0.0, 0.0) *
  RotateYMtx4(FAngle) * HeadingPitchBankMtx4(FRadial);
end;

//---------------------------------------------------------------------------
procedure TRadialParticle.DoMove();
begin
 FAngle:= FAngle + FSpeed;

 UpdateCurPos();
 HaveMoved:= True;
end;

//---------------------------------------------------------------------------
procedure TRadialParticle.Draw();
begin
 if (not HaveMoved) then UpdateCurPos();

 inherited;
end;

//---------------------------------------------------------------------------
constructor TTornadoParticle.Create(AOwner: TGameParticles);
begin
 inherited;

 HaveMoved:= False;

 FRadius   := 0.0;
 FRadiusVel:= 0.0;
 FAngle    := 2.0 * Pi * Random();
 FAngleVel := 0.0;
 FAltitude := 0.0;
 FAltVel   := 0.0;

 Setup();
end;

//---------------------------------------------------------------------------
procedure TTornadoParticle.UpdateCurPos();
begin
 FCurPos.x:= FOrigin.x + Cos(FAngle) * FRadius;
 FCurPos.y:= FOrigin.y + FAltitude;
 FCurPos.z:= FOrigin.z + Sin(FAngle) * FRadius;
end;

//---------------------------------------------------------------------------
procedure TTornadoParticle.DoMove();
begin
 FRadius  := FRadius + FRadiusVel;
 FAngle   := FAngle + FAngleVel;
 FAltitude:= FAltitude + FAltVel;

 UpdateCurPos();
 HaveMoved:= True;
end;

//---------------------------------------------------------------------------
procedure TTornadoParticle.Draw();
begin
 if (not HaveMoved) then UpdateCurPos();

 inherited;
end;

//---------------------------------------------------------------------------
constructor TGameParticles.Create();
begin
 inherited;

 FFirstNode:= nil;
 FLastNode := nil;

 ResetHandle:= EventGameReset.Subscribe(DoGameReset, -1);
 MoveHandle := EventSceneMove.Subscribe(DoMove, PriorityMoveParticles);
 DrawHandle := EventSceneDraw.Subscribe(DoDraw, PrioritySceneDrawParticles);
end;

//---------------------------------------------------------------------------
destructor TGameParticles.Destroy();
begin
 RemoveAll();

 EventSceneDraw.Unsubscribe(DrawHandle);
 EventSceneMove.Unsubscribe(MoveHandle);
 EventGameReset.Unsubscribe(ResetHandle);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGameParticles.DoGameReset(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 RemoveAll();
end;

//---------------------------------------------------------------------------
procedure TGameParticles.RemoveAll();
var
 Node, Temp: TGameParticle;
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
procedure TGameParticles.Include(NewNode: TGameParticle);
begin
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
procedure TGameParticles.Exclude(Node: TGameParticle);
begin
 if (Node.Prev = nil) then FFirstNode:= Node.Next
  else Node.Prev.Next:= Node.Next;

 if (Node.Next = nil) then FLastNode:= Node.Prev
  else Node.Next.Prev:= Node.Prev;
end;

//---------------------------------------------------------------------------
function TGameParticles.GetCount(): Integer;
var
 Node: TGameParticle;
begin
 Node:= FFirstNode;
 Result:= 0;

 while (Node <> nil) do
  begin
   Inc(Result);
   Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameParticles.Move();
var
 Node, Temp: TGameParticle;
begin
 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   if (Node.CurLife < Node.MaxLife) then Node.Move();

   if (Node.CurLife >= Node.MaxLife) then
    begin
     Temp:= Node;
     Node:= Node.Next;

     Temp.Free();
    end else Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameParticles.DoMove(const Sender: TObject; const Param: Pointer;
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
procedure TGameParticles.Draw();
var
 Node: TGameParticle;
begin
 Node:= FFirstNode;
 while (Node <> nil) do
  begin
   Node.Draw();
   Node:= Node.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TGameParticles.DoDraw(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 if (GameState <> gsPlaying) then Exit;

 Draw();
end;

//---------------------------------------------------------------------------
initialization
 Particles:= TGameParticles.Create();

//---------------------------------------------------------------------------
finalization
 Particles.Free();
 Particles:= nil;

//---------------------------------------------------------------------------
end.

