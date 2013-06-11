unit HATypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts,
 Asphyre.Archives, AParticles, AObjects;

//---------------------------------------------------------------------------
var
 DisplaySize: TPoint2px;

//---------------------------------------------------------------------------
 GameDevice : TAsphyreDevice = nil;
 GameCanvas : TAsphyreCanvas = nil;
 GameImages : TAsphyreImages = nil;
 GameFonts  : TAsphyreFonts  = nil;

 Archive    : TAsphyreArchive = nil;

//---------------------------------------------------------------------------
 PEngine1: TParticles;
 OEngine1: TAsphyreObjects;
 PEngine2: TParticles;

//---------------------------------------------------------------------------
 imageBackground : Integer = -1;
 imageShipArmor  : Integer = -1;
 imageCShineLogo : Integer = -1;
 imageBandLogo   : Integer = -1;
 imageLogo       : Integer = -1;
 imageShip       : Integer = -1;
 imageRock       : Integer = -1;
 imageTorpedo    : Integer = -1;
 imageExplode    : Integer = -1;
 imageCombust    : Integer = -1;

//---------------------------------------------------------------------------
 fontArialBlack : Integer = -1;
 fontTimesRoman : Integer = -1;
 fontImpact     : Integer = -1;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
