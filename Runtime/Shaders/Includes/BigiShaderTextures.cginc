#ifndef BIGI_SHADER_TEXTURES_INCL
#define BIGI_SHADER_TEXTURES_INCL
#include <HLSLSupport.cginc>
#ifndef BIGI_SHADER_TEXTURES_H
#define BIGI_SHADER_TEXTURES_H
#ifndef MULTI_TEXTURE
    UNITY_DECLARE_TEX2D(_MainTex);
    float4 _MainTex_ST;
    #define GET_TEX_COLOR(uv) UNITY_SAMPLE_TEX2D(_MainTex, uv)
    #define GET_MASK_COLOR(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_Mask, _MainTex, uv)
    #define GET_AO(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, uv)
    #define GET_NORMAL(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv)

    #define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTex)

#else
    UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
    float4 _MainTexArray_ST;
    #ifndef OTHER_TEXTURE_ID_REF
    uniform int _OtherTextureId;
    #define OTHER_TEXTURE_ID_REF _OtherTextureId
    #endif
    #define GET_TEX_COLOR(uv) UNITY_SAMPLE_TEX2DARRAY(_MainTexArray, float3(uv,OTHER_TEXTURE_ID_REF))
    #define GET_MASK_COLOR(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_Mask, _MainTexArray, uv)
    #define GET_AO(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTexArray, uv)
    #define GET_NORMAL(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTexArray, uv)

    #define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTexArray)

#endif

#ifndef PROTV_TEXTURES_INCLUDED
#define PROTV_TEXTURES_INCLUDED
//ProTV Textures
UNITY_DECLARE_TEX2D(_Udon_VideoTex);
float4 _Udon_VideoTex_TexelSize;
float4 _Udon_VideoTex_ST;
#endif


#ifndef OTHER_BIGI_TEXTURES
#define OTHER_BIGI_TEXTURES

UNITY_DECLARE_TEX2D_NOSAMPLER(_Mask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
UNITY_DECLARE_TEX2D(_Spacey);
float4 _Spacey_ST;
#endif
#endif
#endif
