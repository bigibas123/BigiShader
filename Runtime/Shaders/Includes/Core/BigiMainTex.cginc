#ifndef BIGI_MAINTEX_H
#define BIGI_MAINTEX_H
#ifndef NO_MAINTEX
#ifndef MULTI_TEXTURE

	#ifndef GET_TEX_COLOR_MAINTEX
	#include <HLSLSupport.cginc>
		#ifndef MAINTEX_NAME
			#define MAINTEX_NAME _MainTex
			UNITY_DECLARE_TEX2D(MAINTEX_NAME);
		float4 _MainTex_ST;
		#endif
	#define GET_TEX_COLOR_MAINTEX(uv) UNITY_SAMPLE_TEX2D(MAINTEX_NAME,uv)
	#endif

#else

	#ifndef GET_TEX_COLOR_MAINTEX
	#include <HLSLSupport.cginc>
		#ifndef OTHER_TEXTURE_ID_REF
			uniform int _OtherTextureId;
			#define OTHER_TEXTURE_ID_REF _OtherTextureId
		#endif
		#ifndef MAINTEX_NAME
			#define MAINTEX_NAME _MainTexArray
			UNITY_DECLARE_TEX2DARRAY(MAINTEX_NAME);
			float4 _MainTexArray_ST;
		#endif

		#define GET_TEX_COLOR_MAINTEX(uv) UNITY_SAMPLE_TEX2DARRAY(_MainTexArray,float3(uv,OTHER_TEXTURE_ID_REF))
	#endif

#endif
#endif

#ifdef MAINTEX_NAME
	#ifndef SAMPLE_TEX2D
	#include <HLSLSupport.cginc>
	#define SAMPLE_TEX2D(texName,uv) UNITY_SAMPLE_TEX2D_SAMPLER(texName, MAINTEX_NAME, uv)
	#endif

	#ifndef DO_TRANSFORM
	#include <UnityCG.cginc>
	#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, MAINTEX_NAME)
	#endif

#else
	#ifndef DO_TRANSFORM
	#define DO_TRANSFORM(tc) (tc)
	#endif
#endif

#define DECAL_PARAMS(num) \
	UNITY_DECLARE_TEX2D(_Decal##num); \
	float4 _Decal##num##_ST; \
	namespace b_decal { float4 GetTexColorDecal##num(const in float2 uv){return UNITY_SAMPLE_TEX2D(_Decal##num,uv);} }\
	uniform uint _Decal##num##_BlendMode;\
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
