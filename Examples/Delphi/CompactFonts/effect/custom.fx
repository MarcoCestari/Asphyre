//--------------------------------------------------------------------------------------
// This is the texture that will be used in the shaders.
//--------------------------------------------------------------------------------------
Texture2D SourceTex;

//--------------------------------------------------------------------------------------
SamplerState PointSampler
{
  Filter = MIN_MAG_MIP_POINT;
  AddressU = Clamp;
  AddressV = Clamp;
};

//--------------------------------------------------------------------------------------
// Output of Vertex Shader, Input for Pixel Shader.
//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Color: COLOR0;
  float2 TexAt: TEXCOORD0;
  float4 PosAt: SV_POSITION;
};

//---------------------------------------------------------------------------
// Standard Vertex Shader.
//---------------------------------------------------------------------------
VS_OUTPUT Custom_VS(float2 Pos: POSITION, float4 Color: COLOR,
 float2 TexAt: TEXCOORD)
{
  VS_OUTPUT Res = (VS_OUTPUT)0;

  Res.PosAt = float4(Pos, 0.0, 1.0);
  Res.Color = Color;
  Res.TexAt = TexAt;

  return Res;
}

//---------------------------------------------------------------------------
// This function is similar to Sample() or SampleLevel() in HLSL, but it
// interprets properly A5L3 pixel format. The texture format set by Asphyre
// is usually DXGI_FORMAT_R8_UNORM in this case.
//---------------------------------------------------------------------------
float4 SampleA5L3(float2 TexAt)
{
  int TexVal = SourceTex.SampleLevel(PointSampler, TexAt, 0).x * 255.0;

  float Lum   = (TexVal & 0x07) / 7.0;
  float Alpha = (TexVal >> 3) / 15.0;

  return float4(Lum, Lum, Lum, Alpha);
}

//---------------------------------------------------------------------------
// Compact Font Pixel Shader.
//---------------------------------------------------------------------------
float4 CustomA6L2_PS(VS_OUTPUT Inp): SV_Target
{
  return SampleA5L3(Inp.TexAt) * Inp.Color;
}

//--------------------------------------------------------------------------------------
// Compact Font rendering technique.
//--------------------------------------------------------------------------------------
technique10 CompactFontTech
{
  pass P0
  {
    SetVertexShader(CompileShader(vs_4_0, Custom_VS()));
    SetGeometryShader(NULL);
    SetPixelShader(CompileShader(ps_4_0, CustomA6L2_PS()));
  }
}