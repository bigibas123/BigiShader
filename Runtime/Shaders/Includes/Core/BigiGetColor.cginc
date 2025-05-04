#ifndef BIGI_GETCOLOR_H
#define BIGI_GETCOLOR_H

#ifndef GET_TEX_COLOR
	#ifndef PROTV_SQUARE_ENABLED
		#include "./BigiTextureCreation.cginc"
		#define GET_TEX_COLOR(uv) bigi_texture::GetTexColor(uv)
	#else
		#include "../External/ProTV/BigiProTV.cginc"
		#define GET_TEX_COLOR(uv) b_protv_util::getTexColor(uv)
	#endif
#endif

#ifdef SAMPLE_TEX2D
#ifndef GET_MASK_COLOR
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Mask);
	float4 _Mask_ST;
	#define GET_MASK_COLOR(uv) SAMPLE_TEX2D(_Mask, uv)
#endif

#ifndef GET_AO
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
	#include "./BigiMainTex.cginc"
	#define GET_AO(uv) SAMPLE_TEX2D(_OcclusionMap, uv).g
#endif

#ifndef GET_NORMAL
	#ifdef NORMAL_MAPPING
		#include <HLSLSupport.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
		#include "./BigiMainTex.cginc"
		#define GET_NORMAL(uv) SAMPLE_TEX2D(_BumpMap, uv)
	#else
		#define GET_NORMAL(uv) #error "Trying to get normal while normal mapping is disabled"
	#endif
#endif

#ifndef GET_SPEC_SMOOTH
	#include "./BigiShaderParams.cginc"
	#ifdef SPECSMOOTH_MAP_ENABLED
		#include <HLSLSupport.cginc>
		UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecSmoothMap);
		#include "./BigiMainTex.cginc"
		#define GET_SPEC_SMOOTH(uv) (SAMPLE_TEX2D(_SpecSmoothMap, uv))
	#else
		#define GET_SPEC_SMOOTH(uv) (half4(0, 0, 0, 0))
	#endif
#endif

#else

#ifndef GET_AO
	#define GET_AO(uv) 1.0
#endif

#ifndef GET_SPEC_SMOOTH
	#define GET_SPEC_SMOOTH(uv) (half4(0, 0, 0, 0))
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
