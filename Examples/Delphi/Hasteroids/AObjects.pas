unit AObjects;
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
 Types, Classes, SysUtils, Math, Asphyre.Math, Asphyre.Types, AParticles;

//---------------------------------------------------------------------------
type
 TAsphyreObjects = class;

//---------------------------------------------------------------------------
 TCollideMethod = (cmDistance, cmRectangle);

//---------------------------------------------------------------------------
 TAsphyreObject = class
 private
  FID: Integer;
  FNext: TAsphyreObject;
  FPrev: TAsphyreObject;
  FPosition: TPoint2;
  FVelocity: TPoint2;
  FOwner: TAsphyreObjects;
  FDying: Boolean;
  FCollideRadius: Integer;
  FCollideRect: TRect;
  FCollided: Boolean;

  procedure SetNext(const Value: TAsphyreObject);
  procedure SetPrev(const Value: TAsphyreObject);
  function GetIntPos(): TPoint2px;
  procedure SetIntPos(const Value: TPoint2px);
  procedure SetPosition(const Value: TPoint2);
  procedure SetVelocity(const Value: TPoint2);
  procedure ChangeID(const Value: Integer);
  procedure SetOwner(const Value: TAsphyreObjects);
  procedure SetDying(const Value: Boolean);
 protected
  // links previous and next objects leaving this object unconnected
  procedure Unlink();

  // + called AFTER position has been changed
  procedure UpdatedPosition(); virtual;
  // + called AFTER velocity has been changed
  procedure UpdatedVelocity(); virtual;
  // + called BEFORE the object is to be destroyed
  procedure ObjectDestroy(); virtual;
  // + called BEFORE object's ID is to be changed
  // NOTE: Upon entry to this function, if ACCEPT is "False", then the
  // new ID can be either accepted or denied.
  // However, if the value of "Accept" is "True", then the ID change is
  // indispensable.
  procedure UpdateID(NewID: Integer; var Accept: Boolean); virtual;
  // + called when (before) "Dying" property is changed
  procedure Die(StartDying: Boolean; var Accept: Boolean); virtual;

  // + called to confirm that the object can hit the destination object
  procedure CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
   var Accept: Boolean); virtual;
  // + called AFTER object has confirmed and hit other object
  procedure ObjectCollide(DestObj: TAsphyreObject); virtual;
 public
  // objects's legacy and links
  property ID   : Integer read FID write ChangeID;
  property Owner: TAsphyreObjects read FOwner write SetOwner;
  property Prev : TAsphyreObject read FPrev write SetPrev;
  property Next : TAsphyreObject read FNext write SetNext;

  // determines if the object is to be destroyed or resurrected
  property Dying: Boolean read FDying write SetDying;
  // determines if the object has collided with something
  // (that way it's excluded from current collision check)
  // NOTE: "Move" method changes this back to "False"
  property Collided: Boolean read FCollided write FCollided;

  // object position vector
  property Position: TPoint2 read FPosition write SetPosition;
  property Velocity: TPoint2 read FVelocity write SetVelocity;

  // integer position
  property IntPos: TPoint2px read GetIntPos write SetIntPos;

  // the rectangle object occupies in the space used for collision detection
  // NOTE: only applies if CollisionType is "cmRectangle"
  property CollideRect: TRect read FCollideRect write FCollideRect;

  // the radius from which object can collide with other objects
  // NOTE: only applies if CollisionType is "cmDistance"
  property CollideRadius: Integer read FCollideRadius write FCollideRadius;

  procedure Move(); virtual;
  procedure Render(Tag: TObject); virtual; abstract;

  constructor Create(AOwner: TAsphyreObjects);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreObjects = class
 private
  IDNum         : Integer;
  FCollide      : Boolean;
  FCollideFreq  : Integer;
  FCollideMethod: TCollideMethod;

  function UniqueID(): Integer;
  function GetObject(ID: Integer): TAsphyreObject;
  function GetCount(): Integer;
  procedure SetCollideFreq(const Value: Integer);
  function GetObjectNum(Num: Integer): TAsphyreObject;
 protected
  ListHead,
  ListTail: TAsphyreObject;

  function FindByID(ObjectID: Integer): TAsphyreObject; virtual;
  procedure Insert(Obj: TAsphyreObject); virtual;
  procedure UnlinkObj(Obj: TAsphyreObject); virtual;
  function GenerateID(): Integer; virtual;
  procedure DoCollide(Obj: TAsphyreObject); virtual;
 public
  property Objects[ID: Integer]: TAsphyreObject read GetObject; default;
  property ObjectNum[Num: Integer]: TAsphyreObject read GetObjectNum;
  property Count: Integer read GetCount;

  property Collide: Boolean read FCollide write FCollide;
  property CollideFreq: Integer read FCollideFreq write SetCollideFreq;
  property CollideMethod: TCollideMethod read FCollideMethod write FCollideMethod;

  procedure RemoveAll();

  procedure Remove(ID: Integer); virtual;

  // either moves or destroys dead objects
  procedure Update();

  // renders all objects on the screen ("Tag" is simply passed to individual
  // object)
  procedure Render(Tag: TObject);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreObject.Create(AOwner: TAsphyreObjects);
var
 Accept: Boolean;
begin
 inherited Create();

 FID:= 0;
 FPrev:= nil;
 FNext:= nil;
 FOwner:= AOwner;
 FPosition:= Point2(0, 0);
 FVelocity:= Point2(0, 0);
 FDying:= False;
 FCollideRadius:= 16;
 FCollideRect:= Bounds(0, 0, 16, 16);
 FCollided:= False;

 if (Assigned(FOwner)) then
  begin
   // assign a new ID
   FID:= FOwner.UniqueID();

   // update event
   Accept:= True;
   UpdateID(FID, Accept);

   // insert object
   FOwner.Insert(Self);
  end;
end;

//---------------------------------------------------------------------------
destructor TAsphyreObject.Destroy();
begin
 // 1. unlink the object from the chain
 Unlink();

 // 2. call destroy event
 ObjectDestroy();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.SetPrev(const Value: TAsphyreObject);
var
 UnPrev: TAsphyreObject;
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
procedure TAsphyreObject.SetNext(const Value: TAsphyreObject);
var
 UnNext: TAsphyreObject;
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
procedure TAsphyreObject.Unlink();
var
 WasPrev, WasNext: TAsphyreObject;
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
procedure TAsphyreObject.SetOwner(const Value: TAsphyreObjects);
begin
 // 1. unlink the node
 Unlink();

 // 2. switch owner
 FOwner:= Value;

 // 3. re-insert the node
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.SetPosition(const Value: TPoint2);
begin
 FPosition:= Value;
 UpdatedPosition();
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.SetVelocity(const Value: TPoint2);
begin
 FVelocity:= Value;
 UpdatedVelocity();
end;

//---------------------------------------------------------------------------
function TAsphyreObject.GetIntPos(): TPoint2px;
begin
 Result:= Point(Trunc(FPosition.x), Trunc(FPosition.y));
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.SetIntPos(const Value: TPoint2px);
begin
 Position:= Point2(Value.X, Value.Y);
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.SetDying(const Value: Boolean);
var
 Accept: Boolean;
begin
 // 1. call event
 Accept:= True;
 Die(Value, Accept);

 // 2. change status
 if (Accept) then FDying:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.UpdatedPosition();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.UpdatedVelocity();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.ObjectDestroy();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.CollideCheck(DestObj: TAsphyreObject;
 Distance: Integer; var Accept: Boolean);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.ObjectCollide(DestObj: TAsphyreObject);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.Die(StartDying: Boolean; var Accept: Boolean);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.UpdateID(NewID: Integer; var Accept: Boolean);
begin
 Accept:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.ChangeID(const Value: Integer);
var
 Accept: Boolean;
begin
 // 1. call Update event
 Accept:= False;
 UpdateID(Value, Accept);

 // 2. proceed only if accepted
 if (Accept) then
  begin
   // 1. unlink the node
   Unlink();
   // 2. update ID
   FID:= Value;
   // 3. re-insert the node
   if (Assigned(FOwner)) then FOwner.Insert(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObject.Move();
begin
 FPosition.X:= FPosition.X + FVelocity.X;
 FPosition.Y:= FPosition.Y + FVelocity.Y;
 UpdatedPosition();
 
 FCollided:= False;
end;

//---------------------------------------------------------------------------
//
//                           TAsphyreObjects
//
//---------------------------------------------------------------------------
constructor TAsphyreObjects.Create();
begin
 inherited;

 IDNum:= High(Integer);

 FCollide    := False;
 FCollideFreq:= 4;
 FCollideMethod:= cmDistance;
end;

//---------------------------------------------------------------------------
destructor TAsphyreObjects.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreObjects.GenerateID(): Integer;
begin
 Result:= IDNum;
 Dec(IDNum);
end;

//---------------------------------------------------------------------------
function TAsphyreObjects.UniqueID(): Integer;
const
 FailTolerance = High(Integer);
var
 Tolerance, NewID: Integer;
begin
 Tolerance:= FailTolerance;
 NewID:= GenerateID();
 while (FindByID(NewID) <> nil)and(Tolerance > 0) do
  begin
   NewID:= GenerateID();
   Dec(Tolerance);
  end;

 Result:= NewID;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.Insert(Obj: TAsphyreObject);
var
 ObjectID: Integer;
 Aux: TAsphyreObject;
begin
 // 1. do not accept NULL objects
 if (Obj = nil) then Exit;

 // 2. retreive object ID
 ObjectID:= Obj.ID;

 // 3. check if the object already exists
 if(FindByID(ObjectID) = Obj) then Exit;

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
 if (ObjectID < ListHead.ID) then
  begin
   Obj.Prev:= nil;
   Obj.Next:= ListHead;
   ListHead:= Obj;
   Exit;
  end;

 // 6. insert AFTER first element
 if (ObjectID > ListTail.ID) then
  begin
   Obj.Next:= nil;
   ListTail.Next:= Obj;
   ListTail:= Obj;
   Exit;
  end;

 // 7. search using either fordward or backward method
 if (Abs(Int64(ListHead.ID) - ObjectID) < Abs(Int64(ListTail.ID) - ObjectID)) then
  begin
   // 7 (a) I. forward search
   Aux:= ListHead;
   while (Aux.Next.ID < ObjectID) do Aux:= Aux.Next;

   // 7 (a) II. update links
   Obj.Next:= Aux.Next;
   Obj.Prev:= Aux;
  end else
  begin
   // 7 (b) I. backward search
   Aux:= ListTail;
   while (Aux.Prev.ID > ObjectID) do Aux:= Aux.Prev;

   // 7 (b) II. update links
   Obj.Prev:= Aux.Prev;
   Obj.Next:= Aux;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreObjects.FindByID(ObjectID: Integer): TAsphyreObject;
var
 Aux: TAsphyreObject;
begin
 // 1. no objects exist
 if (ListHead = nil) then
  begin
   Result:= nil;
   Exit;
  end;

 // 2. do either forward or backward search
 if (Abs(Int64(ListHead.ID) - ObjectID) < Abs(Int64(ListTail.ID) - ObjectID)) then
  begin
   // 2 (a). forward search
   Aux:= ListHead;
   while (Aux <> nil)and(Aux.ID <> ObjectID) do Aux:= Aux.Next;
  end else
  begin
   // 2 (a). backward search
   Aux:= ListTail;
   while (Aux <> nil)and(Aux.ID <> ObjectID) do Aux:= Aux.Prev;
  end;
 Result:= Aux
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.UnlinkObj(Obj: TAsphyreObject);
begin
 if (ListTail = Obj) then ListTail:= ListTail.Prev;

 if (ListHead = Obj) then
  begin 
   ListHead:= nil;
   if (Obj.Next <> nil) then ListHead:= Obj.Next;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreObjects.GetObject(ID: Integer): TAsphyreObject;
begin
 Result:= FindByID(ID);
end;

//---------------------------------------------------------------------------
function TAsphyreObjects.GetCount(): Integer;
var
 Aux: TAsphyreObject;
begin
 Result:= 0;
 Aux:= ListHead;

 while (Aux <> nil) do
  begin
   Aux:= Aux.Next;
   Inc(Result);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.Remove(ID: Integer);
var
 Aux: TAsphyreObject;
begin
 // 1. find object
 Aux:= FindByID(ID);

 // 2. release object (it should unlink itself)
 if (Aux <> nil) then Aux.Free();
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.Update();
var
 Aux, Temp: TAsphyreObject;
 Died: Boolean;
begin
 // 1. move all objects
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Aux.Move();
   Aux:= Aux.Next;
  end;

 // 2. collide objects
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   if (not Aux.Dying)and(not Aux.Collided) then DoCollide(Aux);
   Aux:= Aux.Next;
  end;

 // 3. destroy "dead" objects
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Died:= False;
   // 3 (a). check if object dies
   if (Aux.Dying) then
    begin
     Temp:= Aux;
     Aux:= Aux.Next;
     Temp.Free();
     Died:= True;
    end;

   // 3 (b). move the object
   if (not Died) then Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.SetCollideFreq(const Value: Integer);
begin
 FCollideFreq:= Max(Value, 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.DoCollide(Obj: TAsphyreObject);
var
 Aux: TAsphyreObject;
 Delta: Real;
 TooClose: Boolean;
 Accept1, Accept2: Boolean;
begin
 Aux:= Obj.Next;
 while (Aux <> nil) do
  begin
   if (not Aux.Dying)and(not Aux.Collided) then
    begin
     Delta:= Sqrt(Sqr(Obj.Position.X - Aux.Position.X) + Sqr(Obj.Position.Y - Aux.Position.Y));
     if (FCollideMethod = cmDistance) then
      begin
       TooClose:= (Delta < (Obj.CollideRadius + Aux.CollideRadius));
      end else
      begin
       TooClose:= OverlapRect(Obj.CollideRect, Aux.CollideRect);
      end;
     if (TooClose) then
      begin
       Accept1:= True;
       Accept2:= True;
       Obj.CollideCheck(Aux, Trunc(Delta), Accept1);
       Aux.CollideCheck(Obj, Trunc(Delta), Accept2);

       // only collide objects if both agree
       if (Accept1)and(Accept2) then
        begin
         // 1. assume both objects have collided
         Obj.Collided:= True;
         Aux.Collided:= True;
         // 2. call the apropriate events
         Obj.ObjectCollide(Aux);
         Aux.ObjectCollide(Obj);
         // 3. stop collision check for this object, if it's marked "Collided"
         // NOTE: "ObjectCollide" event can change "Collided" variable to
         // prevent this.
         if (Obj.Collided) then Break;
        end;
      end;
    end; // if not Aux.Dying

   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.Render(Tag: TObject);
var
 Aux: TAsphyreObject;
begin
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   if (not Aux.Dying) then Aux.Render(Tag);
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreObjects.RemoveAll();
var
 Aux, Prev: TAsphyreObject;
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
function TAsphyreObjects.GetObjectNum(Num: Integer): TAsphyreObject;
var
 Aux  : TAsphyreObject;
 Index: Integer;
begin
 Result:= nil;
 Aux  := ListHead;
 Index:= 0;

 while (Index < Num) do
  begin
   Aux:= Aux.Next;
   Inc(Index);
  end;

 if (Index = Num) then Result:= Aux;
end;

//---------------------------------------------------------------------------
end.
