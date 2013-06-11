unit HAObjects;
//---------------------------------------------------------------------------
// This unit contains the declaration and implementation of all objects used
// throughout the game.
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
uses
 Types, Classes, SysUtils, Math, Asphyre.Math, Asphyre.Canvas, Asphyre.Images,
 Asphyre.Fonts, Asphyre.Types, AParticles, AObjects;

//---------------------------------------------------------------------------
{$include shipcoords.inc}

//---------------------------------------------------------------------------
type
//---------------------------------------------------------------------------
//                           TStar class
//
// A simple particle which is exactly 1 pixel big which positions itself
// randomly on the screen and then simply fades after some amount of time.
//---------------------------------------------------------------------------
 TStar = class(TParticleEx)
 protected
  // this method is called when the particle is rendered
  procedure ExRender(const Pt: TPoint2px); override;
 public
  constructor Create(AOwner: TParticles); reintroduce;
 end;

//---------------------------------------------------------------------------
//                           TText class
//
// A particle which shows text aligned horizontally for a short period of
// time.
//---------------------------------------------------------------------------
 TText = class(TParticleEx)
 private
  FText: string;
  FFontIndex: Integer;
  FSize: Integer;
 protected
  procedure ExRender(const Pt: TPoint2px); override;
 public
  constructor Create(AOwner: TParticles; Text: string; FontIndex, x, y,
   Size: Integer; Color: Cardinal); reintroduce;
 end;

//---------------------------------------------------------------------------
//                         TSpaceObject class
//
// A helper class which provides movement control for all space objects.
// (if an object leaves the screen, it appears from the opposite direction)
//---------------------------------------------------------------------------
 TSpaceObject = class(TAsphyreObject)
 private
  FAngle: Real;
  FAngleVel: Real;
  FImageIndex: Integer;
  FSize: Integer;
  FPattern: Integer;
  FEffect: TBlendingEffect;
  FDiffuse: Cardinal;

  procedure SetAngle(const Value: Real);
  procedure SetAngleVel(const Value: Real);
  procedure SetSize(const Value: Integer);
 protected
  procedure UpdateAngle(); virtual;
  procedure UpdateSize(); virtual;
 public
  property Angle   : Real read FAngle write SetAngle;
  property AngleVel: Real read FAngleVel write SetAngleVel;

  // image info
  property ImageIndex: Integer read FImageIndex write FImageIndex;
  property Pattern   : Integer read FPattern write FPattern;
  property Size      : Integer read FSize write SetSize;
  property Effect    : TBlendingEffect read FEffect write FEffect;
  property Diffuse   : Cardinal read FDiffuse write FDiffuse;

  procedure Move(); override;
  procedure Render(Tag: TObject); override;

  constructor Create(AOwner: TAsphyreObjects);
 end;

//---------------------------------------------------------------------------
//                           TShip class
//
// A class which implements user-controlled ship.
//---------------------------------------------------------------------------
 TShip = class(TSpaceObject)
 private
  EngineSmoke : Integer;
  WeaponCharge: Integer;
  MaxWeaponCharge: Integer;
  FScore: Integer;
  FWeaponIndex: Integer;
  FLife: Integer;
  FArmour: Integer;

  procedure SetScore(const Value: Integer);
  procedure SetWeaponIndex(const Value: Integer);
  procedure SetLife(const Value: Integer);
 protected
  procedure UpdateAngle(); override;
  procedure CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
   var Accept: Boolean); override;
  procedure ObjectCollide(DestObj: TAsphyreObject); override;
 public
  property Score: Integer read FScore write SetScore;
  property WeaponIndex: Integer read FWeaponIndex write SetWeaponIndex;
  property Life: Integer read FLife write SetLife;
  property Armour: Integer read FArmour write FArmour;

  procedure TurnLeft();
  procedure TurnRight();
  procedure Accelerate();
  procedure Brake();
  function Shoot(): Boolean;

  procedure Move(); override;
  procedure Render(Tag: TObject); override;

  constructor Create(AOwner: TAsphyreObjects);
 end;

//---------------------------------------------------------------------------
//                           TAsteroid class
//
// A class implementing Asteroid behaviour.
//---------------------------------------------------------------------------
 TAsteroid = class(TSpaceObject)
 private
  Anim, AnimDelta: Integer;
  FScore: Integer;

 protected
  procedure CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
   var Accept: Boolean); override;
  procedure UpdateSize(); override;
  procedure ObjectCollide(DestObj: TAsphyreObject); override;
 public
  property Score: Integer read FScore write FScore;

  procedure Move(); override;

  constructor Create(AOwner: TAsphyreObjects);
 end;

//---------------------------------------------------------------------------
//                           TBullet class
//
// A class implementing Asteroid behaviour.
//---------------------------------------------------------------------------
 TBullet = class(TSpaceObject)
 private
  Anim: Integer;
  FRange: Integer;
 protected
  procedure CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
   var Accept: Boolean); override;
  procedure ObjectCollide(DestObj: TAsphyreObject); override;
 public
  property Range: Integer read FRange write FRange;

  procedure Move(); override;

  constructor Create(AOwner: TAsphyreObjects);
 end;

//---------------------------------------------------------------------------
var
 ShipID: Integer = -1; // that ID represents the player's ship Globally
 // although this is not a good way of doing it, but the time and space is
 // limited here ;)

//---------------------------------------------------------------------------
implementation
uses
 MainFm, Dynamic_BASS, HATypes;

//---------------------------------------------------------------------------
const
 StarOrderIndex = $100;
 TextOrderIndex = $200;
 StarColors: array[0..3] of Cardinal = ($FFFFFF, $FF7F00, $3F7FFF, $FFE000);
 ScreenWidth  = 640;
 ScreenHeight = 480;
 AccelFactor  = 0.1;
 ResistFactor = 0.97;
 BrakeFactor  = 0.9;
 WeaponSpeed  = 24;
 BulletSpeed  = 5.0;
 BulletRange  = 56;
 TurnSpeed    = Pi * 4 / 128;

//---------------------------------------------------------------------------
//                            TStar Class
//---------------------------------------------------------------------------
constructor TStar.Create(AOwner: TParticles);
begin
 inherited Create(AOwner, StarOrderIndex);

 // set random position
 IntPos:= Point2px(Random(ScreenWidth), Random(ScreenHeight));

 // one-pixel dimensions
 RenderSize:= Point2px(1, 1);

 // maximum star duration
 MaxRange:= 32 + (32 * Random(8));

 // star color
 Diffuse := StarColors[Random(4)];
end;

//---------------------------------------------------------------------------
procedure TStar.ExRender(const Pt: TPoint2px);
var
 Alpha: Cardinal;
begin
 // 1. fade the pixel when cycle reaches its end
 Alpha:= 255 - ((CurRange * 255) div MaxRange);

 // 2. render the pixel
 GameCanvas.PutPixel(Pt, Diffuse or (Alpha shl 24));
end;

//---------------------------------------------------------------------------
//                            TText Class
//---------------------------------------------------------------------------
constructor TText.Create(AOwner: TParticles; Text: string; FontIndex, x, y,
 Size: Integer; Color: Cardinal);
var
 Font: TAsphyreFont;
begin
 inherited Create(AOwner, TextOrderIndex);

 // assign text attributes
 Diffuse:= Color;
 FText  := Text;
 FSize  := Size;
 FFontIndex:= FontIndex;

 // retreive a specific font
 Font:= GameFonts[FontIndex];

 // determine text dimensions
 if (Font <> nil) then
  begin
   Font.Scale:= FSize / 256.0;
   RenderSize:= Point2px(Font.TexWidth(FText), Font.TexHeight(FText));
  end;

 // centered position
 IntPos:= Point2px(x - (RenderSize.X div 2), y - (RenderSize.Y div 2));

 // rendering effect
 Effect:= beNormal;

 // text duration
 MaxRange:= 128 + (Random(16) * 8);
end;

//---------------------------------------------------------------------------
procedure TText.ExRender(const Pt: TPoint2px);
var
 Alpha, Color: Cardinal;
 Font: TAsphyreFont;
begin
 // 1. fade the text when cycle reaches its end
 Alpha:= 255;
 if (CurRange >= MaxRange div 2) then
  Alpha:= Min((255 - ((CurRange * 255) div MaxRange)) * 2, 255);
 if (CurRange < MaxRange div 4) then
  Alpha:= Min(((CurRange * 255) div MaxRange) * 4, 255);

 // 2. calculate new color
 Color:= (Diffuse and $FFFFFF) or (Alpha shl 24);

 // 3. retreive the required font
 Font:= GameFonts[FFontIndex];

 // 4. render text
 if (Font <> nil) then
  begin
   Font.Scale:= FSize / 256;
   Font.TextOut(Pt, FText, cColor2(Color), 1.0);
  end;
end;

//---------------------------------------------------------------------------
//                        TSpaceObject class
//---------------------------------------------------------------------------
constructor TSpaceObject.Create(AOwner: TAsphyreObjects);
begin
 inherited;

 IntPos     := Point2px(Random(ScreenWidth), Random(ScreenHeight));
 Velocity   := Point2(0.0, 0.0);
 FAngleVel  := 0.0;
 Angle      := Random * Pi * 2;
 FImageIndex:= -1;
 FPattern   := 0;
 FSize      := 256;
 FEffect    := beNormal;
 FDiffuse   := $FFFFFFFF;
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.Move();
var
 iSize, Xpos, Ypos: Real;
 Image: TAsphyreImage;
begin
 Image:= GameImages[ImageIndex];
 if (Image <> nil) then
  begin
   Xpos:= Position.X;
   Ypos:= Position.Y;

   iSize:= Max(Image.VisibleSize.x, Image.VisibleSize.y) * FSize / 256;
   if (Xpos < -(iSize / 2.0)) then Xpos:= Xpos + ScreenWidth + iSize;
   if (Xpos > ScreenWidth + (iSize / 2.0)) then Xpos:= Xpos - ScreenWidth - iSize;
   if (Ypos < -(iSize / 2.0)) then Ypos:= Ypos + ScreenHeight + iSize;
   if (Ypos > ScreenHeight + (iSize / 2.0)) then Ypos:= Ypos - ScreenHeight - iSize;

   Position:= Point2(Xpos, Ypos);
  end;

 inherited Move();
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.SetAngle(const Value: Real);
begin
 FAngle:= Value;
 while (FAngle < 0.0) do FAngle:= FAngle + (2 * Pi);
 while (FAngle > 2 * Pi) do FAngle:= FAngle - (2 * Pi);

 UpdateAngle();
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.SetAngleVel(const Value: Real);
begin
 FAngleVel:= Value;

 UpdateAngle();
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.UpdateAngle();
begin
 // do nothing
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.Render(Tag: TObject);
var
 xSize, ySize, Gamma: Integer;
 Image: TAsphyreImage;
begin
 Image:= GameImages[ImageIndex];
 if (Image = nil) then Exit;

 // 3. calculate image size
 xSize:= (Image.VisibleSize.x * Size) div 256;
 ySize:= (Image.VisibleSize.y * Size) div 256;

 // 4. calculate 256-based angle
 Gamma:= Trunc(Angle * 128 / Pi);

 // 5. render the image
 GameCanvas.UseImagePt(Image, Pattern);
 GameCanvas.TexMap(
  pRotate4(IntPos, Point2(xSize, ySize), Point2(xSize div 2, ySize div 2),
   Gamma),
  cColor4(FDiffuse),
  FEffect);
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.SetSize(const Value: Integer);
begin
 FSize:= Value;
 UpdateSize();
end;

//---------------------------------------------------------------------------
procedure TSpaceObject.UpdateSize();
begin
 // no code
end;

//---------------------------------------------------------------------------
//                        TShip class
//---------------------------------------------------------------------------
constructor TShip.Create(AOwner: TAsphyreObjects);
begin
 inherited;

 IntPos:= Point2px(ScreenWidth div 2, ScreenHeight div 2);
 ImageIndex   := imageShip;
 Angle        := 0;
 EngineSmoke  := 3;
 WeaponCharge := 0;
 CollideRadius:= 24;
 FScore:= 0;
 FWeaponIndex:= 0;
 MaxWeaponCharge:= WeaponSpeed;
 FArmour:= 7;
 FLife:= 3;
end;

//---------------------------------------------------------------------------
procedure TShip.SetScore(const Value: Integer);
begin
 FScore:= Value;
 if (FScore < 0) then FScore:= 0;
end;

//---------------------------------------------------------------------------
procedure TShip.UpdateAngle();
begin
 Pattern:= 16 - Trunc((Angle * 16) / Pi);
 while (Pattern < 0) do Pattern:= Pattern + 32;
 while (Pattern > 31) do Pattern:= Pattern - 32;
end;

//---------------------------------------------------------------------------
procedure TShip.TurnLeft();
begin
 Angle:= Angle - TurnSpeed;
end;

//---------------------------------------------------------------------------
procedure TShip.TurnRight();
begin
 Angle:= Angle + TurnSpeed;
end;

//---------------------------------------------------------------------------
procedure TShip.Accelerate();
var
 Alpha: Real;
 xSmoke, ySmoke: Integer;
begin
 // convert from 32-based angle (stored in Pattern) to radian system
 Alpha:= ((8 - Pattern) * pi) / 16;

 // accelerate
 Velocity:= Point2(Velocity.X + (Cos(Alpha) * AccelFactor), Velocity.Y +
  (Sin(Alpha) * AccelFactor));

 // certain brake - to limit the speed
 Velocity:= Point2(Velocity.X * ResistFactor, Velocity.Y * ResistFactor);

 if (EngineSmoke > 6) then
  begin
   xSmoke:= IntPos.X + ShipCoords[Pattern, 2].X - 32;
   ySmoke:= IntPos.Y + ShipCoords[Pattern, 2].Y - 32;

   PEngine2.CreateParticleEx(imageCombust, xSmoke, ySmoke, 64, beNormal).CurRange:= 4;
   EngineSmoke:= Random(4);
   BASS_SamplePlayEx(MainForm.Sounds[2], 0, -1, 25, -101, False);
  end;
end;

//---------------------------------------------------------------------------
procedure TShip.Brake();
begin
 Velocity:= Point2(Velocity.X * BrakeFactor, Velocity.Y * BrakeFactor);
end;

//---------------------------------------------------------------------------
procedure TShip.Move();
begin
 Inc(EngineSmoke);
 Inc(WeaponCharge);

 inherited Move();
end;

//---------------------------------------------------------------------------
procedure TShip.Render(Tag: TObject);
var
 Left, Top, xSize, ySize: Integer;
 Image: TAsphyreImage;
begin
 // 2. retreive the image
 Image:= GameImages[ImageIndex];
 if (Image = nil) then Exit;

 // 3. calculate image size
 xSize:= (Image.VisibleSize.x * Size) div 256;
 ySize:= (Image.VisibleSize.y * Size) div 256;
 Left:= IntPos.X - (xSize div 2);
 Top := IntPos.Y - (ySize div 2);

 // 4. render the image
 GameCanvas.UseImagePt(Image, Pattern);
 GameCanvas.TexMap(pBounds4(Left, Top, xSize, ySize), clWhite4);
end;

//---------------------------------------------------------------------------
procedure TShip.SetWeaponIndex(const Value: Integer);
begin
 FWeaponIndex:= Value;

 case FWeaponIndex of
  0: MaxWeaponCharge:= Max(WeaponSpeed, 2);
  1: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 0.75), 2);
  2: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 1.25), 2);
  3: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 1.0), 2);
  4: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 0.5), 2);
  5: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 0.7), 2);
  6: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 0.6), 2);
  7: MaxWeaponCharge:= Max(Trunc(WeaponSpeed * 0.5), 2);
 end;
end;

//---------------------------------------------------------------------------
function TShip.Shoot(): Boolean;
const
 Colors: array[0..3] of Cardinal = ($9FFF0000, $9FFF00FF, $9F00FFFF, $9FFFFFFF);
var
 Alpha, Beta, Coef, BetaInc, wRange: Real;
 Obj: TBullet;
 i, j, Max: Integer;
 iColor: Cardinal;
begin
 Result:= False;
 if (WeaponCharge < MaxWeaponCharge) then Exit;
 // convert from 256-based angle to radian system
 Alpha:= ((8 - Pattern) * pi) / 16;
 Beta:= Pi / 32;

 for i:= 0 to 1 do
  case WeaponIndex of
   0:
    begin
     // create bullet
     Obj:= TBullet.Create(Owner);
     Obj.Range:= BulletRange;
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha) * BulletSpeed), Velocity.Y + (Sin(Alpha) *  BulletSpeed));
     Obj.Diffuse:= $9FFF0000;
    end;
   1:
    begin
     // create bullet
     Obj:= TBullet.Create(Owner);
     Obj.Range:= Trunc(BulletRange * 1.2);
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha) * BulletSpeed * 1.1), Velocity.Y + (Sin(Alpha) *  BulletSpeed * 1.1));
     Obj.Diffuse:= $9FFF3F7F;
    end;
   2:
    begin
     // create bullet
     Obj:= TBullet.Create(Owner);
     Obj.Range:= Trunc(BulletRange * 0.75);
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha - Beta) * BulletSpeed * 0.8), Velocity.Y + (Sin(Alpha - Beta) *  BulletSpeed * 0.8));
     Obj.Diffuse:= $9F00FF00;

     Obj:= TBullet.Create(Owner);
     Obj.Range:= Trunc(BulletRange * 0.75);
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha + Beta) * BulletSpeed * 0.8), Velocity.Y + (Sin(Alpha + Beta) *  BulletSpeed * 0.8));
     Obj.Diffuse:= $9F00FF00;
    end;
   3:
    begin
     // create bullet
     Beta:= Pi / 24;

     Coef:= 1.1;
     if (i mod 2 = 0) then Coef:= 0.9;
     iColor:= $9F3FFF7F;
     if (i mod 2 = 0) then iColor:= $9F3F7FFF;
     Obj:= TBullet.Create(Owner);
     Obj.Range:= Trunc(BulletRange * Coef);
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha - Beta) * BulletSpeed * Coef), Velocity.Y + (Sin(Alpha - Beta) *  BulletSpeed * Coef));
     Obj.Diffuse:= iColor;

     Coef:= 0.9;
     if (i mod 2 = 0) then Coef:= 1.1;
     iColor:= $9F3F7FFF;
     if (i mod 2 = 0) then iColor:= $9F3FFF7F;
     Obj:= TBullet.Create(Owner);
     Obj.Range:= Trunc(BulletRange * Coef);
     Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
     Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha + Beta) * BulletSpeed * Coef), Velocity.Y + (Sin(Alpha + Beta) *  BulletSpeed * Coef));
     Obj.Diffuse:= iColor;
    end;
   4, 5, 6, 7:
    begin
     Max:= 4 + (WeaponIndex - 4);
     wRange:= 12 - ((WeaponIndex - 4) * 2);
     Beta:= - Pi / wRange;
     BetaInc:= (Pi / (wRange / 2)) / Max;
     if (WeaponIndex = 4) then
      begin
       if (i = 1) then Break;
       Beta:= Beta - (Pi / 12);
       Max:= Max + 1;
      end;
     for j:= 0 to Max - 1 do
      begin
       Coef:= 1.0 + ((WeaponIndex - 4) * 0.4);
       iColor:= Colors[WeaponIndex - 4];
       Obj:= TBullet.Create(Owner);
       Obj.Range:= Trunc(BulletRange * (1 / Coef));
       Obj.Position:= Point2(Position.X + ShipCoords[Pattern, i].X - 32, Position.Y + ShipCoords[Pattern, i].Y - 32);
       Obj.Velocity:= Point2(Velocity.X + (Cos(Alpha - Beta) * BulletSpeed * Coef), Velocity.Y + (Sin(Alpha - Beta) *  BulletSpeed * Coef));
       Obj.Diffuse:= iColor;
       Beta:= Beta + BetaInc;
      end;
    end;
  end;

 WeaponCharge:= 0;
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TShip.CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
  var Accept: Boolean);
begin
 Accept:= (DestObj is TAsteroid);
end;

//---------------------------------------------------------------------------
procedure TShip.ObjectCollide(DestObj: TAsphyreObject);
begin
 Velocity:= Point2(Velocity.X + DestObj.Velocity.X, Velocity.Y + DestObj.Velocity.Y);
 Brake();
 Dec(FArmour);
 Score:= Score - 5;
{ if (FArmour < 1) then
  begin
   Dec(FLife);
   FArmour:= 7;
  end;} 
end;

//---------------------------------------------------------------------------
procedure TShip.SetLife(const Value: Integer);
begin
 FLife:= Value;
end;

//---------------------------------------------------------------------------
//                        TAsteroid class
//---------------------------------------------------------------------------
constructor TAsteroid.Create(AOwner: TAsphyreObjects);
begin
 inherited;

 ImageIndex:= imageRock;
 Velocity:= Point2((Random * 8) - 4.0, (Random * 8) - 4.0);
 Anim:= 0;
 AnimDelta:= 1;
 if (Random(2) = 0) then AnimDelta:= -1;
 AngleVel:= (Random - 0.5) * Pi / 4;
end;

//---------------------------------------------------------------------------
procedure TAsteroid.UpdateSize();
begin
 CollideRadius:= (48 * FSize) div 256;
end;

//---------------------------------------------------------------------------
procedure TAsteroid.Move();
begin
 Inc(Anim, AnimDelta);
 if (Anim < 0) then Anim:= High(Integer);

 Pattern:= (Anim div 3) mod 32;

 inherited Move();
end;

//---------------------------------------------------------------------------
procedure TAsteroid.CollideCheck(DestObj: TAsphyreObject;
  Distance: Integer; var Accept: Boolean);
begin
 Accept:= (DestObj is TBullet)or(DestObj is TShip);
end;

//---------------------------------------------------------------------------
procedure TAsteroid.ObjectCollide(DestObj: TAsphyreObject);
var
 p: TParticleEx;
 pSize, i, Max: Integer;
 Obj: TAsteroid;
 Pr: TText;
 s: string;
begin
 Dying:= True;

 pSize:= (FSize * 192) div 256;
 p:= PEngine2.CreateParticleEx(imageExplode, IntPos.X, IntPos.Y, 64, beAdd);
 p.RenderSize:= Point2px(pSize, pSize);
 p.RotMiddle := Point2px(pSize div 2, pSize div 2);

 if (FSize > 64)and(FScore > 1) then
  begin
   Max:= 1;
   if (Random(3) = 0) then Inc(Max);
   for i:= 0 to Max do
    begin
     Obj:= TAsteroid.Create(Owner);
     Obj.Size:= (FSize * 2) div 3;
     Obj.Position:= Point2(Position.X, Position.Y);
     Obj.Score:= Score - 1;
    end;
  end;

 s:= IntToStr(FScore) + ' point';
 if (FScore > 1) then s:= s + 's';
 s:= s + '!';
 Pr:= TText.Create(PEngine2, s, 1, IntPos.X, IntPos.Y + 24, 256,
  $FFFFE000);
 Pr.MaxRange:= 48;
 Pr.Velocity:= Point2(Random - 0.5, Random - 1.5);

 TShip(Owner.Objects[ShipID]).Score:= TShip(Owner.Objects[ShipID]).Score + FScore;
 BASS_SamplePlayEx(MainForm.Sounds[1], 0, -1, 50, -101, False);
end;

//---------------------------------------------------------------------------
constructor TBullet.Create(AOwner: TAsphyreObjects);
begin
 inherited;

 ImageIndex:= imageTorpedo;
 Anim:= 0;
 FRange:= 1;
 Effect:= beAdd;
 Diffuse:= $7FFFFFFF;
 CollideRadius:= 16;
end;

//---------------------------------------------------------------------------
procedure TBullet.Move();
var
 Alpha: Cardinal;
begin
 inherited Move();

 Dec(FRange);
 if (FRange < 1) then Dying:= True;

 Inc(Anim);
 Pattern:= Anim mod 32;

 if (FRange < BulletRange div 2) then
  begin
   Alpha:= (FRange * $9F) div (BulletRange div 2);
   Diffuse:= (FDiffuse and $FFFFFF) or (Alpha shl 24);
  end;
end;

//---------------------------------------------------------------------------
procedure TBullet.CollideCheck(DestObj: TAsphyreObject; Distance: Integer;
  var Accept: Boolean);
begin
 Accept:= (DestObj is TAsteroid);
end;

//---------------------------------------------------------------------------
procedure TBullet.ObjectCollide(DestObj: TAsphyreObject);
begin
 Dying:= True;
end;

//---------------------------------------------------------------------------
end.
