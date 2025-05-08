#ifndef BIGI_PROTV_H
#define BIGI_PROTV_H

#if !defined(SHADER_API_D3D11)
uniform sampler2D _Udon_VideoTex;
float4 _Udon_VideoTex_TexelSize;
float4 _Udon_VideoTex_ST;
#define PROTV_PRESENT_REAL(outVar) bool outVar = (_Udon_VideoTex_TexelSize.z > 16)
#define GET_PROTV_REAL(uv) tex2D(_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex))
#else
UNITY_DECLARE_TEX2D(_Udon_VideoTex);
float4 _Udon_VideoTex_ST;
#define PROTV_PRESENT_REAL(outVar) int videoWidth; int videoHeight; _Udon_VideoTex.GetDimensions(videoWidth, videoHeight); bool outVar = (videoWidth > 16)
#define GET_PROTV_REAL(uv) _Udon_VideoTex.Sample(sampler_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex))
#endif

#ifdef PROTV_SQUARE_ENABLED
#include "../../Core/BigiTextureCreation.cginc"
#include "../../Core/BigiShaderParams.cginc"

#define GET_PROTV(uv) GET_PROTV_REAL(uv)
#define PROTV_PRESENT(outVar) PROTV_PRESENT_REAL(outVar)

#else

#define GET_PROTV(uv) float4(0.0,0.0,0.0,0.0)
#define PROTV_PRESENT(outVar) const bool outVar = false

#endif
namespace b_protv_util
{
    float4 getTexColor(float2 uv)
    {
        return GET_PROTV(uv);
    }
}
#endif
