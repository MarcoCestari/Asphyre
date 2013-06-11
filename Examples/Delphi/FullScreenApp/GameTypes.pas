unit GameTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts,
 Asphyre.Archives, Asphyre.RenderTargets;

//---------------------------------------------------------------------------
var
 PrimarySize  : TPoint2px;
 SecondarySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice : TAsphyreDevice = nil;
 GameCanvas : TAsphyreCanvas = nil;
 GameImages : TAsphyreImages = nil;
 GameFonts  : TAsphyreFonts  = nil;

//---------------------------------------------------------------------------
 MediaFile: TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 GameTicks: Integer = 0;

//---------------------------------------------------------------------------
 fontBookAntiqua: Integer = -1;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
