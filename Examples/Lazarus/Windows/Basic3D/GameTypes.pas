unit GameTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Vectors2px, AbstractDevices, AbstractCanvas, AsphyreImages, AsphyreFonts,
 AsphyreArchives, AsphyreMatrices, AsphyreScenes, AbstractRasterizer;

//---------------------------------------------------------------------------
var
 DisplaySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice : TAsphyreDevice = nil;
 GameCanvas : TAsphyreCanvas = nil;
 GameRaster : TAsphyreRasterizer = nil;
 GameImages : TAsphyreImages = nil;
 GameFonts  : TAsphyreFonts  = nil;
 GameScene  : TAsphyreScene = nil;
 MediaFile  : TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 fontCorbel: Integer = -1;

//---------------------------------------------------------------------------
 imageBricks: Integer = -1;

//---------------------------------------------------------------------------
 meshCube: Integer = -1;

//---------------------------------------------------------------------------
 WorldMtx: TAsphyreMatrix = nil;
 ViewMtx : TAsphyreMatrix = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
initialization
 WorldMtx:= TAsphyreMatrix.Create();
 ViewMtx := TAsphyreMatrix.Create();

//---------------------------------------------------------------------------
finalization
 ViewMtx.Free();
 WorldMtx.Free();

//---------------------------------------------------------------------------
end.
