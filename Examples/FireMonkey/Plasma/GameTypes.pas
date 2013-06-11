unit GameTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts,
 Asphyre.Archives;

//---------------------------------------------------------------------------
var
 DisplaySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice: TAsphyreDevice = nil;
 GameCanvas: TAsphyreCanvas = nil;
 GameImages: TAsphyreImages = nil;
 GameFonts : TAsphyreFonts  = nil;

//---------------------------------------------------------------------------
 MediaFile: TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 imagePlasma  : Integer = -1;
 imageScanline: Integer = -1;

//---------------------------------------------------------------------------
 fontTranceform: Integer = -1;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
