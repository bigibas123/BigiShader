﻿Shader "Bigi/Billboard" {
	Properties {
		_MainTexArray ("Other textures", 2DArray) = "" {}
		_TextureId ("Other texture Id", Int) = 0
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

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include <UnityCG.cginc>
			#include <HLSLSupport.cginc>

			UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
			float4 _MainTexArray_ST;
			#ifndef BIGI_OTHER_TEXTURE_ID_DEFINED
			#define BIGI_OTHER_TEXTURE_ID_DEFINED
			uniform int _TextureId;
			#define OTHER_TEXTURE_ID_REF _TextureId
			#endif
			#define GET_TEX_COLOR(uv) UNITY_SAMPLE_TEX2DARRAY(_MainTexArray, float3(uv, OTHER_TEXTURE_ID_REF))

			#define DO_TRANSFORM(tc) TRANSFORM_TEX(tc, _MainTexArray)


			#define BIGI_SHADER_PARAMS
			#include "./Includes/SoundUtilsDefines.cginc"

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

				float4 cameraPos = float4(UnityObjectToViewPos(float3(0.0, 0.0, 0.0)).xyz, 1.0);

				float4 viewDirection = float4(v.pos.x, v.pos.y, 0.0, 0.0);

				o.pos = UnityViewToClipPos(cameraPos + viewDirection);
				o.uv = DO_TRANSFORM(v.uv);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 orig_color = GET_TEX_COLOR(i.uv);
				clip(orig_color.a - Epsilon);
				b_sound::ALSettings set;
				set.AL_Theme_Weight = 1.0;
				set.AL_TC_BassReactive = 0.9;
				GET_SOUND_COLOR_CALL(set,soundColor);
				return lerp(orig_color,soundColor,soundColor.a);
			}
			ENDCG
		}
	}
}