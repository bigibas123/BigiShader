#ifndef BIGI_SHADER_TEXTURES_INCL
#define BIGI_SHADER_TEXTURES_INCL
#include <HLSLSupport.cginc>
#ifndef BIGI_SHADER_TEXTURES_H
#define BIGI_SHADER_TEXTURES_H
#ifndef MULTI_TEXTURE
UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
#define BIGI_MAIN_SAMPLERTEX_NAME _MainTex
#define BIGI_TEX_SAMPLE_FUNC(uv) UNITY_SAMPLE_TEX2D(BIGI_MAIN_SAMPLERTEX_NAME,uv)

#else
    UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
    float4 _MainTexArray_ST;
    #define BIGI_MAIN_SAMPLERTEX_NAME _MainTexArray
#ifndef OTHER_TEXTURE_ID_REF
    uniform int _OtherTextureId;
    #define OTHER_TEXTURE_ID_REF _OtherTextureId
#endif
    #define BIGI_TEX_SAMPLE_FUNC(uv) UNITY_SAMPLE_TEX2DARRAY(BIGI_MAIN_SAMPLERTEX_NAME,float3(uv,OTHER_TEXTURE_ID_REF))

#endif

#define GET_TEX_COLOR_REAL(uv) BIGI_TEX_SAMPLE_FUNC(uv)

#ifndef PROTV_SQUARE_ENABLED
#define GET_TEX_COLOR(uv) GET_TEX_COLOR_REAL(uv)
#else
#define GET_TEX_COLOR(uv) b_protv_util::getTexColor(uv)
#endif

#define GET_MASK_COLOR(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_Mask, BIGI_MAIN_SAMPLERTEX_NAME, uv)

#if defined(AMBIENT_OCCLUSION_ENABLED)
    #define GET_AO(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, BIGI_MAIN_SAMPLERTEX_NAME, uv).g
#else
#define GET_AO(uv) 1.0
#endif

#define GET_NORMAL(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, BIGI_MAIN_SAMPLERTEX_NAME, uv)

#if defined(SPECSMOOTH_MAP_ENABLED)
    #define GET_SPEC_SMOOTH(uv) UNITY_SAMPLE_TEX2D_SAMPLER(_SpecSmoothMap, BIGI_MAIN_SAMPLERTEX_NAME, uv) * half4(_SpecularIntensity, _SpecularIntensity, _SpecularIntensity, _Smoothness)
#else
#define GET_SPEC_SMOOTH(uv) half4(_SpecularIntensity, _SpecularIntensity, _SpecularIntensity, _Smoothness)
#endif

#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, BIGI_MAIN_SAMPLERTEX_NAME)

#ifndef OTHER_BIGI_TEXTURES
#define OTHER_BIGI_TEXTURES

UNITY_DECLARE_TEX2D_NOSAMPLER(_Mask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
UNITY_DECLARE_TEX2D(_Spacey);
UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecSmoothMap);
float4 _Spacey_ST;
#endif
#endif
#endif
