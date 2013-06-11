unit GameTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts,
 Asphyre.Archives, Asphyre.RenderTargets;

//---------------------------------------------------------------------------
var
 DisplaySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice : TAsphyreDevice = nil;
 GameCanvas : TAsphyreCanvas = nil;
 GameImages : TAsphyreImages = nil;
 GameFonts  : TAsphyreFonts  = nil;

//---------------------------------------------------------------------------
 RenderTargets: TAsphyreRenderTargets = nil;

//---------------------------------------------------------------------------
 MediaFile: TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 GameTicks: Integer = 0;

//---------------------------------------------------------------------------
 fontCorbel: Integer = -1;

//---------------------------------------------------------------------------
 targetMotion: Integer = -1;
 targetBlur  : Integer = -1;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
