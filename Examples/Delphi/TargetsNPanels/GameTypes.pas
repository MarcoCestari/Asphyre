unit GameTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, Asphyre.Canvas, Asphyre.Images,
 Asphyre.Fonts, Asphyre.Archives, Asphyre.RenderTargets;

//---------------------------------------------------------------------------
var
 DisplaySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice : TAsphyreDevice = nil;
 GameCanvas : TAsphyreCanvas = nil;
 GameImages : TAsphyreImages = nil;
 GameFonts  : TAsphyreFonts  = nil;
 GameTargets: TAsphyreRenderTargets = nil;

 MediaFile  : TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 swapDraw: Integer = -1;
 swapMix : Integer = -1;

//---------------------------------------------------------------------------
 fontTahoma : Integer = -1;
 fontCalibri: Integer = -1;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
