unit MainFm;
//---------------------------------------------------------------------------
// Hasteroids v1.1.4
//
// This is a port of Hasteroids that was originally published for very early
// versions of Asphyre first made by Humberto Andrade aka "Hab".
//
// Unfortunately, I had no time to rewrite the code for better readability,
// it was merely ported to use Asphyre Sphinx.
//
// This example works correctly with Delphi XE 2, but only on 32-bit platform.
// The lack of 64-bit support is due to BASS sound library, which is used in
// this example and it is only compiled for 32 bits.
//
// If you spot any bugs or mistakes made upon conversion, please let me know
// or better, put the fix on Asphyre forums. :)
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
uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,  Dialogs, Math,
  Dynamic_bass, HAScores, WinKeyb;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PowerDraw1InitDevice(Sender: TObject; var ExitCode: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    CSAnim, CSAnimInc: Integer;
    Ticks: Integer;
    Level: Integer;
    LevelDelay: Integer;
    GameOver,
    Initial: Boolean;
    MusicModule: HMusic;
    PlayerName: string;
    BassInitiated: Boolean;
    HighScores: THighScores;

    procedure LoadBassDLL();
    procedure InitBass();
    procedure DoneBass();
    procedure LoadSounds();
    procedure ShowInitial();
    procedure ShowTitle(Text: string; y, Size: Integer; Color: Cardinal);
    procedure ControlShip();
    procedure NextLevel();
    function AsteroidCount(): Integer;
    procedure RemoveBullets();
    procedure RemoveAsteroids();
    procedure ScorePlayer();
    procedure ShowHighScores();

    procedure OnDeviceCreate(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure TimerEvent(Sender: TObject);
    procedure ProcessEvent(Sender: TObject);
    procedure RenderEvent(Sender: TObject);
  public
    { Public declarations }
    Sounds: array[0..3] of HSample;
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
uses
 Asphyre.Math, Asphyre.Providers, Asphyre.Devices, Asphyre.Images, Asphyre.Fonts,
 Asphyre.Archives, Asphyre.FormTimers, HATypes, AParticles, AObjects, HAObjects,
 StartFm, Asphyre.Types, Asphyre.Events, DX7Providers, Asphyre.Providers.DX9,
 DX10Providers, Asphyre.Providers.DX11, WGLProviders;
{$R *.dfm}

//---------------------------------------------------------------------------
const
 StartDelay    =  60;
 InitialPhase1 = 330;
 InitialPhase2 = 330;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Enable Delphi 2006+ debugger.
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Specify initial variables
 BassInitiated:= False;
 HighScores   := nil;

 PEngine1:= TParticles.Create();
 OEngine1:= TAsphyreObjects.Create();

 OEngine1.Collide      := True;
 OEngine1.CollideFreq  := 4;
 OEngine1.CollideMethod:= cmDistance;

 PEngine2:= TParticles.Create();

 // Show Asphyre configuration dialog
 StartForm:= TStartForm.Create(Self);
 if (StartForm.ShowModal() <> mrOk) then
  begin
   StartForm.Free();
   Application.Terminate();
   Exit;
  end;

 DisplaySize:= Point2px(ClientWidth, ClientHeight);

 // Tell which version of DirectX provider to use.
 case StartForm.DXComboBox.ItemIndex of
  1: Factory.UseProvider(idDirectX9);
  2: Factory.UseProvider(idDirectX10);
  3: Factory.UseProvider(idDirectX11);
  4: Factory.UseProvider(idWinOpenGL);

  else Factory.UseProvider(idDirectX7);
 end;

 // Create Asphyre components in run-time.
 GameDevice:= Factory.CreateDevice();
 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 Archive:= TAsphyreArchive.Create();
 Archive.OpenMode:= aomReadOnly;
 Archive.FileName:= ExtractFilePath(ParamStr(0)) + 'media.asvf';

 // Specify Asphyre device configuration.
 GameDevice.SwapChains.Add(Self.Handle, DisplaySize);

 PlayerName:= StartForm.PlayerName;

 // Subscribe to device creation event.
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);

 Randomize();

 // Init sound engine.
 InitBass();

 // Attempt to initialize Asphyre device.
 if (not GameDevice.Initialize()) then
  begin
   ShowMessage('Failed to initialize Asphyre device.');
   Halt;
   Exit;
  end;

 // Load high-scores.
 HighScores:= THighScores.Create();
 HighScores.LoadFromVTDb('highscores.data', Archive);

 // Create rendering timer.
 Timer.OnTimer  := TimerEvent;
 Timer.OnProcess:= ProcessEvent;
 Timer.Speed    := 60.0;
 Timer.MaxFPS   := 4000;
 Timer.Enabled  := True;

 // step 8. create the ship
 ShipID:= TShip.Create(OEngine1).ID;

 Level    := 0;
 Ticks    := 0;
 CSAnim   := 0;
 CSAnimInc:= 1;
 Initial  := True;

 NextLevel();

 GameOver:= True;

 LevelDelay:= InitialPhase1 + InitialPhase2 + StartDelay;
 BASS_MusicPlay(MusicModule);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 if (Assigned(HighScores)) then
  begin
   HighScores.SaveToVTDb('highscores.data', Archive);
   FreeAndNil(HighScores);
  end;

 Timer.Enabled:= False;
 PEngine2.Clear();
 PEngine1.Clear();
 OEngine1.RemoveAll();

 FreeAndNil(PEngine2);
 FreeAndNil(OEngine1);
 FreeAndNil(PEngine1);

 // Release all Asphyre components.
 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(Archive);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);

 if (BassInitiated) then DoneBass();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 imageBackground:= GameImages.AddFromArchive('/stars.image', Archive);
 imageBandLogo  := GameImages.AddFromArchive('/cshine.image', Archive);
 imageLogo      := GameImages.AddFromArchive('/logo.image', Archive);
 imageCShineLogo:= GameImages.AddFromArchive('/cslogo.image', Archive);
 imageShipArmor := GameImages.AddFromArchive('/life.image', Archive);
 imageShip      := GameImages.AddFromArchive('/ship.image', Archive);
 imageRock      := GameImages.AddFromArchive('/rock.image', Archive);
 imageTorpedo   := GameImages.AddFromArchive('/torpedo.image', Archive);
 imageExplode   := GameImages.AddFromArchive('/explode.image', Archive);
 imageCombust   := GameImages.AddFromArchive('/combust.image', Archive);

 GameImages.AddFromArchive('/ArialBlack.image', Archive);
 GameImages.AddFromArchive('/TimesNewRoman.image', Archive);
 GameImages.AddFromArchive('/Impact.image', Archive);

 fontArialBlack:= GameFonts.Insert('/media.asvf | /ArialBlack.xml', 'ArialBlack.image');
 fontTimesRoman:= GameFonts.Insert('/media.asvf | /TimesNewRoman.xml', 'TimesNewRoman.image');
 fontImpact    := GameFonts.Insert('/media.asvf | /Impact.xml', 'Impact.image');
end;

//---------------------------------------------------------------------------
procedure TMainForm.PowerDraw1InitDevice(Sender: TObject;
 var ExitCode: Integer);
begin
 BASS_MusicPlay(MusicModule);
end;

//---------------------------------------------------------------------------
procedure TMainForm.TimerEvent(Sender: TObject);
begin
 Caption:= 'Hasteroids. FPS: ' + IntToStr(Timer.FrameRate) + ', Tech: ' +
  GetFullDeviceTechString(GameDevice);

 GameDevice.Render(RenderEvent, 0);
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
var
 i, j, Index, TextSize: Integer;
 Text: ShortString;
begin
 // render background
 if (not GameOver) then
  begin
   Index:= 0;
   for j:= 0 to 1 do
    for i:= 0 to 3 do
     begin
      GameCanvas.UseImagePt(GameImages[imageBackground], Index);
      GameCanvas.TexMap(pBounds4((i * 160.0), (j * 240.0), 160.0, 240.0),
       clWhite4);

      Inc(Index);
     end;
  end;

 // render particles beneath objects
 PEngine1.Render(nil);

 if (not GameOver) then
  begin
   // render all game objects
   OEngine1.Render(nil);

   // render particles over objects
   PEngine2.Render(nil);

   // show player's armour
   for i:= 0 to TShip(OEngine1[ShipID]).Armour - 1 do
    begin
     GameCanvas.UseImage(GameImages[imageShipArmor], TexFull4);
     GameCanvas.TexMap(pBounds4(640.0 - 32.0 - (i * 32.0), 4.0, 32.0, 32.0),
      clWhite4);
    end;

   // show player's life
   for i:= 0 to TShip(OEngine1[ShipID]).Life - 1 do
    begin
     GameCanvas.UseImagePt(GameImages[imageShip], 2);
     GameCanvas.TexMap(pBounds4((i * 32) + 8, 4, 32, 32),
      clWhite4);
    end;
  end;

 if (not Initial) then
  begin
   GameCanvas.UseImagePt(GameImages[imageCShineLogo], CSAnim);
   GameCanvas.TexMap(pBounds4(4.0, 480.0 - 32.0, 128.0, 32.0),
    clWhite4);
  end;

 if (not GameOver) then
  begin
   Text:= 'Score: ' + IntToStr(TShip(OEngine1[ShipID]).Score);
   TextSize:= Round(GameFonts[fontArialBlack].TextWidth(Text));

   GameFonts[fontArialBlack].TextOut(
    Point2(632.0 - TextSize, 460.0),
    Text,
    cColor2($FFDFFF67, $FF5C966F), 1.0);
  end;

 if (GameOver)and(not Initial) then
  begin
   for i:= 0 to 3 do
    begin
     GameCanvas.UseImagePt(GameImages[imageLogo], i);
     GameCanvas.TexMap(pBounds4((i * 160.0), 0.0, 160.0, 240.0),
      clWhite4);
    end;

   GameCanvas.Line(
    Point2(0.0, 224.0),
    Point2(640.0, 224.0),
    $1F1F1F, $5F5F5F);

   ShowHighScores();
  end;

 if (Initial) then ShowInitial();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 ControlShip();

 // 1. create a new star
 TStar.Create(PEngine1);

{ for i:= 0 to 15 do
  PEngine1.CreateParticleEx(Random(6), Random(640), Random(480), 32, effectAdd or effectSrcAlpha);}

 PEngine1.Update();
 PEngine2.Update();
 if (LevelDelay <= 0) then
  begin
   OEngine1.Update();
   if (GameOver) then
    begin
     // re-create ship
     OEngine1.Remove(ShipID);
     ShipID:= TShip.Create(OEngine1).ID;

     RemoveAsteroids();
     Level:= 0;

     if (Random(5) = 0)and(not Initial) then
      begin
       TText.Create(PEngine2, 'Try this one!!!', 2, 320, 280, 256, $FFFF0000).Velocity:= Point2(0.0, 0.5);
       TShip(OEngine1[ShipID]).Armour:= 15;
       TShip(OEngine1[ShipID]).Life:= 1;
       Level:= 6;
      end;

     NextLevel();
     GameOver:= False;
     Initial:= False;
    end;
  end else Dec(LevelDelay);

 if (AsteroidCount() < 1) then
  begin
   RemoveAsteroids();
   NextLevel();
   if (TShip(OEngine1[ShipID]).Armour < 10) then
    begin
     TShip(OEngine1[ShipID]).Armour:= TShip(OEngine1[ShipID]).Armour + 1;
     ShowTitle('1 health bonus!', 300, 256, $FF7F3F);
    end else
    begin
     if (TShip(OEngine1[ShipID]).Life < 5) then
      begin
       TShip(OEngine1[ShipID]).Life:= TShip(OEngine1[ShipID]).Life + 1;
       TShip(OEngine1[ShipID]).Armour:= 2;
       ShowTitle('1 life bonus!!', 300, 256, $FFFFFF);
      end else
       begin
        TShip(OEngine1[ShipID]).Score:= TShip(OEngine1[ShipID]).Score + 10000;
        ShowTitle('10,000 bonus!!', 300, 256, $FFD000);
       end;
    end;
  end;

 if (TShip(OEngine1[ShipID]).Armour < 1) then
  begin
   TShip(OEngine1[ShipID]).Armour:= 7;
   TShip(OEngine1[ShipID]).Life:= TShip(OEngine1[ShipID]).Life - 1;
   Level:= Level - 1;
   RemoveAsteroids();
   TShip(OEngine1[ShipID]).Score:= TShip(OEngine1[ShipID]).Score - 15;
   NextLevel();
  end;

 if (TShip(OEngine1[ShipID]).Life < 1)and(not GameOver) then
  begin
   ScorePlayer();
   GameOver:= True;
   LevelDelay:= 10 * 60;
  end;

 Inc(Ticks);
 if (Ticks mod 8 = 0) then Inc(CSAnim, CSAnimInc);
 if (CSAnim > 30) then CSAnimInc:= -1;
 if (CSAnim < 1) then CSAnimInc:= 1;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (Key = VK_ESCAPE) then Close();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ShowTitle(Text: string; y, Size: Integer; Color: Cardinal);
begin
 TText.Create(PEngine2, Text, 0, 320, y, Size, Color);
end;

//---------------------------------------------------------------------------
procedure TMainForm.ControlShip();
var
 Ship: TShip;
begin
 Ship:= TShip(OEngine1[ShipID]);

 if (Keyb.Key[VK_LEFT]) then Ship.TurnLeft();
 if (Keyb.Key[VK_RIGHT]) then Ship.TurnRight();
 if (Keyb.Key[VK_UP]) then Ship.Accelerate();
 if (Keyb.Key[VK_DOWN]) then Ship.Brake();

 if (Keyb.Key[VK_SPACE])and(LevelDelay <= 0) then
  begin
   if (Ship.Shoot()) then
    BASS_SamplePlayEx(Sounds[0], 0, -1, 80, -101, False);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.NextLevel();
const
 Colors: array[0..7] of Cardinal = ($00FF00, $007FFF, $FF0000, $FFE000, $FF00FF, $FF7F3F, $0000E0, $D0D0D0);
 Weapons: array[0..9] of Integer = (0, 0, 1, 1, 2, 3, 4, 5, 6, 7);
var
 p: TAsteroid;
 i, iColor: Integer;
 Text: TText;
 PrevWeapon, NewWeapon: Integer;
begin
 RemoveBullets();
 Inc(Level);

 with OEngine1[ShipID] as TShip do
  begin
   Position:= Point2(480.0, 240.0);
   Velocity:= Point2(0.0, 0.0);
   PrevWeapon:= WeaponIndex;
   if (Level < 11) then
    WeaponIndex:= Weapons[Level - 1]
     else WeaponIndex:= 7;
   NewWeapon:= WeaponIndex;
  end;

 for i:= 1 to Max(Level div 2, 1) do
  begin
   p:= TAsteroid.Create(OEngine1);
   p.Position:= Point2(160, 240);
   p.Size:= 192 + (64 * Level);
   p.Score:= 2 + ((Level * 2) div 3);
  end;

 iColor:= (Level - 1) mod 8;
 if (Level > 8) then iColor:= Random(8);
 Text:= TText.Create(PEngine2, 'Level ' + IntToStr(Level), 2, 320, 240, 256, $DBECA1);
 Text.MaxRange:= Round(Timer.Speed * 4);
 LevelDelay:= Round(Timer.Speed * 4);

 if (PrevWeapon <> NewWeapon)and(Level > 1) then
  begin
   Text:= TText.Create(PEngine2, 'Weapons upgraded!', 0, 320, 260, 256, Colors[7 - iColor]);
   Text.MaxRange:= Round(Timer.Speed * 4);
  end;

 if (not Initial) then
  BASS_SamplePlayEx(MainForm.Sounds[3], 0, -1, 100, -101, False);
end;

//---------------------------------------------------------------------------
function TMainForm.AsteroidCount(): Integer;
var
 Aux: TAsphyreObject;
begin
 Result:= 0;

 // acquire initial object
 Aux:= OEngine1.ObjectNum[0];

 // loop through all objects in the list
 while (Aux <> nil) do
  begin
   if (Aux is TAsteroid) then Inc(Result);
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.RemoveBullets();
var
 Aux: TAsphyreObject;
begin
 // acquire initial object
 Aux:= OEngine1.ObjectNum[0];

 // loop through all objects in the list
 while (Aux <> nil) do
  begin
   if (Aux is TBullet) then Aux.Dying:= True;
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.RemoveAsteroids();
var
 Aux: TAsphyreObject;
begin
 // acquire initial object
 Aux:= OEngine1.ObjectNum[0];

 // loop through all objects in the list
 while (Aux <> nil) do
  begin
   if (Aux is TAsteroid) then Aux.Dying:= True;
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.ShowInitial();
var
 Diffuse: Cardinal;
 Alpha, Beta, i: Integer;
begin
 // * This method shows initial two logos
 // - Sorry for messy code, was actually eager to complete this game...
 if (LevelDelay <= InitialPhase1 + InitialPhase2)and(LevelDelay > InitialPhase2) then
  begin
   Beta:= LevelDelay - InitialPhase2;
   Alpha:= 255;
   if (Beta >= InitialPhase1 * 2 / 3) then
    Alpha:= Trunc(((InitialPhase1 - Beta) * 255) / (InitialPhase1 / 3));
   if (Beta <= InitialPhase1 / 3) then
    Alpha:= Trunc((Beta * 255) / (InitialPhase1 / 3));


   Diffuse:= (Cardinal(Alpha) shl 24) or $7F7F7F;

   GameCanvas.UseImagePt(GameImages[imageBandLogo], 0);
   GameCanvas.TexMap(
    pBounds4(320 - 96, 240 - 128, 192.0, 256.0),
    cColor4(Diffuse));

   GameCanvas.WireQuad(pBounds4(320 - 96 - 1, 240 - 128 - 1, 192 + 2, 256 + 2),
    cColor4(Diffuse));
  end;

 if (LevelDelay <= InitialPhase2) then
  begin
   Beta:= LevelDelay;
   Alpha:= 255;
   if (Beta >= InitialPhase2 * 2 / 3) then
    Alpha:= Trunc(((InitialPhase2 - Beta) * 255) / (InitialPhase2 / 3));
   if (Beta <= InitialPhase2 / 3) then
    Alpha:= Trunc((Beta * 255) / (InitialPhase2 / 3));

   Diffuse:= (Cardinal(Alpha) shl 24) or $FFFFFF;

   for i:= 0 to 3 do
    begin
     GameCanvas.UseImagePt(GameImages[imageLogo], i);
     GameCanvas.TexMap(
      pBounds4((i * 160), 240 - 112, 160.0, 224.0),
      cColor4(Diffuse));
    end;

   Diffuse:= (Cardinal(Alpha) shl 24);
   GameCanvas.Line(
    Point2(0, 240 - 112 - 1),
    Point2(640, 240 - 112 - 1),
    $1F1F1F or Diffuse, $5F5F5F or Diffuse);

   GameCanvas.Line(
    Point2(0, 240 + 112), Point2(640, 240 + 112),
    $1F1F1F or Diffuse, $5F5F5F or Diffuse);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.InitBass();
var
 Stream: TMemoryStream;
 Res: Boolean;
 i: Integer;
begin
 MusicModule:= 0;
 for i:= 0 to 3 do Sounds[i]:= 0;
 BassInitiated:= True;

 LoadBassDLL();

 // step 2. Ensure BASS 2.0 was loaded
 if (BASS_GetVersion() <> Cardinal(MAKELONG(2,0))) then
  begin
   MessageDlg('bass.dll version 2.0 is required to run this application!', mtError, [mbOk], 0);
   Application.Terminate();
   Exit;
	end;

 // step 3. Initialize audio - default device, 44100hz, stereo, 16 bits
 if (not BASS_Init(1, 44100, 0, Handle, nil)) then
  begin
   MessageDlg('Failed to initialize bass.dll!', mtError, [mbOk], 0);
   Application.Terminate();
   Exit;
	end;

 // step 4. create memory stream
 Stream:= TMemoryStream.Create();

 // step 5. read the stream
 Res:= Archive.ReadStream('/sten.it', Stream);

 // step 6. check for errors
 if (not Res) then
  begin
   Stream.Free();
   MessageDlg('Failed reading music from archive!', mtError, [mbOk], 0);
   DoneBass();
   Halt;
  end;

 // step 7. load music module
 Stream.Seek(0, soFromBeginning);
 MusicModule:= BASS_MusicLoad(True, Stream.Memory, 0, Stream.Size,
  BASS_MUSIC_LOOP or BASS_MUSIC_RAMPS, 0);

 // step 8. release the stream
 Stream.Free();

 // step 9. finally check if the song has been loaded
 if (MusicModule = 0) then
  begin
   MessageDlg('Failed to load music module from VTDb!', mtError, [mbOk], 0);
   DoneBass();
   Application.Terminate();
  end;

 // step 10. load other sounds
 LoadSounds();
end;

//---------------------------------------------------------------------------
procedure TMainForm.DoneBass();
var
 i: Integer;
begin
 if (MusicModule <> 0) then
  begin
   BASS_MusicFree(MusicModule);
   MusicModule:= 0;
  end;

 for i:= 0 to 3 do
  if (Sounds[i] <> 0) then
   begin
    BASS_SampleFree(Sounds[i]);
    Sounds[i]:= 0;
   end; 

 // Close BASS
 BASS_Free();
 Unload_BASSDLL();
 DeleteFile('bass.dll');
end;

//---------------------------------------------------------------------------
procedure TMainForm.LoadBassDLL();
var
 st: TStream;
begin
 // 1. create 'bass.dll' file
 try
  st:= TFileStream.Create('bass.dll', fmCreate	or fmShareExclusive);
 except
  MessageDlg('Failed to create bass.dll!', mtError, [mbOk], 0);
  Application.Terminate();
  Exit;
 end;

 // 2. load 'bass.dll' file from vtdb to disk
 if (not Archive.ReadStream('/bass.dll', st)) then
  begin
   st.Free();
   MessageDlg('Failed to create bass.dll!', mtError, [mbOk], 0);
   Application.Terminate();
   Exit;
  end;

 // 3. release the stream
 st.Free();

 // 4. load "bass.dll"
 Load_BASSDLL('bass.dll');
end;

//---------------------------------------------------------------------------
procedure TMainForm.LoadSounds();
const
 SoundKeys: array[0..3] of string = ('beam2.wav', 'crash1.wav', 'accel.wav',
  'newlevel.wav');
var
 Stream: TMemoryStream;
 i     : Integer;
begin
 for i:= 0 to 3 do
  begin
   Stream:= TMemoryStream.Create();
   if (not Archive.ReadStream('/' + SoundKeys[i], Stream)) then
    begin
     Stream.Free();
     DoneBass();
     MessageDlg('Failed to load sample sounds!', mtError, [mbOk], 0);
     Application.Terminate();
     Exit;
    end;

   Sounds[i]:= BASS_SampleLoad(True, Stream.Memory, 0, Stream.Size, 8, 0);
   if (Sounds[i] = 0) then
    begin
     Stream.Free();
     DoneBass();
     MessageDlg('Failed to load sample sounds!', mtError, [mbOk], 0);
     Application.Terminate();
     Exit;
    end;

   Stream.Free();
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.ScorePlayer();
var
 HighScore: THighScore;
begin
 HighScore:= HighScores.Add();
 HighScore.Player:= PlayerName;
 HighScore.Score:= TShip(OEngine1[ShipID]).Score;

 HighScores.Sort();
 while (HighScores.Count > 10) do HighScores.Delete(10);
end;

//---------------------------------------------------------------------------
procedure TMainForm.ShowHighScores();
var
 sWidth, i, j: Integer;
 st: string;
begin
 sWidth:= 0;

 // step 1. determine total width of names
 for i:= 0 to HighScores.Count - 1 do
  begin
   st:= IntToStr(i + 1);
   while (Length(st) < 2) do st:= ' ' + st;
   st:= st + '. ' + HighScores[i].Player;
   while (Length(st) > 24) do Delete(st, Length(st), 1);
   sWidth:= Max(sWidth, Round(GameFonts[fontArialBlack].TextWidth(st)));
  end;

 GameFonts[fontImpact].TextMidF(
  Point2(DisplaySize.x div 2, 228.0),
  'High Scores:', cColor2($FFFFFFFF), 1.0);

 for i:= 0 to HighScores.Count - 1 do
  begin
   j:= (((9 - i) * 192) div 9) + 63;

   st:= IntToStr(i + 1);
   while (Length(st) < 2) do st:= ' ' + st;
   st:= st + '. ' + HighScores[i].Player;
   while (Length(st) > 24) do Delete(st, Length(st), 1);
   GameFonts[fontArialBlack].TextOut(
    Point2(200.0, 260 + (i * 20.0)), st,
    cColor2($FFFF7F3F or (Cardinal(j) shl 24)), 1.0);

   GameFonts[fontArialBlack].TextOut(
    Point2(200 + sWidth + 20, 260 + (i * 20)),
    IntToStr(HighScores[i].Score),
    cColor2($FFFFD000 or (Cardinal(j) shl 24)), 1.0);
  end;
end;

//---------------------------------------------------------------------------
end.
