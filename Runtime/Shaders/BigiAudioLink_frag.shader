Shader "Bigi/AudioLink_frag" {
	Properties {
		[MainTexture] _MainTex ("Texture", 2D) = "black" {}
		[Toggle(DO_ALPHA_PLS)] _UsesAlpha("Is transparent", Float) = 1
		_Spacey ("Spacey Texture", 2D) = "black" {}
		_EmissionStrength ("Emission strength", Range(0.0,2.0)) = 1.0
		[NoScaleOffset] _Mask ("Mask", 2D) = "black" {}
		[NoScaleOffset] _OcclusionMap ("Ambient occlusion map", 2D) = "white" {}
		[Toggle(NORMAL_MAPPING)] _UsesNormalMap("Enable normal map", Float) = 1
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

		[Header(Lighting)]
		_LightSmoothness ("Shadow smoothness",Range(0.0,1.0)) = 1.0
		_LightThreshold ("Shadow Start point", Range(0.0,1.0)) = 0.0
		_MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.005
		_VRSLGIStrength ("VRSL-GI Strength", Range(0.0,1.0)) = 0.5
		
		[Header(MapEffects)]
		_OcclusionStrength("Occlusion Strength", Range(0, 1.0)) = 1.0
		_Transmissivity ("Transmission of light through the material", Range(0.0,1.0)) = 0.000
		_Smoothness ("Smoothness", Range(0.0,1.0)) = 0.000
		_SpecularIntensity ("Specular intensity", Range(0.0,1.0)) = 0.000

		[Header(Audiolink world theme colors)]
		_AL_Theme_Weight("Weight", Range(0.0, 1.0)) = 1.0
		_AL_TC_BassReactive("Bassreactivity", Range(0.0,1.0)) = 0.75

		[Header(Effects)]
		_MonoChrome("MonoChrome", Range(0.0,1.0)) = 0.0
		_Voronoi("Voronoi", Range(0.0,1.0)) = 0.0
		_OutlineWidth ("Outline Width", Range(0.0,1.0)) = 0.0
		_Rounding ("Rounding Factor", Range(0.0,0.05)) = 0.0

		[Header(Multi Texture)]
		[Toggle(MULTI_TEXTURE)] _MultiTexture("Use multi texture", Float) = 0
		_MainTexArray ("Other textures", 2DArray) = "" {}
		_OtherTextureId ("Other texture Id", Int) = 0


	}

	CustomEditor "cc.dingemans.bigibas123.bigishader.BigiShaderEditor"
	SubShader {
		Blend SrcAlpha OneMinusSrcAlpha
		Tags {
			"VRCFallback" = "ToonCutout" "LTCGI"="ALWAYS"
		}

		Pass {
			Name "OpaqueForwardBase"
			Tags {
				"Queue" = "AlphaTest"
				"RenderType" = "AlphaTest"
				"LightMode" = "ForwardBase"
				"LTCGI"="ALWAYS"
			}
			Cull Off
			ZWrite On
			ZTest Less
			Blend One OneMinusSrcAlpha
			Stencil {
				Ref 180 //148 + 32 // 1011 0100 // VRSLGI + Own stencil bit
				Comp Always
				WriteMask 180
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex bigi_toon_vert
			#pragma fragment frag

			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"

			#include "./Includes/ToonVert.cginc"
			#include "./Includes/LightUtilsDefines.cginc"
			#include "./Includes/NormalUtils.cginc"

			#include "./Includes/BigiEffects.cginc"

			fragOutput frag(v2f i)
			{
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				if (_UsesAlpha)
				{
					clip(orig_color.a - (1.0 - Epsilon));
				}
				fragOutput o;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				if (_UsesNormalMap)
				{
					i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent, i.bitangent);
				}

				BIGI_GETLIGHT_DEFAULT(lighting);

				const fixed4 mask = GET_MASK_COLOR(GETUV);
				o.color = b_effects::apply_effects(GETUV, mask, orig_color, lighting, i.staticTexturePos);
				UNITY_APPLY_FOG(i.fogCoord, o.color);
				return o;
			}
			ENDCG
		}

		Pass {
			Name "TransparentForwardBase"
			Tags {
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
				"LightMode" = "ForwardBase"
			}
			Cull Off
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil {
				Ref 180 //148 + 32 // 1011 0100 // VRSLGI + Own stencil bit
				Comp Always
				WriteMask 180
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbasealpha
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"

			#include "./Includes/ToonVert.cginc"
			#include "./Includes/LightUtilsDefines.cginc"
			#include "./Includes/NormalUtils.cginc"
			#include "./Includes/BigiEffects.cginc"

			v2f vert(appdata v)
			{
				if (_UsesAlpha)
				{
					return bigi_toon_vert(v);
				}
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				return o;
			}

			fragOutput frag(v2f i)
			{
				if (_UsesAlpha)
				{
					const fixed4 orig_color = GET_TEX_COLOR(GETUV);
					clip((orig_color.a - (1.0 - Epsilon)) * -1.0);
					fragOutput o;
					UNITY_SETUP_INSTANCE_ID(i);
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
					if (_UsesNormalMap)
					{
						i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent,
																	i.bitangent);
					}

					BIGI_GETLIGHT_DEFAULT(lighting);

					const fixed4 mask = GET_MASK_COLOR(GETUV);
					o.color = b_effects::apply_effects(GETUV, mask, orig_color, lighting, i.staticTexturePos);
					UNITY_APPLY_FOG(i.fogCoord, o.color);
					return o;
				}
				else
				{
					discard;
					fragOutput o;
					UNITY_INITIALIZE_OUTPUT(fragOutput, o);
					return o;
				}
			}
			ENDCG
		}

		Pass {
			Name "ForwardAdd"
			Tags {
				"LightMode" = "ForwardAdd"
			}
			Cull Off
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha One
			Stencil {
				Ref 180 //148 + 32 // 1011 0100 // VRSLGI + Own stencil bit
				Comp Always
				WriteMask 180
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex bigi_toon_vert
			#pragma fragment frag
			#include_with_pragmas "./Includes/Pragmas/ForwardAdd.cginc"


			#include "./Includes/ToonVert.cginc"
			#include "./Includes/LightUtilsDefines.cginc"
			#include "./Includes/BigiEffects.cginc"
			#include "./Includes/BigiShaderParams.cginc"
			#include "./Includes/NormalUtils.cginc"

			fragOutput frag(v2f i)
			{
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				fragOutput o;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				if (_UsesNormalMap)
				{
					i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent, i.bitangent);
				}

				BIGI_GETLIGHT_DEFAULT(lighting);

				o.color = b_effects::apply_effects(GETUV, fixed4(0, 0, 0, 0), orig_color, lighting, i.staticTexturePos);
				UNITY_APPLY_FOG(i.fogCoord, o.color);
				return o;
			}
			ENDCG
		}


		Pass {
			Name "Outline"
			Tags {
				"Queue" = "Overlay"
				"RenderType" = "TransparentCutout"
				"Lightmode" = "Always"
			}
			Cull Off
			ZWrite Off
			ZTest LEqual
			AlphaToMask On
			Stencil {
				Ref 0
				ReadMask 32
				WriteMask 0
				Comp GEqual
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include_with_pragmas "./Includes/Pragmas/Global.cginc"


			#include "./Includes/BigiShaderParams.cginc"
			#include "./Includes/SoundUtilsDefines.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID };

			//intermediate
			struct v2f
			{
				UNITY_POSITION(pos); //float4 pos : SV_POSITION;
				half4 soundColor: COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata v)
			{
				v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
				if (AudioLinkIsAvailable())
				{
					

					GET_SOUND_COLOR(scol);
					o.soundColor = scol;

					float4 heightPos = v.vertex * 10.0 + float4(0.0, 7.0, 0.0, 0.0);
					float3 offset = v.normal.xyz * (_OutlineWidth * 0.01) * b_sound::GetWaves(length(heightPos));

					o.pos = UnityObjectToClipPos(v.vertex + offset);
					o.pos = lerp(0.0, o.pos, smoothstep(0.0,Epsilon, _OutlineWidth));
				}else
				{
					o.pos = float4(0,0,0,0);
					o.soundColor = half4(0,0,0,0);
				}

				return o;
			}

			fragOutput frag(v2f i)
			{
				fragOutput o;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				if (AudioLinkIsAvailable())
				{
					clip(_OutlineWidth - Epsilon);
					clip(i.soundColor.a - Epsilon);
					o.color = half4(i.soundColor.rgb * i.soundColor.a, smoothstep(0.0, 0.05, i.soundColor.a));
					clip(o.color.a - Epsilon);
				}else
				{
					discard;
					o.color = fixed4(0,0,0,0);
				}
				return o;
			}
			ENDCG

		}

		Pass {
			Name "ShadowPass"
			Tags {
				"LightMode"="ShadowCaster"
			}
			Cull Off
			ZWrite On
			ZTest LEqual
			CGPROGRAM
			#pragma vertex vert alpha
			#pragma fragment frag alpha

			#include_with_pragmas "./Includes/Pragmas/ShadowCaster.cginc"

			#include "./Includes/BigiShaderParams.cginc"
			#include <UnityCG.cginc>

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO
				#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    float2 tex : TEXCOORD1;

				#if defined(_PARALLAXMAP)
                        half3 viewDirForParallax : TEXCOORD2;
				#endif
				#endif
				//float4 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

				#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    o.tex = DO_TRANSFORM(v.uv0);

				#ifdef _PARALLAXMAP
                        TANGENT_SPACE_ROTATION;
                        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
				#endif
				#endif
				if (_Rounding > Epsilon)
				{
					float4 snapToPixel = o.pos;
					float gridSize = 1.0 / (_Rounding + Epsilon);
					float4 vt = snapToPixel;
					vt.xyz = snapToPixel.xyz / snapToPixel.w;
					vt.xy = floor(gridSize * vt.xy) / gridSize;
					vt.xyz *= snapToPixel.w;
					o.pos = vt;
				}
				//o.uv = v.texcoord;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i)
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

				#ifdef UNITY_STANDARD_USE_SHADOW_UVS
                     half alpha = GET_TEX_COLOR(i.tex.y).a;
				#ifdef UNITY_STANDARD_USE_DITHER_MASK
				// Use dither mask for alpha blended shadows, based on pixel position xy
				// and alpha level. Our dither texture is 4x4x16.
				#ifdef LOD_FADE_CROSSFADE
                                #define _LOD_FADE_ON_ALPHA
                                alpha *= unity_LODFade.y;
				#endif
                            half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
                            clip (alphaRef - 0.01);
				#else
                            clip (alpha - );
				#endif
				#endif
				//#if defined(UNITY_STANDARD_USE_SHADOW_UVS)

				#ifdef LOD_FADE_CROSSFADE
				#ifdef _LOD_FADE_ON_ALPHA
                        #undef _LOD_FADE_ON_ALPHA
				#else
                        UnityApplyDitherCrossFade(vpos.xy);
				#endif
				#endif


				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}