#ifndef BIGI_GETCOLOR_H
#define BIGI_GETCOLOR_H

#ifndef GET_TEX_COLOR
		#include "./BigiTextureCreation.cginc"
		#define GET_TEX_COLOR(uv) bigi_texture::GetTexColor(uv)
#endif

#ifdef SAMPLE_TEX2D
#ifndef GET_MASK_COLOR
	#ifndef UNITY_STANDARD_INPUT_INCLUDED
		#include <HLSLSupport.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Mask);
	#else
		sampler2D _Mask;
	#endif
	float4 _Mask_ST;
	#define GET_MASK_COLOR(uv) SAMPLE_TEX2D(_Mask, TRANSFORM_TEX(uv,_Mask))
#endif

#ifndef GET_AO
	#ifndef UNITY_STANDARD_INPUT_INCLUDED
		#include <HLSLSupport.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
	#endif
	#include "./BigiMainTex.cginc"
	#define GET_AO(uv) (SAMPLE_TEX2D(_OcclusionMap,uv).g)
#endif

#ifndef GET_NORMAL
	#ifndef NORMAL_SCALE_VAR
		#ifndef UNITY_STANDARD_INPUT_INCLUDED
		uniform half _BumpScale;
		#endif
		#define NORMAL_SCALE_VAR (_BumpScale)
	#endif
	#ifdef NORMAL_MAPPING
		#include <HLSLSupport.cginc>
		#include <UnityCG.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
		float4 _BumpMap_ST;
		#include "./BigiMainTex.cginc"
		#define GET_NORMAL(uv) (SAMPLE_TEX2D(_BumpMap, TRANSFORM_TEX(uv,_BumpMap)) * NORMAL_SCALE_VAR)
	#endif
#endif


#ifndef GET_2NDNORMAL
	#ifndef NORMAL_2ND_SCALE_VAR
		uniform half _Bump2ndScale;
		#define NORMAL_2ND_SCALE_VAR (_Bump2ndScale)
	#endif
	#ifdef NORMAL_2ND_MAPPING
		#include <HLSLSupport.cginc>
		#include <UnityCG.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Bump2ndMap);
		float4 _Bump2ndMap_ST;
		#define GET_2NDNORMAL(uv) (SAMPLE_TEX2D(_Bump2ndMap, TRANSFORM_TEX(uv,_Bump2ndMap)) * NORMAL_2ND_SCALE_VAR)
	#endif
#endif

#ifndef GET_SPEC_GLOSS
	#include "./BigiShaderParams.cginc"
	#ifndef UNITY_STANDARD_INPUT_INCLUDED
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecGlossMap);
	#endif
	float4 _SpecGlossMap_ST;
	#include "./BigiMainTex.cginc"
	#define GET_SPEC_GLOSS(uv) (SAMPLE_TEX2D(_SpecGlossMap, TRANSFORM_TEX(uv,_SpecGlossMap)))
#endif

#else

#ifndef GET_AO
	#define GET_AO(uv) 1.0
#endif

#ifndef GET_SPEC_GLOSS
	#define GET_SPEC_GLOSS(uv) (half4(0, 0, 0, 0))
#endif

#endif

#ifndef GET_SPACEY
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2D(_Spacey);
	float4 _Spacey_ST;
	#include <UnityCG.cginc>
	#define GET_SPACEY(uv) UNITY_SAMPLE_TEX2D(_Spacey, TRANSFORM_TEX((uv.xy / uv.w), _Spacey))
#endif

#endif
