#ifndef BIGI_MAINTEX_H
#define BIGI_MAINTEX_H

#ifndef MULTI_TEXTURE
	#ifndef MAINTEX_DECLARED
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2D(_MainTex);
	float4 _MainTex_ST;
	#define MAINTEX_DECLARED
	#endif

	#ifndef GET_TEX_COLOR_MAINTEX
	#include <HLSLSupport.cginc>
	#define GET_TEX_COLOR_MAINTEX(uv) UNITY_SAMPLE_TEX2D(_MainTex,uv)
	#endif

	#ifndef SAMPLE_TEX2D
	#include <HLSLSupport.cginc>
	#define SAMPLE_TEX2D(texName,uv) UNITY_SAMPLE_TEX2D_SAMPLER(texName, _MainTex, uv)
	#endif

	#ifndef DO_TRANSFORM
	#include <UnityCG.cginc>
	#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTex)
	#endif

#else
	#ifndef MAINTEX_DECLARED
	#include <HLSLSupport.cginc>
	UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
	float4 _MainTexArray_ST;
	#define MAINTEX_DECLARED
	#endif

	#ifndef OTHER_TEXTURE_ID_REF
		uniform int _OtherTextureId;
		#define OTHER_TEXTURE_ID_REF _OtherTextureId
	#endif

	#ifndef GET_TEX_COLOR_MAINTEX
	#include <HLSLSupport.cginc>
	#define GET_TEX_COLOR_MAINTEX(uv) UNITY_SAMPLE_TEX2DARRAY(_MainTexArray,float3(uv,OTHER_TEXTURE_ID_REF))
	#endif

	#ifndef SAMPLE_TEX2D
	#include <HLSLSupport.cginc>
	#define SAMPLE_TEX2D(texName,uv) UNITY_SAMPLE_TEX2D_SAMPLER(texName, _MainTexArray, uv)
	#endif

	#ifndef DO_TRANSFORM
	#include <UnityCG.cginc>
	#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTexArray)
	#endif

#endif

#define DECAL_PARAMS(num) \
	UNITY_DECLARE_TEX2D(_Decal##num); \
	float4 _Decal##num##_ST; \
	namespace b_decal { float4 GetTexColorDecal##num(const in float2 uv){return UNITY_SAMPLE_TEX2D(_Decal##num,uv);} }\
	uniform float _Decal##num##_Opacity; \
	uniform float4 _Decal##num##_Position; \

#ifdef DECAL_1_ENABLED
DECAL_PARAMS(1)
#endif
#ifdef DECAL_2_ENABLED
DECAL_PARAMS(2)
#endif
#ifdef DECAL_3_ENABLED
DECAL_PARAMS(3)
#endif

#endif
