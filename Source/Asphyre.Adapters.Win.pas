unit Asphyre.Adapters.Win;
//---------------------------------------------------------------------------
// Adapter Management Utility for Windows platform.
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
{$ifndef fpc}
 WinApi.Windows, WinApi.MultiMon,
{$else}
 Windows, MultiMon,
{$endif}
 Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
 PWinAdapterInfo = ^TWinAdapterInfo;
 TWinAdapterInfo = record
  DeviceName: string;
  DeviceText: string;
  MnRect    : TRect;
  Monitor   : HMonitor;
 end;

//---------------------------------------------------------------------------
 PWinAdapterMode = ^TWinAdapterMode;
 TWinAdapterMode = record
  Width   : Integer;
  Height  : Integer;
  BitDepth: Integer;
  Refresh : Integer;
  DevMode : TDeviceMode;
 end;

//---------------------------------------------------------------------------
 TWinAdapterHelper = class
 private
  Adapters: array of TWinAdapterInfo;
  Modes   : array of TWinAdapterMode;

  function InsertAdapter(const AAdapter: TWinAdapterInfo): Integer;

  function GetAdapterCount(): Integer;
  function GetAdapter(Index: Integer): PWinAdapterInfo;
  function GetMode(Index: Integer): PWinAdapterMode;
  function GetModeCount(): Integer;
 public
  property AdapterCount: Integer read GetAdapterCount;
  property Adapter[Index: Integer]: PWinAdapterInfo read GetAdapter;

  property ModeCount: Integer read GetModeCount;
  property Mode[Index: Integer]: PWinAdapterMode read GetMode;

  function RefreshAdapters(): Boolean;
  function RefreshModes(AdapterNo: Integer): Boolean;

  function MatchMode(Width, Height: Integer; BitDepth: Integer = 0;
   Refresh: Integer = 0): Integer;
  function CurrentMode(AdapterNo: Integer): TWinAdapterMode;

  function SetTempMode(AdapterNo, NewMode: Integer): Boolean;
  procedure RestoreTempMode(AdapterNo: Integer);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 WinAdapterHelper: TWinAdapterHelper = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils;
{$else}
 SysUtils;
{$endif}


//---------------------------------------------------------------------------
const
 ENUM_CURRENT_SETTINGS  = Cardinal(-1);
 ENUM_REGISTRY_SETTINGS = Cardinal(-2);

//---------------------------------------------------------------------------
function EnumCallback(Monitor: HMONITOR; MonitorDC: HDC; MonitorRect: PRect;
 Context: LPARAM): Boolean; stdcall;
var
 InfoItem: TWinAdapterInfo;
 Helper  : TWinAdapterHelper;
 Info    : TMonitorInfoEx;
 DpDevice: TDisplayDeviceW;
begin
 FillChar(Info, SizeOf(TMonitorInfoEx), 0);
 Info.cbSize:= SizeOf(TMonitorInfoEx);

 if (GetMonitorInfo(Monitor, @Info)) then
  begin
   InfoItem.DeviceName:= Info.szDevice;
   InfoItem.MnRect    := Info.rcWork;
   InfoItem.Monitor   := Monitor;

   FillChar(DpDevice, SizeOf(TDisplayDeviceA), 0);
   DpDevice.cb:= SizeOf(TDisplayDeviceA);

   if (EnumDisplayDevicesW(PChar(InfoItem.DeviceName), 0, DpDevice, 0)) then
    InfoItem.DeviceText:= DpDevice.DeviceString
     else InfoItem.DeviceText:= InfoItem.DeviceName;

   Helper:= TWinAdapterHelper(Context);
   Helper.InsertAdapter(InfoItem);
  end;

 Result:= True;
end;

//---------------------------------------------------------------------------
constructor TWinAdapterHelper.Create();
begin
 inherited;

end;

//---------------------------------------------------------------------------
destructor TWinAdapterHelper.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.RefreshAdapters(): Boolean;
begin
 SetLength(Adapters, 0);

 Result:= EnumDisplayMonitors(0, nil, EnumCallback, PtrInt(Self));
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.InsertAdapter(
 const AAdapter: TWinAdapterInfo): Integer;
begin
 Result:= Length(Adapters);
 SetLength(Adapters, Result + 1);

 Adapters[Result]:= AAdapter;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.GetAdapterCount(): Integer;
begin
 Result:= Length(Adapters);
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.GetAdapter(Index: Integer): PWinAdapterInfo;
begin
 if (Index >= 0)and(Index < Length(Adapters)) then
  Result:= @Adapters[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.GetModeCount(): Integer;
begin
 Result:= Length(Modes);
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.GetMode(Index: Integer): PWinAdapterMode;
begin
 if (Index >= 0)and(Index < Length(Modes)) then
  Result:= @Modes[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.RefreshModes(AdapterNo: Integer): Boolean;
var
 iMode, Index: Integer;
 DevMode: TDeviceMode;
begin
 if (AdapterNo <= Length(Adapters)) then
  begin
   Result:= RefreshAdapters();
   if (not Result) then Exit;
  end;

 SetLength(Modes, 0);

 iMode:= 0;
 while (EnumDisplaySettingsW(PWideChar(Adapters[AdapterNo].DeviceName), iMode,
  DevMode)) do
  begin
   Index:= Length(Modes);
   SetLength(Modes, Index + 1);

   Modes[Index].Width   := DevMode.dmPelsWidth;
   Modes[Index].Height  := DevMode.dmPelsHeight;
   Modes[Index].BitDepth:= DevMode.dmBitsPerPel;
   Modes[Index].Refresh := DevMode.dmDisplayFrequency;
   Move(DevMode, Modes[Index].DevMode, SizeOf(TDeviceMode));
   
   Inc(iMode);
  end;
  
 Result:= Length(Modes) > 0; 
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.MatchMode(Width, Height: Integer;
 BitDepth: Integer = 0; Refresh: Integer = 0): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Modes) - 1 do
  if (Modes[i].Width = Width)and(Modes[i].Height = Height) then
   begin
    if (BitDepth > 0)and(Modes[i].BitDepth <> BitDepth) then Continue;
    if (Refresh > 0)and(Modes[i].Refresh <> Refresh) then Continue;

    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.CurrentMode(AdapterNo: Integer): TWinAdapterMode;
var
 DevMode: TDeviceMode;
begin
 FillChar(Result, SizeOf(TWinAdapterMode), 0);

 if (AdapterNo >= Length(Adapters))and(not RefreshAdapters()) then Exit;
 if (AdapterNo >= Length(Adapters)) then Exit;
 
 if (not EnumDisplaySettingsW(PChar(Adapters[AdapterNo].DeviceName),
  ENUM_CURRENT_SETTINGS, DevMode)) then Exit;
  
 Result.Width   := DevMode.dmPelsWidth;
 Result.Height  := DevMode.dmPelsHeight;
 Result.BitDepth:= DevMode.dmBitsPerPel;
 Result.Refresh := DevMode.dmDisplayFrequency;
end;

//---------------------------------------------------------------------------
function TWinAdapterHelper.SetTempMode(AdapterNo, NewMode: Integer): Boolean;
var
 DevMode: TDeviceMode;
begin
 if (NewMode < 0)or(NewMode >= Length(Modes))or(AdapterNo < 0)or
  (AdapterNo >= Length(Adapters)) then
  begin
   Result:= False;
   Exit;
  end;

 Move(Modes[NewMode].DevMode, DevMode, SizeOf(TDeviceMode));

 Result:= ChangeDisplaySettingsEx(PChar(Adapters[AdapterNo].DeviceName),
  DevMode, 0, CDS_FULLSCREEN, nil) = DISP_CHANGE_SUCCESSFUL;
end;

//---------------------------------------------------------------------------
procedure TWinAdapterHelper.RestoreTempMode(AdapterNo: Integer);
var
 DevMode: PDeviceModeW;
begin
 if (AdapterNo < 0)or(AdapterNo >= Length(Adapters)) then Exit;

 DevMode:= nil;

 ChangeDisplaySettingsEx(PChar(Adapters[AdapterNo].DeviceName), DevMode^,
  0, 0, nil);
end;

//---------------------------------------------------------------------------
initialization
 WinAdapterHelper:= TWinAdapterHelper.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(WinAdapterHelper);

//---------------------------------------------------------------------------
end.
