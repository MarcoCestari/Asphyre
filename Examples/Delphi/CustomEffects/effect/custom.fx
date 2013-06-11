//--------------------------------------------------------------------------------------
// Texture and Sampler parameters.
//--------------------------------------------------------------------------------------
Texture2D SourceTex;

//--------------------------------------------------------------------------------------
float2 TexSize;
float SmoothAlpha;
float SmoothDistance;

//--------------------------------------------------------------------------------------
SamplerState MipmapSampler
{
  Filter = MIN_MAG_MIP_LINEAR;
  AddressU = Clamp;
  AddressV = Clamp;
};

//--------------------------------------------------------------------------------------
SamplerState PointSampler
{
  Filter = MIN_MAG_MIP_POINT;
  AddressU = Clamp;
  AddressV = Clamp;
};

//--------------------------------------------------------------------------------------
// Output of Vertex Shader, Input for Pixel Shader
//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Color: COLOR0;
  float2 TexAt: TEXCOORD0;
  float4 PosAt: SV_POSITION;
};

//---------------------------------------------------------------------------
// Vertex Shader
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
float4 SampleAt(float2 PosAt)
{
  float2 NewPos = PosAt / TexSize;

  return SourceTex.Sample(MipmapSampler, NewPos);
}

//---------------------------------------------------------------------------
float BrakeTheta(float Theta)
{
  return sin(Theta * 3.14 * 0.5);
}

//---------------------------------------------------------------------------
// PS: Glow Effect
//---------------------------------------------------------------------------
float4 Glow_PS(VS_OUTPUT Inp): SV_Target
{
  float2 OrigPos = Inp.TexAt * TexSize;

  float4 BloomCol = 0.0;

  for (int j = 0; j < 5; j++)
   for (int i = 0; i < 5; i++)
   {
     BloomCol += SampleAt(float2(OrigPos.x + (i - 2), OrigPos.y + (j - 2)));
   }

  BloomCol = BloomCol / (25.0 / 1.25);

  float Theta = (BloomCol.x + BloomCol.y + BloomCol.z) / 3;
  BloomCol.w = BloomCol.w * BrakeTheta(Theta);

  float4 TexCol = SourceTex.Sample(MipmapSampler, Inp.TexAt);
  TexCol = max(TexCol, BloomCol);

  return TexCol * Inp.Color;
}

//---------------------------------------------------------------------------
// PS: Blur Effect
//---------------------------------------------------------------------------
float4 Blur_PS(VS_OUTPUT Inp): SV_Target
{
  float2 OrigPos = Inp.TexAt * TexSize;

  float4 SmoothCol = 0.0;

  for (int j = 0; j < 5; j++)
   for (int i = 0; i < 5; i++)
   {
     SmoothCol += SampleAt(float2(OrigPos.x + (i - 2) * SmoothDistance,
      OrigPos.y + (j - 2) * SmoothDistance));
   }

  SmoothCol /= 25.0;

  float4 TexCol = SourceTex.Sample(MipmapSampler, Inp.TexAt);

  TexCol = (TexCol * (1.0 - SmoothAlpha)) + (SmoothCol * SmoothAlpha);

  return TexCol * Inp.Color;
}

//---------------------------------------------------------------------------
// Glow Technique
//---------------------------------------------------------------------------
technique10 GlowTechnique
{
  pass P0
  {
    SetVertexShader(CompileShader(vs_4_0, Custom_VS()));
    SetGeometryShader(NULL);
    SetPixelShader(CompileShader(ps_4_0, Glow_PS()));
  }
}

//---------------------------------------------------------------------------
// Blur Technique
//---------------------------------------------------------------------------
technique10 BlurTechnique
{
  pass P0
  {
    SetVertexShader(CompileShader(vs_4_0, Custom_VS()));
    SetGeometryShader(NULL);
    SetPixelShader(CompileShader(ps_4_0, Blur_PS()));
  }
}