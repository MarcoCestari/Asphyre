unit MainFm;
//---------------------------------------------------------------------------
// Asphyre Security example.
// Illustrates how to load password-protected content.
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
 Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
 Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    FailureHandled: Boolean;
    FileCreated: Boolean;
    GameTicks: Integer;

    procedure OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceInit(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceCreate(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnTimerReset(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure TimerEvent(Sender: TObject);
    procedure ProcessEvent(Sender: TObject);
    procedure RenderEvent(Sender: TObject);

    procedure HandleConnectFailure();
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.dfm}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Types, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FormTimers, Asphyre.Providers, Asphyre.Archives, Asphyre.Devices,
 Asphyre.Images, Asphyre.Fonts, Asphyre.Canvas, Asphyre.Native.Connectors,
 Asphyre.Providers.DX9, GameTypes, GameAuth;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Enable Delphi's memory manager to show memory leaks.
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Specify that DirectX 9 provider is to be used.
 Factory.UseProvider(idDirectX9);

 // This event is called when Asphyre components should be created.
 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);

 // This event is called when Asphyre components are to be freed.
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);

 // This event is callled before creating Asphyre device to initialize its
 // parameters.
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);

 // This event is callled upon Asphyre device creation.
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);

 // This event is called when creating device and loading data to let the
 // application reset the timer so it does not stall.
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 // Initialize and prepare the timer.
 Timer.OnTimer  := TimerEvent;
 Timer.OnProcess:= ProcessEvent;
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
procedure TMainForm.OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // Create all Asphyre components.
 GameDevice:= Factory.CreateDevice();
 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 FileCreated:= False;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Enabled:= False;

 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(MediaFile);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(Self.Handle, DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 GameImages.AddFromArchive('raavi.image', MediaFile, '', False);

 fontRaavi:= GameFonts.Insert('media.asvf | raavi.xml', 'raavi.image');
 imageFruits := GameImages.AddFromArchive('fruits.image', MediaFile);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontRaavi <> -1)and
  (imageFruits <> -1);
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

 // Render the scene.
 GameDevice.Render(RenderEvent, $FF28313B);

 // Execute constant time processing.
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 Inc(GameTicks);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
begin
 GameCanvas.MipMapping:= True;

 GameCanvas.UseImagePx(GameImages[imageFruits], pBounds4(0, 0, 512, 512));
 GameCanvas.TexMap(pRotate4c(Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  Point2(300.0, 300.0), GameTicks * 0.008741), clWhite4);

 GameFonts[fontRaavi].TextMidH(
  Point2px(DisplaySize.x div 2, 200 + DisplaySize.y div 2),
  'The above image as well as this font were loaded securely from archive.',
  cColor2($FFE2E9EE, $FF8CC5FF), 1.0);

 if (not FileCreated) then
  begin
   GameFonts[fontRaavi].TextOut(
    Point2(4.0, 24.0),
    'Press F2 to generate "password.key" file.',
    cColor2($FFF1F4F0, $FF9ABD9E));

   GameFonts[fontRaavi].TextOut(
    Point2(4.0, 44.0),
    'This file will be used by AsphyreManager to handle your secure archives.',
    cColor2($FFF1F4F0, $FF9ABD9E));

   GameFonts[fontRaavi].TextOut(
    Point2(4.0, 64.0),
    'It must be located in the same folder as your archives.',
    cColor2($FFF1F4F0, $FF9ABD9E));

   GameFonts[fontRaavi].TextOut(
    Point2(4.0, 84.0),
    'Remember to delete it before distributing your application!',
    cColor2($FFF1F4F0, $FF9ABD9E));
  end else
  begin
   GameFonts[fontRaavi].TextOut(
    Point2(4.0, 24.0),
    '"password.key" file has been created.',
    cColor2($FFA193FF, $FFE3EDFF));
  end;

 GameFonts[fontRaavi].TextOut(Point2(4.0, 4.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate), cColor2($FFFFEA8C, $FFF7B300));

 GameFonts[fontRaavi].TextOut(
  Point2(4.0, 104.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormResize(Sender: TObject);
begin
 if (Assigned(GameDevice)) then
  begin
   DisplaySize:= Point2px(ClientWidth, ClientHeight);
   GameDevice.Resize(0, DisplaySize);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimerReset(const Sender: TObject; const Param: Pointer;
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
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
var
 List: TStringList;
 DestFile: string;
begin
 if (Key <> VK_F2)or(FileCreated) then Exit;

 DestFile:= ExtractFilePath(ParamStr(0)) + 'password.key';

 List:= TStringList.Create();
 List.Text:= PasswordProvider.GetKeyText();
 List.SaveToFile(DestFile);
 List.Free();

 FileCreated:= True;
 Timer.Reset();
end;

//---------------------------------------------------------------------------
end.
