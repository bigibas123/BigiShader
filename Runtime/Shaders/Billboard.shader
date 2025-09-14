Shader "Bigi/Billboard" {
	Properties {
		_MainTexArray ("Other textures", 2DArray) = "" {}
		_TextureId ("Other texture Id", Int) = 0
		[Toggle(ALPHA_MUL)] _Alpha_Multiply("Multiply alpha with itself", Float) = 1
		[Toggle(DO_HOVER)] _Hover("Hover up and down",Float) = 1.0
	}

	SubShader {
		Tags {
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"DisableBatching" = "False"
		}

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		CGINCLUDE
		#include <UnityCG.cginc>
		#include <HLSLSupport.cginc>

		UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
		CBUFFER_START(UnityPerMaterial)
		float4 _MainTexArray_ST;
		uniform int _TextureId;
		CBUFFER_END
		#ifndef BIGI_OTHER_TEXTURE_ID_DEFINED
		#define BIGI_OTHER_TEXTURE_ID_DEFINED
		#define OTHER_TEXTURE_ID_REF _TextureId
		#endif
		#define GET_TEX_COLOR(uv) UNITY_SAMPLE_TEX2DARRAY(_MainTexArray, float3(uv, OTHER_TEXTURE_ID_REF))

		#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTexArray)


		#define BIGI_SHADER_PARAMS
		#define BIGI_DEFAULT_APPDATA_DEFINED
		#define BIGI_DEFAULT_V2F_DEFINED

		#include "./Includes/Effects/SoundUtilsDefines.cginc"

		struct appdata
		{
			float4 pos : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		v2f vert(appdata v)
		{
			v2f o;
			#ifdef DO_HOVER
			float4 _OffsetAndScale = float4(0.0, sin(_Time.y) * 0.05, 0.0, 1.0);
			#else
			float4 _OffsetAndScale = float4(0.0, 0.0, 0.0, 1.0);
			#endif

			float3 scale = float3(
				length(unity_ObjectToWorld._m00_m10_m20),
				length(unity_ObjectToWorld._m01_m11_m21),
				length(unity_ObjectToWorld._m02_m12_m22)
			);

			float4 outPos = mul(UNITY_MATRIX_P,
							mul(UNITY_MATRIX_MV, float4(_OffsetAndScale))
							+ float4(v.pos.x, v.pos.y, 0.0, 0.0)
							* float4(scale.x, scale.y, 0.0, 0.0)
			);

			o.pos = outPos;

			UNITY_TRANSFER_FOG(o, o.vertex);

			o.uv = DO_TRANSFORM(v.uv);

			return o;
		}
		ENDCG

		Pass {
			Name "Depth pass"
			Tags {
				"Queue" = "Geometry"
			}
			Stencil {
				Ref 148
				Comp Always
				Pass Replace
				Fail Keep
			}
			ColorMask 0
			Cull Back
			ZWrite On
			ZTest Less
			CGPROGRAM
			#pragma shader_feature_local_fragment ALPHA_MUL
			#pragma shader_feature_local_vertex DO_HOVER
			#pragma vertex vert
			#pragma fragment frag
			#include "./Includes/Epsilon.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				half4 orig_color = GET_TEX_COLOR(i.uv);
				clip(orig_color.a - (1.0 - Epsilon));
				return orig_color;
			}
			ENDCG
		}

		Pass {
			Name "Forward Base Main"
			Stencil {
				Ref 148
				Comp Always
				Pass Replace
				Fail Keep
			}
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma shader_feature_local_fragment ALPHA_MUL
			#pragma shader_feature_local_vertex DO_HOVER
			#pragma vertex vert
			#pragma fragment frag
			#include "./Includes/Epsilon.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				half4 orig_color = GET_TEX_COLOR(i.uv);
				#ifdef ALPHA_MUL
				orig_color.a *= orig_color.a;
				#endif
				clip(orig_color.a - Epsilon);
				b_sound::ALSettings set;
				set.AL_Mode = b_sound::AudioLinkMode::ALM_Flat;
				set.AL_Distance = 0.0;
				set.AL_Theme_Weight = 1.0;
				set.AL_TC_BassReactive = 0.9;
				GET_SOUND_COLOR_CALL(set, soundColor);
				half4 result = lerp(orig_color, soundColor, soundColor.a);
				result.a = orig_color.a;
				return result;
			}
			ENDCG
		}
	}
}