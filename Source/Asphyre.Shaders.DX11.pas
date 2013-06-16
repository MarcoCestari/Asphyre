unit Asphyre.Shaders.DX11;
//---------------------------------------------------------------------------
// High-level shader effect wrapper for Direct3D 11.
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
{$ifndef fpc}
 Winapi.Windows,
{$else}
 Windows,
{$endif}
 JSB.D3D11, Asphyre.TypeDef, Asphyre.Math;

//---------------------------------------------------------------------------
type
 PDX11BufferVariable = ^TDX11BufferVariable;
 TDX11BufferVariable = record
  VariableName: StdString;
  ByteAddress: Integer;
  SizeInBytes: Integer;
 end;

//---------------------------------------------------------------------------
 TDX11BufferVariables = class
 private
  Data: array of TDX11BufferVariable;
  DataDirty: Boolean;

  procedure DataListSwap(Index1, Index2: Integer);
  function DataListCompare(const Item1, Item2: TDX11BufferVariable): Integer;
  function DataListSplit(Start, Stop: Integer): Integer;
  procedure DataListSort(Start, Stop: Integer);
  procedure UpdateDataDirty();

  function IndexOf(const Name: StdString): Integer;

  function GetVariable(const Name: StdString): PDX11BufferVariable;
 public
  property Variable[const Name: StdString]: PDX11BufferVariable
   read GetVariable; default;

  procedure Declare(const Name: StdString; AByteAddress, ASizeInBytes: Integer);
  procedure Clear();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX11ConstantBufferType = (cbtUnknown, cbtVertex, cbtPixel);

//---------------------------------------------------------------------------
 TDX11ConstantBuffer = class
 private
  FVariables: TDX11BufferVariables;

  FName: StdString;
  FInitialized: Boolean;

  FBufferType: TDX11ConstantBufferType;
  FBufferSize: Integer;

  FSystemBuffer: Pointer;
  FVideoBuffer: ID3D11Buffer;

  FConstantIndex: Integer;

  procedure SetBufferType(Value: TDX11ConstantBufferType);
  procedure SetBufferSize(Value: Integer);
  procedure SetConstantIndex(Value: Integer);

  function UpdateVariable(const Variable: TDX11BufferVariable;
   Content: Pointer; ByteOffset, ByteCount: Integer): Boolean;

  function SetBasicVariable(const VariableName: string; Content: Pointer;
   ContentSize, SubIndex: Integer): Boolean;
 public
  property Name: StdString read FName;

  property Initialized: Boolean read FInitialized;

  property BufferType: TDX11ConstantBufferType read FBufferType
   write SetBufferType;

  property BufferSize: Integer read FBufferSize write SetBufferSize;

  property SystemBuffer: Pointer read FSystemBuffer;
  property VideoBuffer : ID3D11Buffer read FVideoBuffer;

  property ConstantIndex: Integer read FConstantIndex write SetConstantIndex;

  property Variables: TDX11BufferVariables read FVariables;

  function Initialize(): Boolean;
  procedure Finalize();

  function Update(): Boolean;
  function Bind(): Boolean;

  function SetInt(const VariableName: StdString; Value: LongInt;
   SubIndex: Integer = 0): Boolean;

  function SetUInt(const VariableName: StdString; Value: LongWord;
   SubIndex: Integer = 0): Boolean;

  function SetFloat(const VariableName: StdString; Value: Single;
   SubIndex: Integer = 0): Boolean;

  function SetPoint2(const VariableName: StdString; const Value: TPoint2;
   SubIndex: Integer = 0): Boolean;

  function SetVector3(const VariableName: StdString; const Value: TVector3;
   SubIndex: Integer = 0): Boolean;

  function SetVector4(const VariableName: StdString; const Value: TVector4;
   SubIndex: Integer = 0): Boolean;

  function SetMatrix4(const VariableName: StdString; const Value: TMatrix4;
   SubIndex: Integer = 0): Boolean;

  constructor Create(const AName: StdString);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX11ShaderEffect = class
 private
  ConstantBuffers: array of TDX11ConstantBuffer;
  ConstantBuffersDirty: Boolean;

  FInitialized: Boolean;

  FInputLayout : ID3D11InputLayout;
  FVertexShader: ID3D11VertexShader;
  FPixelShader : ID3D11PixelShader;

  VertexLayoutDesc: array of D3D11_INPUT_ELEMENT_DESC;

  BinaryVS: Pointer;
  BinaryVSLength: Integer;

  BinaryPS: Pointer;
  BinaryPSLength: Integer;

  procedure ConstantBufferSwap(Index1, Index2: Integer);
  function ConstantBufferCompare(const Item1,
   Item2: TDX11ConstantBuffer): Integer;
  function ConstantBufferSplit(Start, Stop: Integer): Integer;
  procedure ConstantBufferSort(Start, Stop: Integer);
  procedure OrderConstantBuffers();

  function IndexOfConstantBuffer(const Name: StdString): Integer;
  function GetConstantBuffer(const Name: StdString): TDX11ConstantBuffer;
 public
  property Initialized: Boolean read FInitialized;

  property InputLayout : ID3D11InputLayout read FInputLayout;
  property VertexShader: ID3D11VertexShader read FVertexShader;
  property PixelShader : ID3D11PixelShader read FPixelShader;

  property ConstantBuffer[const Name: StdString]: TDX11ConstantBuffer
   read GetConstantBuffer; default;

  procedure RemoveAllConstantBuffers();

  function AddConstantBuffer(const AName: StdString;
   ABufferType: TDX11ConstantBufferType; ABufferSize: Integer;
   AConstantIndex: Integer = 0): TDX11ConstantBuffer;

  function UpdateBindAllBuffers(): Boolean;

  function SetVertexLayout(Content: PD3D11_INPUT_ELEMENT_DESC;
   ElementCount: Integer): Boolean;

  procedure SetShaderCodes(AVertexShader: Pointer; AVertexShaderLength: Integer;
   APixelShader: Pointer; APixelShaderLength: Integer);

  function Initialize(): Boolean;
  procedure Finalize();

  function Activate(): Boolean;
  procedure Deactivate();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Types, Asphyre.Types.DX11;

//---------------------------------------------------------------------------
constructor TDX11BufferVariables.Create();
begin
 inherited;

 DataDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TDX11BufferVariables.Destroy();
begin
 Clear();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX11BufferVariables.DataListSwap(Index1, Index2: Integer);
var
 Aux: TDX11BufferVariable;
begin
 Aux:= Data[Index1];

 Data[Index1]:= Data[Index2];
 Data[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TDX11BufferVariables.DataListCompare(const Item1,
 Item2: TDX11BufferVariable): Integer;
begin
 Result:= CompareText(Item1.VariableName, Item2.VariableName);
end;

//---------------------------------------------------------------------------
function TDX11BufferVariables.DataListSplit(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: TDX11BufferVariable;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Data[Start];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(DataListCompare(Data[Left], Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(DataListCompare(Data[Right], Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then DataListSwap(Left, Right);
  end;

 DataListSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TDX11BufferVariables.DataListSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= DataListSplit(Start, Stop);

   DataListSort(Start, SplitPt - 1);
   DataListSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11BufferVariables.UpdateDataDirty();
begin
 if (Length(Data) > 1) then DatalistSort(0, Length(Data) - 1);
 DataDirty:= False;
end;

//---------------------------------------------------------------------------
function TDX11BufferVariables.IndexOf(const Name: StdString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (DataDirty) then UpdateDataDirty();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(Data) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= CompareText(Data[Mid].VariableName, Name);

   if (Res = 0) then
    begin
     Result:= Mid;
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11BufferVariables.Clear();
begin
 SetLength(Data, 0);
 DataDirty:= False;
end;

//---------------------------------------------------------------------------
function TDX11BufferVariables.GetVariable(
 const Name: StdString): PDX11BufferVariable;
var
 Index: Integer;
begin
 Index:= IndexOf(Name);

 if (Index <> -1) then
  Result:= @Data[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX11BufferVariables.Declare(const Name: StdString; AByteAddress,
 ASizeInBytes: Integer);
var
 Index: Integer;
begin
 Index:= IndexOf(Name);

 if (Index = -1) then
  begin
   Index:= Length(Data);
   SetLength(Data, Index + 1);

   DataDirty:= True;
  end;

 Data[Index].VariableName:= Name;

 Data[Index].ByteAddress:= AByteAddress;
 Data[Index].SizeInBytes:= ASizeInBytes;
end;

//---------------------------------------------------------------------------
constructor TDX11ConstantBuffer.Create(const AName: StdString);
begin
 inherited Create();

 FName:= AName;
 FInitialized:= False;

 FVariables:= TDX11BufferVariables.Create();

 FBufferType:= cbtUnknown;
 FBufferSize:= 0;

 FConstantIndex:= 0;
end;

//---------------------------------------------------------------------------
destructor TDX11ConstantBuffer.Destroy();
begin
 if (FInitialized) then Finalize();

 FreeAndNil(FVariables);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX11ConstantBuffer.SetBufferType(
 Value: TDX11ConstantBufferType);
begin
 if (not FInitialized) then FBufferType:= Value;
end;

//---------------------------------------------------------------------------
procedure TDX11ConstantBuffer.SetBufferSize(Value: Integer);
begin
 if (not FInitialized) then FBufferSize:= Value;
end;

//---------------------------------------------------------------------------
procedure TDX11ConstantBuffer.SetConstantIndex(Value: Integer);
begin
 FConstantIndex:= Max2(Value, 0);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.Initialize(): Boolean;
var
 Desc: D3D11_BUFFER_DESC;
begin
 Result:= (Assigned(D3D11Device))and(not FInitialized)and
  (FBufferType <> cbtUnknown)and(FBufferSize > 0);
 if (not Result) then Exit;

 FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);

 Desc.ByteWidth:= FBufferSize;
 Desc.Usage:= D3D11_USAGE_DYNAMIC;
 Desc.BindFlags:= Cardinal(D3D11_BIND_CONSTANT_BUFFER);
 Desc.CPUAccessFlags:= Cardinal(D3D11_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateBuffer(Desc, nil, FVideoBuffer));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 FSystemBuffer:= AllocMem(FBufferSize);

 FInitialized:= True;
end;

//---------------------------------------------------------------------------
procedure TDX11ConstantBuffer.Finalize();
begin
 if (not FInitialized) then Exit;

 if (Assigned(FSystemBuffer)) then FreeNullMem(FSystemBuffer);

 if (Assigned(FVideoBuffer)) then FVideoBuffer:= nil;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.Update(): Boolean;
var
 Mapped: D3D11_MAPPED_SUBRESOURCE;
begin
 Result:= (FInitialized)and(Assigned(FSystemBuffer))and
  (Assigned(FVideoBuffer))and(Assigned(D3D11Context));
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Context.Map(FVideoBuffer, 0, D3D11_MAP_WRITE_DISCARD,
   0, Mapped));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 Move(FSystemBuffer^, Mapped.pData^, FBufferSize);

 PushClearFPUState();
 try
  D3D11Context.Unmap(FVideoBuffer, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.Bind(): Boolean;
begin
 Result:= (FInitialized)and(FConstantIndex >= 0)and
  (FBufferType <> cbtUnknown)and(Assigned(FVideoBuffer))and
  (Assigned(D3D11Context));
 if (not Result) then Exit;

 PushClearFPUState();
 try
  case FBufferType of
   cbtVertex:
    D3D11Context.VSSetConstantBuffers(FConstantIndex, 1, @FVideoBuffer);

   cbtPixel:
    D3D11Context.PSSetConstantBuffers(FConstantIndex, 1, @FVideoBuffer);
  end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.UpdateVariable(
 const Variable: TDX11BufferVariable; Content: Pointer; ByteOffset,
  ByteCount: Integer): Boolean;
var
 MinBytes: Integer;
 WritePtr: Pointer;
begin
 Result:= False;
 if (not Assigned(Content)) then Exit;

 if (ByteOffset > 0)and(Variable.SizeInBytes <= ByteOffset) then Exit;

 MinBytes:= Min2(ByteCount, Variable.SizeInBytes - ByteOffset);
 if (MinBytes < 1) then Exit;

 WritePtr:= Pointer(PtrInt(FSystemBuffer) + Variable.ByteAddress + ByteOffset);

 Move(Content^, WritePtr^, MinBytes);

 Result:= True;
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetBasicVariable(const VariableName: string;
 Content: Pointer; ContentSize, SubIndex: Integer): Boolean;
var
 Variable: PDX11BufferVariable;
begin
 Result:= False;

 Variable:= FVariables[VariableName];
 if (not Assigned(Variable)) then Exit;

 Result:= UpdateVariable(Variable^, Content, SubIndex * ContentSize,
  ContentSize);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetInt(const VariableName: StdString;
 Value: LongInt; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(LongInt), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetUInt(const VariableName: StdString;
 Value: LongWord; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(LongWord), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetFloat(const VariableName: StdString;
 Value: Single; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(Single), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetPoint2(const VariableName: StdString;
 const Value: TPoint2; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(TPoint2), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetVector3(const VariableName: StdString;
 const Value: TVector3; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(TVector3), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetVector4(const VariableName: StdString;
 const Value: TVector4; SubIndex: Integer): Boolean;
begin
 Result:= SetBasicVariable(VariableName, @Value, SizeOf(TVector4), SubIndex);
end;

//---------------------------------------------------------------------------
function TDX11ConstantBuffer.SetMatrix4(const VariableName: StdString;
 const Value: TMatrix4; SubIndex: Integer): Boolean;
var
 Aux: TMatrix4;
begin
 Aux:= TransposeMtx4(Value);

 Result:= SetBasicVariable(VariableName, @Aux, SizeOf(TMatrix4), SubIndex);
end;

//---------------------------------------------------------------------------
constructor TDX11ShaderEffect.Create();
begin
 inherited;

 FInitialized:= False;
 ConstantBuffersDirty:= False;

 BinaryVS:= nil;
 BinaryPS:= nil;
end;

//---------------------------------------------------------------------------
destructor TDX11ShaderEffect.Destroy();
begin
 RemoveAllConstantBuffers();

 if (FInitialized) then Finalize();

 if (Assigned(BinaryPS)) then
  begin
   FreeNullMem(BinaryPS);
   BinaryPSLength:= 0;
  end;

 if (Assigned(BinaryVS)) then
  begin
   FreeNullMem(BinaryVS);
   BinaryVSLength:= 0;
  end;

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.RemoveAllConstantBuffers();
var
 i: Integer;
begin
 for i:= Length(ConstantBuffers) - 1 downto 0 do
  if (Assigned(ConstantBuffers[i])) then
   FreeAndNil(ConstantBuffers[i]);

 SetLength(ConstantBuffers, 0);
 ConstantBuffersDirty:= False;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.ConstantBufferSwap(Index1, Index2: Integer);
var
 Aux: TDX11ConstantBuffer;
begin
 Aux:= ConstantBuffers[Index1];

 ConstantBuffers[Index1]:= ConstantBuffers[Index2];
 ConstantBuffers[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.ConstantBufferCompare(const Item1,
 Item2: TDX11ConstantBuffer): Integer;
begin
 Result:= CompareText(Item1.Name, Item2.Name);
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.ConstantBufferSplit(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: TDX11ConstantBuffer;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= ConstantBuffers[Start];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(ConstantBufferCompare(ConstantBuffers[Left],
    Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(ConstantBufferCompare(ConstantBuffers[Right],
    Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then ConstantBufferSwap(Left, Right);
  end;

 ConstantBufferSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.ConstantBufferSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= ConstantBufferSplit(Start, Stop);

   ConstantBufferSort(Start, SplitPt - 1);
   ConstantBufferSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.OrderConstantBuffers();
begin
 if (Length(ConstantBuffers) > 1) then
  ConstantBufferSort(0, Length(ConstantBuffers) - 1);

 ConstantBuffersDirty:= False;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.IndexOfConstantBuffer(
 const Name: StdString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (ConstantBuffersDirty) then OrderConstantBuffers();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(ConstantBuffers) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= CompareText(ConstantBuffers[Mid].Name, Name);

   if (Res = 0) then
    begin
     Result:= Mid;
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.GetConstantBuffer(
 const Name: StdString): TDX11ConstantBuffer;
var
 Index: Integer;
begin
 Index:= IndexOfConstantBuffer(Name);

 if (Index <> -1) then
  Result:= ConstantBuffers[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.AddConstantBuffer(const AName: StdString;
 ABufferType: TDX11ConstantBufferType; ABufferSize,
 AConstantIndex: Integer): TDX11ConstantBuffer;
var
 Index: Integer;
begin
 Result:= nil;
 if (AName = '') then Exit;

 Index:= IndexOfConstantBuffer(AName);
 if (Index <> -1) then Exit;

 Result:= TDX11ConstantBuffer.Create(AName);
 Result.BufferType:= ABufferType;
 Result.BufferSize:= ABufferSize;
 Result.ConstantIndex:= AConstantIndex;

 if (not Result.Initialize()) then
  begin
   FreeAndNil(Result);
   Exit;
  end;

 Index:= Length(ConstantBuffers);
 SetLength(ConstantBuffers, Index + 1);

 ConstantBuffers[Index]:= Result;
 ConstantBuffersDirty:= True;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.UpdateBindAllBuffers(): Boolean;
var
 i: Integer;
begin
 Result:= False;

 for i:= 0 to Length(ConstantBuffers) - 1 do
  if (Assigned(ConstantBuffers[i]))and(ConstantBuffers[i].Initialized) then
   begin
    Result:= ConstantBuffers[i].Update();
    if (not Result) then Break;

    Result:= ConstantBuffers[i].Bind();
    if (not Result) then Break;
   end;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.SetVertexLayout(Content: PD3D11_INPUT_ELEMENT_DESC;
 ElementCount: Integer): Boolean;
var
 i: Integer;
 Source: PD3D11_INPUT_ELEMENT_DESC;
begin
 Result:= (not FInitialized)and(Assigned(Content))and(ElementCount > 0);
 if (not Result) then Exit;

 Source:= Content;

 SetLength(VertexLayoutDesc, ElementCount);

 for i:= 0 to Length(VertexLayoutDesc) - 1 do
  begin
   Move(Source^, VertexLayoutDesc[i], SizeOf(D3D11_INPUT_ELEMENT_DESC));
   Inc(Source);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.SetShaderCodes(AVertexShader: Pointer;
 AVertexShaderLength: Integer; APixelShader: Pointer;
 APixelShaderLength: Integer);
begin
 if (Assigned(AVertexShader))and(AVertexShaderLength > 0) then
  begin
   BinaryVSLength:= AVertexShaderLength;

   ReallocMem(BinaryVS, BinaryVSLength);
   Move(AVertexShader^, BinaryVS^, BinaryVSLength);
  end else
  begin
   if (Assigned(BinaryVS)) then
    begin
     FreeNullMem(BinaryVS);
     BinaryVSLength:= 0;
    end;
  end;

 if (Assigned(APixelShader))and(APixelShaderLength > 0) then
  begin
   BinaryPSLength:= APixelShaderLength;

   ReallocMem(BinaryPS, BinaryPSLength);
   Move(APixelShader^, BinaryPS^, BinaryPSLength);
  end else
  begin
   if (Assigned(BinaryPS)) then
    begin
     FreeNullMem(BinaryPS);
     BinaryPSLength:= 0;
    end;
  end;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.Initialize(): Boolean;
begin
 Result:= (not FInitialized)and(Length(VertexLayoutDesc) > 0)and
  (Assigned(BinaryVS))and(Assigned(BinaryPS))and(Assigned(D3D11Device));
 if (not Result) then Exit;

 // Load binary Vertex Shader.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateVertexShader(BinaryVS, BinaryVSLength,
   nil, FVertexShader));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 // Create VS-compatible Vertex Layout.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateInputLayout(@VertexLayoutDesc[0],
   Length(VertexLayoutDesc), BinaryVS, BinaryVSLength, FInputLayout));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   FVertexShader:= nil;
   Exit;
  end;

 // Create binary Pixel Shader.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreatePixelShader(BinaryPS, BinaryPSLength,
   nil, FPixelShader));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   FInputLayout:= nil;
   FVertexShader:= nil;
   Exit;
  end;

 FInitialized:= True;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.Finalize();
begin
 if (not FInitialized) then Exit;

 if (Assigned(FPixelShader)) then FPixelShader:= nil;
 if (Assigned(FInputLayout)) then FInputLayout:= nil;
 if (Assigned(FVertexShader)) then FVertexShader:= nil;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TDX11ShaderEffect.Activate(): Boolean;
begin
 Result:= (FInitialized)and(Assigned(D3D11Context))and
  (Assigned(FVertexShader))and(Assigned(FInputLayout))and
  (Assigned(FPixelShader));
 if (not Result) then Exit;

 PushClearFPUState();
 try
  D3D11Context.IASetInputLayout(FInputLayout);
  D3D11Context.VSSetShader(FVertexShader, nil, 0);
  D3D11Context.PSSetShader(FPixelShader, nil, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11ShaderEffect.Deactivate();
begin
 if (FInitialized)and(Assigned(D3D11Context)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.PSSetShader(nil, nil, 0);
    D3D11Context.VSSetShader(nil, nil, 0);
    D3D11Context.IASetInputLayout(nil);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
end.
