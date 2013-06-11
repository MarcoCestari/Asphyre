unit Asphyre.Meshes;
//---------------------------------------------------------------------------
// Asphyre 3D mesh implementation.
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
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Classes, System.SysUtils, System.Math, Asphyre.TypeDef, Asphyre.Math, 
 Asphyre.Archives, Asphyre.Math.Sets;

//---------------------------------------------------------------------------
type
 TAsphyreMesh = class
 private
  FName: StdString;

  FVertices   : TVectors3;
  FNormals    : TVectors3;
  FTexCoords  : TPoints2;
  FFaceNormals: TVectors3;
  FFaceOrigins: TVectors3;
  FVertexIndices : TIntegerList;
  FTextureIndices: TIntegerList;

  function FindUnifyMatch(VtxList: TVectors3; TexList: TPoints2;
   const VtxPoint: TVector3; const TexPoint: TPoint2): Integer;
 public
  property Name: StdString read FName write FName;

  property Vertices : TVectors3 read FVertices;
  property Normals  : TVectors3 read FNormals;
  property TexCoords: TPoints2 read FTexCoords;

  property FaceNormals: TVectors3 read FFaceNormals;
  property FaceOrigins: TVectors3 read FFaceOrigins;

  property VertexIndices : TIntegerList read FVertexIndices;
  property TextureIndices: TIntegerList read FTextureIndices;

  procedure ComputeFaceOrigins();
  procedure ComputeFaceNormals();
  procedure ComputeVertexNormals();

  procedure Rescale(const Theta: TVector3);
  procedure Displace(const Theta: TVector3);
  procedure Normalize();
  procedure Centralize();
  procedure InvertNormals();

  procedure UnifyVertices();

  procedure SphericalTextureMappingNormal();
  procedure SphericalTextureMappingPosition();

  procedure Validate();

  procedure LoadFromStream(Stream: TStream);
  procedure SaveToStream(Stream: TStream);

  function LoadFromFile(const FileName: StdString): Boolean;
  function SaveToFile(const FileName: StdString): Boolean;

  function LoadFromArchive(const Key: UniString;
   Archive: TAsphyreArchive): Boolean;
  function SaveToArchive(const Key: UniString;
   Archive: TAsphyreArchive): Boolean;

  procedure Assign(Source: TAsphyreMesh);

  constructor Create(const AName: StdString = '');
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreMeshes = class
 private
  Meshes: array of TAsphyreMesh;

  SearchObjects: array of Integer;
  SearchDirty  : Boolean;

  function GetCount(): Integer;
  function GetItem(Index: Integer): TAsphyreMesh;
  function Insert(Element: TAsphyreMesh): Integer;
  procedure InitSearchObjects();
  procedure SwapSearchObjects(Index1, Index2: Integer);
  function CompareSearchObjects(Obj1, Obj2: TAsphyreMesh): Integer;
  function SplitSearchObjects(Start, Stop: Integer): Integer;
  procedure SortSearchObjects(Start, Stop: Integer);
  procedure UpdateSearchObjects();
  function GetMesh(const Name: StdString): TAsphyreMesh;
 public
  property Count: Integer read GetCount;
  property Items[Index: Integer]: TAsphyreMesh read GetItem; default;

  property Mesh[const Name: StdString]: TAsphyreMesh read GetMesh;

  function IndexOf(Element: TAsphyreMesh): Integer; overload;
  function IndexOf(const Name: StdString): Integer; overload;
  function Include(Element: TAsphyreMesh): Integer;

  function AddFromFile(const FileName: StdString;
   const Name: StdString = ''): Integer;
  function AddFromArchive(const Key: UniString; Archive: TAsphyreArchive;
   const Name: StdString = ''): Integer;

  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure MarkSearchDirty();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 Meshes: TAsphyreMeshes = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Streams, Asphyre.Archives.Auth, Asphyre.Media.Utils;

//---------------------------------------------------------------------------
const
// Vertices under this distance are considered the same point in space,
// when calculating mesh normals.
 WeldEpsilon = 0.0001;

//---------------------------------------------------------------------------
constructor TAsphyreMesh.Create(const AName: StdString = '');
begin
 inherited Create();

 FName:= AName;

 FVertices := TVectors3.Create();
 FNormals  := TVectors3.Create();
 FTexCoords:= TPoints2.Create();

 FFaceNormals:= TVectors3.Create();
 FFaceOrigins:= TVectors3.Create();

 FVertexIndices := TIntegerList.Create();
 FTextureIndices:= TIntegerList.Create();
end;

//---------------------------------------------------------------------------
destructor TAsphyreMesh.Destroy();
begin
 FreeAndNil(FTextureIndices);
 FreeAndNil(FVertexIndices);

 FreeAndNil(FFaceOrigins);
 FreeAndNil(FFaceNormals);

 FreeAndNil(FTexCoords);
 FreeAndNil(FNormals);
 FreeAndNil(FVertices);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.ComputeFaceOrigins();
var
 Num, v0, v1, v2: Integer;
begin
 FFaceOrigins.RemoveAll();

 Num:= 0;

 while (Num < FVertexIndices.Count - 2) do
  begin
   v0:= FVertexIndices[Num];
   v1:= FVertexIndices[Num + 1];
   v2:= FVertexIndices[Num + 2];

   FFaceOrigins.Add((FVertices[v0]^ + FVertices[v1]^ + FVertices[v2]^) / 3.0);

   Inc(Num, 3);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.ComputeFaceNormals();
var
 Num, v0, v1, v2: Integer;
 a, b: TVector3;
begin
 FFaceNormals.RemoveAll();

 Num:= 0;

 while (Num < FVertexIndices.Count - 2) do
  begin
   v0:= FVertexIndices[Num];
   v1:= FVertexIndices[Num + 1];
   v2:= FVertexIndices[Num + 2];

   a:= FVertices[v2]^ - FVertices[v0]^;
   b:= FVertices[v2]^ - FVertices[v1]^;
   FFaceNormals.Add(Norm3(Cross3(a, b)));

   Inc(Num, 3);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.ComputeVertexNormals();
var
 i, FaceNo, VertNo, v0, v1, v2: Integer;
 Weights: array of Single;
 a, b, Normal, Sample: TVector3;
begin
 FNormals.RemoveAll();
 FFaceNormals.RemoveAll();

 SetLength(Weights, FVertexIndices.Count div 3);

 VertNo:= 0;
 FaceNo:= 0;

 while (VertNo < FVertexIndices.Count - 2) do
  begin
   v0:= FVertexIndices[VertNo];
   v1:= FVertexIndices[VertNo + 1];
   v2:= FVertexIndices[VertNo + 2];

   a:= FVertices[v2]^ - FVertices[v0]^;
   b:= FVertices[v2]^ - FVertices[v1]^;

   Normal:= Cross3(a, b);
   FFaceNormals.Add(Norm3(Normal));

   Weights[FaceNo]:= Length3(Normal);

   Inc(FaceNo);
   Inc(VertNo, 3);
  end;

 for i:= 0 to FVertices.Count - 1 do
  begin
   Normal:= ZeroVec3;
   Sample:= FVertices[i]^;

   FaceNo:= 0;
   VertNo:= 0;

   while (VertNo < FVertexIndices.Count - 2) do
    begin
     v0:= FVertexIndices[VertNo];
     v1:= FVertexIndices[VertNo + 1];
     v2:= FVertexIndices[VertNo + 2];

     if (Length3(FVertices[v0]^ - Sample) < WeldEpsilon) then
      Normal:= Normal + (FFaceNormals[FaceNo]^ * Weights[FaceNo]);

     if (Length3(FVertices[v1]^ - Sample) < WeldEpsilon) then
      Normal:= Normal + (FFaceNormals[FaceNo]^ * Weights[FaceNo]);

     if (Length3(FVertices[v2]^ - Sample) < WeldEpsilon) then
      Normal:= Normal + (FFaceNormals[FaceNo]^ * Weights[FaceNo]);

     Inc(FaceNo);
     Inc(VertNo, 3);
    end;

   FNormals.Add(Norm3(Normal));
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Rescale(const Theta: TVector3);
var
 i: Integer;
begin
 for i:= 0 to FVertices.Count - 1 do
  FVertices[i]^:= FVertices[i]^ * Theta;

 for i:= 0 to FFaceOrigins.Count - 1 do
  FFaceOrigins[i]^:= FFaceOrigins[i]^ * Theta;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Displace(const Theta: TVector3);
var
 i: Integer;
begin
 for i:= 0 to FVertices.Count - 1 do
  FVertices[i]^:= FVertices[i]^ + Theta;

 for i:= 0 to FFaceOrigins.Count - 1 do
  FFaceOrigins[i]^:= FFaceOrigins[i]^ + Theta;
end;

//---------------------------------------------------------------------------
function TAsphyreMesh.FindUnifyMatch(VtxList: TVectors3; TexList: TPoints2;
 const VtxPoint: TVector3; const TexPoint: TPoint2): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to VtxList.Count - 1 do
  if (SameVec3(VtxList[i]^, VtxPoint, WeldEpsilon))and
   (SameVec2(TexList[i]^, TexPoint)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.UnifyVertices();
var
 NewVertices : TVectors3;
 NewTexCoords: TPoints2;
 NewIndices  : TIntegerList;
 i, v0, v1, v2, uv0, uv1, uv2, Index: Integer;
begin
 if (FVertexIndices.Count <> FTextureIndices.Count) then Exit;

 NewVertices := TVectors3.Create();
 NewTexCoords:= TPoints2.Create();
 NewIndices  := TIntegerList.Create();

 for i:= 0 to (FVertexIndices.Count div 3) - 1 do
  begin
   v0:= FVertexIndices[i * 3];
   v1:= FVertexIndices[(i * 3) + 1];
   v2:= FVertexIndices[(i * 3) + 2];

   uv0:= FTextureIndices[i * 3];
   uv1:= FTextureIndices[(i * 3) + 1];
   uv2:= FTextureIndices[(i * 3) + 2];

   // First Index (v0, uv0)
   Index:= FindUnifyMatch(NewVertices, NewTexCoords, FVertices[v0]^,
    FTexCoords[uv0]^);
   if (Index = -1) then
    begin
     Index:= NewVertices.Count;
     NewVertices.Add(FVertices[v0]^);
     NewTexCoords.Add(FTexCoords[uv0]^);
    end;

   NewIndices.Insert(Index);

   // Second Index (v1, uv1)
   Index:= FindUnifyMatch(NewVertices, NewTexCoords, FVertices[v1]^,
    FTexCoords[uv1]^);
   if (Index = -1) then
    begin
     Index:= NewVertices.Count;
     NewVertices.Add(FVertices[v1]^);
     NewTexCoords.Add(FTexCoords[uv1]^);
    end;

   NewIndices.Insert(Index);

   // Third Index (v2, uv2)
   Index:= FindUnifyMatch(NewVertices, NewTexCoords, FVertices[v2]^,
    FTexCoords[uv2]^);
   if (Index = -1) then
    begin
     Index:= NewVertices.Count;
     NewVertices.Add(FVertices[v2]^);
     NewTexCoords.Add(FTexCoords[uv2]^);
    end;

   NewIndices.Insert(Index);
  end;

 FVertices.CopyFrom(NewVertices);
 FTexCoords.CopyFrom(NewTexCoords);
 FVertexIndices.CopyFrom(NewIndices);
 FTextureIndices.CopyFrom(NewIndices);

 FreeAndNil(NewIndices);
 FreeAndNil(NewTexCoords);
 FreeAndNil(NewVertices);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.SaveToStream(Stream: TStream);
var
 i: Integer;
begin
 // -> Mesh Name
 StreamPutShortUtf8String(Stream, FName);

 // -> Vertex Count
 StreamPutWord(Stream, FVertices.Count);
 // -> Normals Count
 StreamPutWord(Stream, FNormals.Count);
 // -> Texture Coordinate Count
 StreamPutWord(Stream, FTexCoords.Count);
 // -> Vertex Indices Count
 StreamPutWord(Stream, FVertexIndices.Count);
 // -> Texture Indices Count
 StreamPutWord(Stream, FTextureIndices.Count);
 // -> Face Normal Count
 StreamPutWord(Stream, FFaceNormals.Count);

 // -> Vertices
 for i:= 0 to FVertices.Count - 1 do
  begin
   StreamPutSingle(Stream, FVertices[i].x);
   StreamPutSingle(Stream, FVertices[i].y);
   StreamPutSingle(Stream, FVertices[i].z);
  end;

 // -> Normals
 for i:= 0 to FNormals.Count - 1 do
  begin
   StreamPutSingle(Stream, FNormals[i].x);
   StreamPutSingle(Stream, FNormals[i].y);
   StreamPutSingle(Stream, FNormals[i].z);
  end;

 // -> Texture Coordinates
 for i:= 0 to FTexCoords.Count - 1 do
  begin
   StreamPutSingle(Stream, FTexCoords[i]^.x);
   StreamPutSingle(Stream, FTexCoords[i]^.y);
  end;

 // -> Vertex Indices
 for i:= 0 to FVertexIndices.Count - 1 do
  StreamPutWord(Stream, Cardinal(FVertexIndices[i]));

 // -> Texture Indices
 for i:= 0 to FTextureIndices.Count - 1 do
  StreamPutWord(Stream, Cardinal(FTextureIndices[i]));

 // -> Face Normals
 for i:= 0 to FFaceNormals.Count - 1 do
  begin
   StreamPutSingle(Stream, FFaceNormals[i].x);
   StreamPutSingle(Stream, FFaceNormals[i].y);
   StreamPutSingle(Stream, FFaceNormals[i].z);
  end;

 // Face Origins are not saved and are calculated upon loading instead.
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.LoadFromStream(Stream: TStream);
var
 VertexCount, NormalCount, TexCoordCount: Integer;
 i, VertIndexCount, TexIndexCount, FaceNormCount: Integer;
 Coord: TVector3;
begin
 // -> Mesh Name
 FName:= StreamGetShortUtf8String(Stream);

 // -> Vertex Count
 VertexCount:= StreamGetWord(Stream);
 // -> Normals Count
 NormalCount:= StreamGetWord(Stream);
 // -> Texture Coordinate Count
 TexCoordCount:= StreamGetWord(Stream);
 // -> Vertex Indices Count
 VertIndexCount:= StreamGetWord(Stream);
 // -> Texture Indices Count
 TexIndexCount:= StreamGetWord(Stream);
 // -> Face Normal Count
 FaceNormCount:= StreamGetWord(Stream);

 // -> Vertices
 FVertices.RemoveAll();
 for i:= 0 to VertexCount - 1 do
  begin
   Coord.x:= StreamGetSingle(Stream);
   Coord.y:= StreamGetSingle(Stream);
   Coord.z:= StreamGetSingle(Stream);
   FVertices.Add(Coord);
  end;

 // -> Normals
 FNormals.RemoveAll();
 for i:= 0 to NormalCount - 1 do
  begin
   Coord.x:= StreamGetSingle(Stream);
   Coord.y:= StreamGetSingle(Stream);
   Coord.z:= StreamGetSingle(Stream);
   FNormals.Add(Coord);
  end;

 // -> Texture Coordinates
 FTexCoords.RemoveAll();
 for i:= 0 to TexCoordCount - 1 do
  begin
   Coord.x:= StreamGetSingle(Stream);
   Coord.y:= StreamGetSingle(Stream);
   FTexCoords.Add(Coord.x, Coord.y);
  end;

 // -> Vertex Indices
 FVertexIndices.Clear();
 for i:= 0 to VertIndexCount - 1 do
  FVertexIndices.Insert(Integer(StreamGetWord(Stream)));

 // -> Texture Indices
 FTextureIndices.Clear();
 for i:= 0 to TexIndexCount - 1 do
  FTextureIndices.Insert(Integer(StreamGetWord(Stream)));

 // -> Face Normals
 FFaceNormals.RemoveAll();
 for i:= 0 to FaceNormCount - 1 do
  begin
   Coord.x:= StreamGetSingle(Stream);
   Coord.y:= StreamGetSingle(Stream);
   Coord.z:= StreamGetSingle(Stream);
   FFaceNormals.Add(Coord);
  end;

 // Face Origins are calculated automatically.
 ComputeFaceOrigins();
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Normalize();
var
 MinSize, MaxSize, Theta: Single;
 i: Integer;
begin
 if (FVertices.Count < 1) then Exit;

 MinSize:= High(Integer);
 MaxSize:= Low(Integer);

 for i:= 0 to FVertices.Count - 1 do
  begin
   MinSize:= MinValue([MinSize, FVertices[i].x, FVertices[i].y,
    FVertices[i].z]);

   MaxSize:= MaxValue([MaxSize, FVertices[i].x, FVertices[i].y,
    FVertices[i].z]);
  end;

 Theta:= 1.0 / (MaxSize - MinSize);
 Rescale(Vector3(Theta, Theta, Theta));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.InvertNormals();
var
 i: Integer;
begin
 for i:= 0 to Normals.Count - 1 do
  Normals[i]^:= -Normals[i]^;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Centralize();
var
 MinAxis, MaxAxis, Shift: TVector3;
 i: Integer;
begin
 if (FVertices.Count < 1) then Exit;

 MinAxis:= Vector3(High(Integer), High(Integer), High(Integer));
 MaxAxis:= Vector3(Low(Integer), Low(Integer), Low(Integer));

 for i:= 0 to FVertices.Count - 1 do
  begin
   MinAxis.x:= Min(MinAxis.x, FVertices[i].x);
   MinAxis.y:= Min(MinAxis.y, FVertices[i].y);
   MinAxis.z:= Min(MinAxis.z, FVertices[i].z);

   MaxAxis.x:= Max(MaxAxis.x, FVertices[i].x);
   MaxAxis.y:= Max(MaxAxis.y, FVertices[i].y);
   MaxAxis.z:= Max(MaxAxis.z, FVertices[i].z);
  end;

 Shift.x:= -(MinAxis.x + MaxAxis.x) * 0.5;
 Shift.y:= -(MinAxis.y + MaxAxis.y) * 0.5;
 Shift.z:= -(MinAxis.z + MaxAxis.z) * 0.5;

 Displace(Shift);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.SphericalTextureMappingNormal();
var
 i: Integer;
 Normal: TVector3;
 TexPos: TPoint2;
begin
 if (FVertices.Count <> FNormals.Count) then Exit;

 FTexCoords.RemoveAll();

 for i:= 0 to FVertices.Count - 1 do
  begin
   Normal:= FNormals[i]^;

   TexPos.x:= 0.5 + ArcSin(Normal.x) / Pi;
   TexPos.y:= 0.5 + ArcSin(Normal.y) / Pi;

   FTexCoords.Add(TexPos);
  end;

 FTextureIndices.CopyFrom(FVertexIndices);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.SphericalTextureMappingPosition();
var
 i: Integer;
 Middle, VecTo: TVector3;
 TexPos: TPoint2;
begin
 if (FVertices.Count < 1) then Exit;

 Middle:= ZeroVec3;

 for i:= 0 to FVertices.Count - 1 do
  Middle:= Middle + FVertices[i]^;

 Middle:= Middle * (1.0 / FVertices.Count);

 FTexCoords.RemoveAll();

 for i:= 0 to FVertices.Count - 1 do
  begin
   VecTo:= Norm3(FVertices[i]^ - Middle);

   TexPos.x:= 0.5 + ArcSin(VecTo.x) / Pi;
   TexPos.y:= 0.5 + ArcSin(VecTo.y) / Pi;

   FTexCoords.Add(TexPos);
  end;

 FTextureIndices.CopyFrom(FVertexIndices);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Validate();
var
 Triangles: Integer;
begin
 if (FVertices.Count < 1)or(FVertexIndices.Count mod 3 > 0) then Exit;

 Triangles:= FVertexIndices.Count div 3;
 if (Triangles < 1) then Exit;

 if (FFaceOrigins.Count <> Triangles) then ComputeFaceOrigins();
 if (FFaceNormals.Count <> Triangles) then ComputeFaceNormals();

 if (TextureIndices.Count < 1) then
  begin
   if (FNormals.Count = FVertices.Count) then SphericalTextureMappingNormal()
    else SphericalTextureMappingPosition();
  end;

 if (FNormals.Count <> FVertices.Count) then ComputeVertexNormals();
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Assign(Source: TAsphyreMesh);
begin
 FName:= Source.Name;

 FVertices.CopyFrom(Source.Vertices);
 FNormals.CopyFrom(Source.Normals);
 FTexCoords.CopyFrom(Source.TexCoords);
 FFaceNormals.CopyFrom(Source.FaceNormals);
 FFaceOrigins.CopyFrom(Source.FaceOrigins);
 FVertexIndices.CopyFrom(Source.VertexIndices);
 FTextureIndices.CopyFrom(Source.TextureIndices);
end;

//---------------------------------------------------------------------------
function TAsphyreMesh.LoadFromFile(const FileName: StdString): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
 except
  Result:= False;
  Exit;
 end;

 Result:= True;

 try
  LoadFromStream(Stream);
 except
  Result:= False;
 end;

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreMesh.SaveToFile(const FileName: StdString): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(FileName, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 Result:= True;

 try
  SaveToStream(Stream);
 except
  Result:= False;
 end;

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreMesh.LoadFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 Result:= False;
 if (not Archive.Ready) then Exit;

 Auth.Authorize(Self, Archive);

 Stream:= TMemoryStream.Create();

 Result:= Archive.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Auth.Unauthorize();
   FreeAndNil(Stream);
   Exit;
  end;

 Auth.Unauthorize();

 Stream.Seek(0, soFromBeginning);

 try
  LoadFromStream(Stream);
 except
  Result:= False;
 end;

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreMesh.SaveToArchive(const Key: UniString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 Result:= False;
 if (not Archive.Ready) then Exit;

 Stream:= TMemoryStream.Create();

 try
  SaveToStream(Stream);
 except
  FreeAndNil(Stream);
  Result:= False;
  Exit;
 end;

 Auth.Authorize(Self, Archive);

 Stream.Seek(0, soFromBeginning);
 Result:= Archive.WriteStream(Key, Stream);

 Auth.Unauthorize();
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
constructor TAsphyreMeshes.Create();
begin
 inherited;

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreMeshes.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.GetCount(): Integer;
begin
 Result:= Length(Meshes);
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.GetItem(Index: Integer): TAsphyreMesh;
begin
 if (Index >= 0)and(Index < Length(Meshes)) then
  Result:= Meshes[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Meshes)) then Exit;

 FreeAndNil(Meshes[Index]);

 for i:= Index to Length(Meshes) - 2 do
  Meshes[i]:= Meshes[i + 1];

 SetLength(Meshes, Length(Meshes) - 1);
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Meshes) - 1 do
  if (Assigned(Meshes[i])) then
   FreeAndNil(Meshes[i]);

 SetLength(Meshes, 0);
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.Insert(Element: TAsphyreMesh): Integer;
var
 Index: Integer;
begin
 Index:= Length(Meshes);
 SetLength(Meshes, Index + 1);

 Meshes[Index]:= Element;
 Result:= Index;

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.IndexOf(Element: TAsphyreMesh): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Meshes) - 1 do
  if (Meshes[i] = Element) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.Include(Element: TAsphyreMesh): Integer;
begin
 Result:= IndexOf(Element);

 if (Result = -1) then
  Result:= Insert(Element);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.InitSearchObjects();
var
 i: Integer;
begin
 if (Length(Meshes) <> Length(SearchObjects)) then
  SetLength(SearchObjects, Length(Meshes));

 for i:= 0 to Length(Meshes) - 1 do
  SearchObjects[i]:= i;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.SwapSearchObjects(Index1, Index2: Integer);
var
 Aux: Integer;
begin
 Aux:= SearchObjects[Index1];

 SearchObjects[Index1]:= SearchObjects[Index2];
 SearchObjects[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.CompareSearchObjects(Obj1,
 Obj2: TAsphyreMesh): Integer;
begin
 Result:= CompareText(Obj1.Name, Obj2.Name);
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.SplitSearchObjects(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: TAsphyreMesh;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Meshes[SearchObjects[Start]];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(CompareSearchObjects(Meshes[SearchObjects[Left]],
    Pivot) < 0) do Inc(Left);

   while (Right > Start)and(CompareSearchObjects(Meshes[SearchObjects[Right]],
    Pivot) >= 0) do Dec(Right);

   if (Left < Right) then SwapSearchObjects(Left, Right);
  end;

 SwapSearchObjects(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.SortSearchObjects(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= SplitSearchObjects(Start, Stop);

   SortSearchObjects(Start, SplitPt - 1);
   SortSearchObjects(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.UpdateSearchObjects();
begin
 InitSearchObjects();
 SortSearchObjects(0, Length(SearchObjects) - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.IndexOf(const Name: StdString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (SearchDirty) then UpdateSearchObjects();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(SearchObjects) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= CompareText(Meshes[SearchObjects[Mid]].Name, Name);

   if (Res = 0) then
    begin
     Result:= SearchObjects[Mid];
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMeshes.MarkSearchDirty();
begin
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.GetMesh(const Name: StdString): TAsphyreMesh;
var
 Index: Integer;
begin
 Index:= IndexOf(Name);

 if (Index <> -1) then
  Result:= Meshes[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.AddFromArchive(const Key: UniString;
 Archive: TAsphyreArchive; const Name: StdString = ''): Integer;
var
 MeshItem: TAsphyreMesh;
begin
 if (Name <> '') then MeshItem:= TAsphyreMesh.Create(Name)
  else MeshItem:= TAsphyreMesh.Create(ExtractPipedName(Key));

 if (not MeshItem.LoadFromArchive(Key, Archive)) then
  begin
   MeshItem.Free();
   Result:= -1;
   Exit;
  end;

 Result:= Insert(MeshItem);
end;

//---------------------------------------------------------------------------
function TAsphyreMeshes.AddFromFile(const FileName: StdString;
 const Name: StdString = ''): Integer;
var
 MeshItem: TAsphyreMesh;
begin
 if (Name = '') then
  MeshItem:= TAsphyreMesh.Create(ChangeFileExt(ExtractFileName(FileName), ''))
   else MeshItem:= TAsphyreMesh.Create(Name);

 if (not MeshItem.LoadFromFile(FileName)) then
  begin
   MeshItem.Free();
   Result:= -1;
   Exit;
  end;

 Result:= Insert(MeshItem);
end;

//---------------------------------------------------------------------------
initialization
 Meshes:= TAsphyreMeshes.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(Meshes);

//---------------------------------------------------------------------------
end.

