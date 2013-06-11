unit AParticles;
//---------------------------------------------------------------------------
// Ashpyre Object engine
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
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
 Types, Classes, SysUtils, Math, Asphyre.Math, AsphyreColors, Asphyre.Types,
 Asphyre.Canvas;

//---------------------------------------------------------------------------
type
 TParticles = class;

//---------------------------------------------------------------------------
 TParticle = class
 private
  FOwner: TParticles;
  FPrev: TParticle;
  FNext: TParticle;
  FOrderIndex: Integer;
  FAccel   : TPoint2;
  FPosition: TPoint2;
  FVelocity: TPoint2;
  FMaxRange: Integer;
  FCurRange: Integer;

  procedure SetNext(const Value: TParticle);
  procedure SetPrev(const Value: TParticle);
  procedure SetOwner(const Value: TParticles);
  procedure SetOrderIndex(const Value: Integer);
  procedure SetAccel(const Value: TPoint2);
  procedure SetPosition(const Value: TPoint2);
  procedure SetVelocity(const Value: TPoint2);
  function GetIntPos(): TPoint2px;
  procedure SetIntPos(const Value: TPoint2px);
  procedure SetCurRange(const Value: Integer);
  procedure SetMaxRange(const Value: Integer);

 protected
  // links previous and next objects leaving this object unconnected
  procedure Unlink();
  // + called AFTER position has been changed
  procedure UpdatedPosition(); virtual;
  // + called AFTER velocity has been changed
  procedure UpdatedVelocity(); virtual;
  // + called AFTER velocity has been changed
  procedure UpdatedAccel(); virtual;
  // + called AFTER any of range variables have been updated
  procedure UpdatedRange(); virtual;
 public
  property Owner: TParticles read FOwner write SetOwner;
  property Prev : TParticle read FPrev write SetPrev;
  property Next : TParticle read FNext write SetNext;
  // all particles are sorted by their order
  // for cached rendering
  property OrderIndex: Integer read FOrderIndex write SetOrderIndex;

  // particle position vector
  property Position: TPoint2 read FPosition write SetPosition;
  property Velocity: TPoint2 read FVelocity write SetVelocity;
  // particle acceleration
  property Accel   : TPoint2 read FAccel write SetAccel;

  // integer position
  property IntPos: TPoint2px read GetIntPos write SetIntPos;

  // current range the particle has travelled
  property CurRange: Integer read FCurRange write SetCurRange;
  // maximum range for the particle
  property MaxRange: Integer read FMaxRange write SetMaxRange;

  // returns False when particle needs to be destroyed
  function Move(): Boolean; virtual;

  procedure Render(Tag: TObject); virtual; abstract;

  constructor Create(AOwner: TParticles; AOrderIndex: Integer); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Simple particle implementation featuring VScreen and animated patterns
//---------------------------------------------------------------------------
 TParticleEx = class(TParticle)
 private
  FEffect    : TBlendingEffect;
  FDiffuse4  : TColor4;
  FImageIndex: Integer;
  FRenderSize: TPoint2px;

  FAngle    : Real;
  FAngleVel : Real;
  FRotMiddle: TPoint2px;

  procedure SetAngle(const Value: Real);
  procedure SetAngleVel(const Value: Real);
  function GetDiffuse(): Cardinal;
  procedure SetDiffuse(const Value: Cardinal);
  procedure SetEffect(const Value: TBlendingEffect);
  procedure SetRenderSize(const Value: TPoint2px);
  procedure SetRotMiddle(const Value: TPoint2px);
  procedure SetImageIndex(const Value: Integer);
  procedure SetDiffuse4(const Value: TColor4);
 protected
  // + called AFTER image index or size has been changed
  procedure UpdatedImage(); virtual;
  // + called AFTER image effect or diffuse color have been changed
  procedure UpdatedEffect(); virtual;
  // + called AFTER particle rotation parameters have been changed or
  // the particle has been rotated
  procedure UpdatedRotation(); virtual;
  // * called to render the particle
  //   "Pt" represents the middle Point2px of the particle on screen
  procedure ExRender(const Pt: TPoint2px); virtual;
 public
  // visible index
  property ImageIndex: Integer read FImageIndex write SetImageIndex;
  // rendering size
  property RenderSize: TPoint2px read FRenderSize write SetRenderSize;
  // rendering info
  property Effect  : TBlendingEffect read FEffect write SetEffect;
  property Diffuse4: TColor4 read FDiffuse4 write SetDiffuse4;
  property Diffuse : Cardinal read GetDiffuse write SetDiffuse;

  // particle rotation info
  property RotMiddle: TPoint2px read FRotMiddle write SetRotMiddle;
  // angle and rotation speed (in radians)
  property Angle    : Real read FAngle write SetAngle;
  property AngleVel : Real read FAngleVel write SetAngleVel;

  function Move(): Boolean; override;
  procedure Render(Tag: TObject); override;

  constructor Create(AOwner: TParticles; AOrderIndex: Integer); override;
 end;

//---------------------------------------------------------------------------
 TParticles = class
 private
  function GetCount(): Integer;
 protected
  ListHead, ListTail: TParticle;

  function Linked(Obj: TParticle): Boolean;
  procedure Insert(Obj: TParticle); virtual;
  procedure UnlinkObj(Obj: TParticle); virtual;
 public
  property Count: Integer read GetCount;

  // removes all particles from list
  procedure Clear();

  // moves and updates all particles
  procedure Update();

  // Renders all particles on the screen ("Tag" is simply passed to individual
  // object).
  // NOTE: Particles that derive TParticleEx can take advantage from Tag, if
  // you pass TVScreen as its value.
  procedure Render(Tag: TObject);

  // adds new TParticleExplosion and returns pointer to it
  function CreateParticleEx(const ImageNum, Xpos, Ypos,
   Cycle: Integer; Effect: TBlendingEffect): TParticleEx; overload;

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Images, HATypes;

//---------------------------------------------------------------------------
constructor TParticle.Create(AOwner: TParticles; AOrderIndex: Integer);
begin
 inherited Create();

 FPrev:= nil;
 FNext:= nil;
 FOrderIndex:= AOrderIndex;
 FOwner:= AOwner;

 FPosition:= Point2(0, 0);
 FVelocity:= Point2(0, 0);
 FAccel   := Point2(0, 0);
 FCurRange:= 0;
 FMaxRange:= 1;

 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
destructor TParticle.Destroy();
begin
 // 1. unlink the particle
 Unlink();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TParticle.SetPrev(const Value: TParticle);
var
 UnPrev: TParticle;
begin
 // 1. determine previous forward link
 UnPrev:= nil;
 if (FPrev <> nil)and(FPrev.Next = Self) then UnPrev:= FPrev;
 // 2. update link
 FPrev:= Value;
 // 3. remove previous forward link
 if (UnPrev <> nil) then UnPrev.Next:= nil;
 // 4. insert forward link
 if (FPrev <> nil)and(FPrev.Next <> Self) then FPrev.Next:= Self;
end;

//---------------------------------------------------------------------------
procedure TParticle.SetNext(const Value: TParticle);
var
 UnNext: TParticle;
begin
 // 1. determine previous backward link
 UnNext:= nil;
 if (FNext <> nil)and(FNext.Prev = Self) then UnNext:= FNext;
 // 2. update link
 FNext:= Value;
 // 3. remove previous backward link
 if (UnNext <> nil) then UnNext.Prev:= nil;
 // 4. insert backward link
 if (FNext <> nil)and(FNext.Prev <> Self) then FNext.Prev:= Self;
end;

//---------------------------------------------------------------------------
procedure TParticle.Unlink();
var
 WasPrev, WasNext: TParticle;
begin
 // 1. unlink the object from its owner
 if (Assigned(FOwner)) then FOwner.UnlinkObj(Self);

 // 2. unlink previous node
 WasPrev:= FPrev;
 WasNext:= FNext;
 FPrev:= nil;
 FNext:= nil;

 if (WasPrev = nil) then
  begin
   if (WasNext <> nil) then WasNext.Prev:= nil;
  end else WasPrev.Next:= WasNext;
end;

//---------------------------------------------------------------------------
procedure TParticle.SetOwner(const Value: TParticles);
begin
 // 1. unlink the node
 Unlink();

 // 2. switch owner
 FOwner:= Value;

 // 3. re-insert the node
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
procedure TParticle.SetOrderIndex(const Value: Integer);
begin
 // 1. unlink the node
 Unlink();
 // 2. update order index
 FOrderIndex:= Value;
 // 3. re-insert the particle
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
procedure TParticle.SetPosition(const Value: TPoint2);
begin
 FPosition:= Value;
 UpdatedPosition();
end;

//---------------------------------------------------------------------------
procedure TParticle.SetVelocity(const Value: TPoint2);
begin
 FVelocity:= Value;
 UpdatedVelocity();
end;

//---------------------------------------------------------------------------
procedure TParticle.SetAccel(const Value: TPoint2);
begin
 FAccel:= Value;
 UpdatedAccel();
end;

//---------------------------------------------------------------------------
function TParticle.GetIntPos(): TPoint2px;
begin
 Result:= Point2px(Trunc(FPosition.X), Trunc(FPosition.Y));
end;

//---------------------------------------------------------------------------
procedure TParticle.SetIntPos(const Value: TPoint2px);
begin
 Position:= Point2(Value.X, Value.Y);
end;

//---------------------------------------------------------------------------
procedure TParticle.SetCurRange(const Value: Integer);
begin
 FCurRange:= Value;
 UpdatedRange();
end;

//---------------------------------------------------------------------------
procedure TParticle.SetMaxRange(const Value: Integer);
begin
 FMaxRange:= Value;
 UpdatedRange();
end;

//---------------------------------------------------------------------------
procedure TParticle.UpdatedPosition();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TParticle.UpdatedVelocity();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TParticle.UpdatedAccel();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TParticle.UpdatedRange();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TParticle.Move(): Boolean;
begin
 // 1. accelerate
 FVelocity.X:= FVelocity.X + FAccel.X;
 FVelocity.Y:= FVelocity.Y + FAccel.Y;
 UpdatedVelocity();

 // 2. move
 FPosition.X:= FPosition.X + FVelocity.X;
 FPosition.Y:= FPosition.Y + FVelocity.Y;
 UpdatedPosition();

 // 3. update particle's range
 Inc(FCurRange);
 UpdatedRange();

 Result:= FCurRange < FMaxRange;
end;

//---------------------------------------------------------------------------
constructor TParticleEx.Create(AOwner: TParticles; AOrderIndex: Integer);
begin
 inherited;

 FDiffuse4  := clWhite4;
 FEffect    := beNormal;
 FImageIndex:= -1;
 FRenderSize:= Point2px(0, 0);
 FRotMiddle := Point2px(0, 0);
 FAngle     := Random * Pi * 2;
 FAngleVel  := 0;
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetAngle(const Value: Real);
begin
 FAngle:= Value;
 UpdatedRotation();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetAngleVel(const Value: Real);
begin
 FAngleVel:= Value;
 UpdatedRotation();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetDiffuse(const Value: Cardinal);
begin
 Diffuse4:= cColor4(Value);
end;

//---------------------------------------------------------------------------
function TParticleEx.GetDiffuse(): Cardinal;
var
 Colors: array[0..3] of TAsphyreColor;
 MidCol: TAsphyreColor;
begin
 Colors[0]:= FDiffuse4[0];
 Colors[1]:= FDiffuse4[1];
 Colors[2]:= FDiffuse4[2];
 Colors[3]:= FDiffuse4[3];
 MidCol:= (Colors[0] + Colors[1] + Colors[2] + Colors[3]) * 0.25;

 Result:= MidCol;
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetEffect(const Value: TBlendingEffect);
begin
 FEffect:= Value;
 UpdatedEffect();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetImageIndex(const Value: Integer);
var
 Image: TAsphyreImage;
begin
 // attempt to retreive image parameters
 if (FImageIndex = -1)and(Value >= 0) then
  begin
   Image:= GameImages[Value];

   if (Image <> nil) then
    begin
     FRenderSize:= Image.VisibleSize;
     FRotMiddle := FRenderSize * 0.5;
    end;
  end;

 FImageIndex:= Value;
 UpdatedImage();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetRenderSize(const Value: TPoint2px);
begin
 FRenderSize:= Value;
 UpdatedImage();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetRotMiddle(const Value: TPoint2px);
begin
 FRotMiddle:= Value;
 UpdatedImage();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.SetDiffuse4(const Value: TColor4);
begin
 FDiffuse4:= Value;
 UpdatedEffect();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.UpdatedImage();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TParticleEx.UpdatedEffect();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TParticleEx.UpdatedRotation();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TParticleEx.Move(): Boolean;
begin
 // 1. update angle
 FAngle:= FAngle + FAngleVel;
 while (FAngle > Pi * 2) do FAngle:= FAngle - (Pi * 2);
 UpdatedRotation();

 // 2. move the particle
 Result:= inherited Move();
end;

//---------------------------------------------------------------------------
procedure TParticleEx.Render(Tag: TObject);
var
 Pt: TPoint2px;
begin
 Pt:= IntPos;

 if (not OverlapRect(Bounds(Pt.X - RotMiddle.X, Pt.Y - RotMiddle.Y,
  RenderSize.X, RenderSize.Y), Bounds(0, 0, DisplaySize.x,
  DisplaySize.y))) then Exit;

 if (not OverlapRect(Bounds(Pt.X - RotMiddle.X, Pt.Y - RotMiddle.Y,
  RenderSize.X, RenderSize.Y), GameCanvas.ClipRect)) then Exit;

 ExRender(Pt);
end;

//---------------------------------------------------------------------------
procedure TParticleEx.ExRender(const Pt: TPoint2px);
var
 Image: TAsphyreImage;
 Pattern, Gamma: Integer;
begin
 Image:= GameImages[ImageIndex];
 if (Image = nil) then Exit;

 Pattern:= 0;
 if (MaxRange > 0) then Pattern:= (CurRange * Image.PatternCount) div MaxRange;
 Gamma:= Trunc(Angle * 128 / Pi);

 GameCanvas.UseImagePt(Image, Pattern);
 GameCanvas.TexMap(pRotate4(Pt, RenderSize, RotMiddle, Gamma), Diffuse4,
  Effect);
end;

//---------------------------------------------------------------------------
constructor TParticles.Create();
begin
 inherited;

 ListHead:= nil;
 ListTail:= nil;
end;

//---------------------------------------------------------------------------
procedure TParticles.Clear();
var
 Aux, Prev: TParticle;
begin
 Aux:= ListTail;
 while (Aux <> nil) do
  begin
   Prev:= Aux.Prev;
   Aux.Free();
   Aux:= Prev;
  end;
end;

//---------------------------------------------------------------------------
function TParticles.GetCount(): Integer;
var
 Aux: TParticle;
begin
 Result:= 0;
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Inc(Result);
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
function TParticles.Linked(Obj: TParticle): Boolean;
var
 Aux0, Aux1: TParticle;
begin
 // 1. validate initial object
 Result:= False;
 if (Obj = nil) then Exit;

 // 2. start from opposite ends
 Aux0:= ListHead;
 Aux1:= ListTail;

 // 3. do bi-directional search
 while (Aux0 <> nil)or(Aux1 <> nil) do
  begin
   // 3 (a). compare the objects
   if (Aux0 = Obj)or(Aux1 = Obj) then
    begin
     Result:= True;
     Exit;
    end;

   // 3 (b). advance in the list
   if (Aux0 <> nil) then Aux0:= Aux0.Next;
   if (Aux1 <> nil) then Aux1:= Aux1.Prev;
  end;
end;

//---------------------------------------------------------------------------
procedure TParticles.Insert(Obj: TParticle);
var
 OIndex: Integer;
 Aux: TParticle;
begin
 // 1. do not accept NULL objects
 if (Obj = nil) then Exit;

 // 2. retreive order index
 OIndex:= Obj.OrderIndex;

 // 3. check if the particle is already linked into the list
 if(Linked(Obj)) then Exit;

 // 4. if no items available - create a first element
 if (ListHead = nil) then
  begin
   Obj.Prev:= nil;
   Obj.Next:= nil;
   ListHead:= Obj;
   ListTail:= ListHead;
   Exit;
  end;

 // 5. insert BEFORE first element
 if (OIndex <= ListHead.OrderIndex) then
  begin
   Obj.Prev:= nil;
   Obj.Next:= ListHead;
   ListHead:= Obj;
   Exit;
  end;

 // 6. insert AFTER first element
 if (OIndex >= ListTail.OrderIndex) then
  begin
   Obj.Next:= nil;
   ListTail.Next:= Obj;
   ListTail:= Obj;
   Exit;
  end;

 // 7. search using either fordward or backward method
 if (Abs(Int64(ListHead.OrderIndex) - OIndex) < Abs(Int64(ListTail.OrderIndex) - OIndex)) then
  begin
   // 7 (a) I. forward search
   Aux:= ListHead;
   while (Aux.Next.OrderIndex < OIndex) do Aux:= Aux.Next;

   // 7 (a) II. update links
   Obj.Next:= Aux.Next;
   Obj.Prev:= Aux;
  end else
  begin
   // 7 (b) I. backward search
   Aux:= ListTail;
   while (Aux.Prev.OrderIndex > OIndex) do Aux:= Aux.Prev;

   // 7 (b) II. update links
   Obj.Prev:= Aux.Prev;
   Obj.Next:= Aux;
  end;
end;

//---------------------------------------------------------------------------
procedure TParticles.UnlinkObj(Obj: TParticle);
begin
 if (ListTail = Obj) then ListTail:= ListTail.Prev;

 if (ListHead = Obj) then
  begin 
   ListHead:= nil;
   if (Obj.Next <> nil) then ListHead:= Obj.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TParticles.Update();
var
 Aux, pNext: TParticle;
 PForward: Boolean;
begin
 // 1. decide random direction for processing
 PForward:= Random(2) = 0;
 Aux:= ListHead;
 if (not PForward) then Aux:= ListTail;

 // 2. update all particles
 while (Aux <> nil) do
  begin
   // 2 (a). determine next particle
   pNext:= Aux.Next;
   if (not PForward) then pNext:= Aux.Prev;

   // 2 (b). move current particle
   if (not Aux.Move()) then Aux.Free();

   // 2 (c). advance in the list
   Aux:= pNext;
  end; // while
end;

//---------------------------------------------------------------------------
function TParticles.CreateParticleEx(const ImageNum, Xpos, Ypos,
 Cycle: Integer; Effect: TBlendingEffect): TParticleEx;
var
 Image: TAsphyreImage;
begin
 Result:= nil;

 Image:= GameImages[ImageNum];
 if (Image = nil) then Exit;

 Result:= TParticleEx.Create(Self, ImageNum);

 Result.IntPos    := Point2px(Xpos, Ypos);
 Result.RenderSize:= Image.VisibleSize;
 Result.Effect    := Effect;
 Result.ImageIndex:= ImageNum;
 Result.Angle     := Random(256);
 Result.MaxRange  := Cycle;
end;

//---------------------------------------------------------------------------
procedure TParticles.Render(Tag: TObject);
var
 Aux: TParticle;
begin
 Aux:= ListHead;

 while (Aux <> nil) do
  begin
   Aux.Render(Tag);
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
end.
