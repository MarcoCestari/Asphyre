unit MainFm;
//---------------------------------------------------------------------------
// Basic 3D Example for Asphyre Sphinx.                 Modified: 12-Sep-2012
// Shows how to display a simple 3D mesh.                        Version 1.01
//---------------------------------------------------------------------------
// Important Notice:
//
// If you modify/use this code or one of its parts either in original or
// modified form, you must comply with Mozilla Public License v1.1,
// specifically section 3, "Distribution Obligations". Failure to do so will
// result in the license breach, which will be resolved in the court.
// Remember that violating author's rights is considered a serious crime in
// many countries. Thank you!
//
// !! Please *read* Mozilla Public License 1.1 document located at:
//  http://www.mozilla.org/MPL/
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

{$mode objfpc}{$H+}

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Messages, SysUtils, Classes, Controls, Forms, Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;
    GameTicks: Integer;

    procedure OnAsphyreCreate(Sender: TObject; Param: Pointer;
     var Handled: Boolean);

    procedure OnAsphyreDestroy(Sender: TObject; Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceInit(Sender: TObject; Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceCreate(Sender: TObject; Param: Pointer;
     var Handled: Boolean);

    procedure OnTimerReset(Sender: TObject; Param: Pointer;
     var Handled: Boolean);

    procedure TimerEvent(Sender: TObject);
    procedure ProcessEvent(Sender: TObject);
    procedure RenderEvent(Sender: TObject);

    procedure CreateLights();
    procedure HandleConnectFailure();
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.lfm}

//---------------------------------------------------------------------------
uses
 Vectors2, Vectors2px, Vectors3, AsphyreTypes, AsphyreColors, AsphyreEventTypes,
 AsphyreEvents, AsphyreTimer, AsphyreFactory, AsphyreArchives, AbstractDevices,
 AsphyreImages, AsphyreFonts, AbstractCanvas, AsphyreScenes, AsphyreMeshes,
 AbstractRasterizer, AsphyreLights, NativeConnectors, GameTypes, DX9Providers;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Specify that DirectX 9 provider is to be used.
 Factory.UseProvider(idDirectX9);

 // This event is called when Asphyre components should be created.
 EventAsphyreCreate.Subscribe(ClassName, @OnAsphyreCreate);

 // This event is called when Asphyre components are to be freed.
 EventAsphyreDestroy.Subscribe(ClassName, @OnAsphyreDestroy);

 // This event is callled before creating Asphyre device to initialize its
 // parameters.
 EventDeviceInit.Subscribe(ClassName, @OnDeviceInit);

 // This event is callled upon Asphyre device creation.
 EventDeviceCreate.Subscribe(ClassName, @OnDeviceCreate);

 // This event is called when creating device and loading data to let the
 // application reset the timer so it does not stall.
 EventTimerReset.Subscribe(ClassName, @OnTimerReset);

 // Initialize and prepare the timer.
 Timer.OnTimer  := @TimerEvent;
 Timer.OnProcess:= @ProcessEvent;
 Timer.Enabled  := True;

 // Tell AsphyreManager that the archive will always be in the same folder
 // as this application.
 ArchiveTypeAccess:= ataPackaged;

 // This variable tells that a connection failure to Asphyre device has been
 // already handled.
 FailureHandled:= False;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 // Disconnect Asphyre device.
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 // Finish the Asphyre connection manager.
 NativeAsphyreConnect.Done();

 // Remove the subscription to the events.
 EventProviders.Unsubscribe(ClassName);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(Sender: TObject; Param: Pointer;
 var Handled: Boolean);
begin
 // Create all Asphyre components.
 GameDevice:= Factory.CreateDevice();
 GameCanvas:= Factory.CreateCanvas();
 GameRaster:= Factory.CreateRasterizer();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 GameScene:= TAsphyreScene.Create();
 GameScene.Raster     := GameRaster;
 GameScene.DisplaySize:= DisplaySize;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 // Create the lights that will be used in our 3D scene.
 CreateLights();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(Sender: TObject; Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Enabled:= False;

 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(MediaFile);
 FreeAndNil(GameScene);
 FreeAndNil(GameRaster);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(Sender: TObject; Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(Self.Handle, DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(Sender: TObject; Param: Pointer;
 var Handled: Boolean);
var
 Mesh: TAsphyreMesh;
begin
 // Load the font's image and the character descriptions.
 GameImages.AddFromArchive('Corbel.image', MediaFile, '', False);
 fontCorbel:= GameFonts.Insert('media.asvf | Corbel.xml', 'Corbel.image');

 // This image will be used as texture for our 3D cube.
 imageBricks:= GameImages.AddFromArchive('Bricks.image', MediaFile);

 // This is our 3D cube itself.
 Mesh:= TAsphyreMesh.Create();
 if (not Mesh.LoadFromArchive('cube.mesh', MediaFile)) then FreeAndNil(Mesh);

 if (Assigned(Mesh)) then
  meshCube:= Meshes.Include(Mesh);

 // Make sure everything has been loaded properly.
 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (imageBricks <> -1)and
  (meshCube <> -1)and
  (fontCorbel <> -1);
end;

//---------------------------------------------------------------------------
procedure TMainForm.TimerEvent(Sender: TObject);
begin
 // Try to connect Asphyre to the application.
 if (not NativeAsphyreConnect.Init()) then Exit;

 // In case the device could not be initialized properly (in the frame before
 // this one), show error message and close the form.
 if (Assigned(GameDevice))and(GameDevice.IsAtFault()) then
  begin
   if (not FailureHandled) then HandleConnectFailure();
   FailureHandled:= True;
   Exit;
  end;

 // Initialize Asphyre device, if needed. If this initialization fails, the
 // failure will be handled in the next OnTimer event.
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 GameDevice.Render(@RenderEvent, $000050);
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 Inc(GameTicks);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
var
 Phi: Single;
begin
 // The following call is not exactly necessary (since it's called
 // automatically), unless you have drawn 2D stuff before that.
 GameRaster.ResetStates();

 // The following parameter is important to preserve 3D object sizes on
 // different resolutions.
 GameScene.AspectRatio:= DisplaySize.y / DisplaySize.x;

 // Below the view matrix is configured, which is basically our "camera" in
 // the 3D scene.
 ViewMtx.LoadIdentity();

 // Here we specify our camera position and orientation.
 ViewMtx.LookAt(
  // Where are we located?
  Vector3(150.0, 150.0, 150.0),
  // What position are we looking at?
  Vector3(0.0, 0.0, 0.0),
  // The following vector defines our camera's "roof" (i.e. camera's top)
  AxisYVec3);

 // The following call must always be made before drawing 3D stuff.
 GameScene.BeginScene();

 // Initially, rescale our cube to 100x100x100 size.
 // By default, it has unitary size of 1x1x1.
 WorldMtx.LoadIdentity();
 WorldMtx.Scale(100.0);

 // Rotate the cube and move it around.
 Phi:= GameTicks * Pi / 100.0;
 WorldMtx.RotateX(Phi);
 WorldMtx.Translate(Sin(Phi) * 50.0, Sin(Phi) * 50.0, Sin(Phi) * 50.0);

 // Place the cube mesh in our world scene.
 GameScene.Draw(Meshes[meshCube], WorldMtx.RawMtx, GameImages[imageBricks]);

 // The following call must always follow after rendering 3D stuff.
 GameScene.EndScene(ViewMtx.RawMtx);

 // The 3D scene has been made, now display it on the screen.
 GameScene.Present(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  DisplaySize);

 // The raster class is used to draw triangles on the screen from the 3D scene.
 // Make sure to flush its buffers before drawing 2D stuff.
 GameRaster.Flush();

 // In order to continue drawing 2D stuff, we need to make this call so that
 // the canvas is ready.
 GameCanvas.ResetStates();

 // Display the information text.
 GameFonts[fontCorbel].TextOut(
  Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFFFEC99, $FFF78900));

 GameFonts[fontCorbel].TextOut(
  Point2(4.0, 24.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));

 // The following call is not necessary here, unless you want to render 3D
 // stuff afterwards. To avoid having problems later on, leave it as is.
 GameCanvas.Flush();
end;

//---------------------------------------------------------------------------
procedure TMainForm.CreateLights();
var
 Ambient: TAsphyreAmbientLight;
begin
 // Our scene is not going to be lit with anything, so we just set the ambient
 // light to maximum value.
 Ambient:= TAsphyreAmbientLight.Create();
 Ambient.Color:= cColor(255, 255, 255, 0);

 GameScene.Lights.Insert(Ambient);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimerReset(Sender: TObject; Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Reset();
end;

//---------------------------------------------------------------------------
procedure TMainForm.HandleConnectFailure();
begin
 Timer.Enabled:= False;

 ShowMessage('Failed initializing Asphyre device.');
 Close();
end;

//---------------------------------------------------------------------------
end.
