Shader "Bigi/AudioLink_frag" {
	Properties {
		[MainTexture] _MainTex ("Texture", 2D) = "black" {}
		[HideInInspector] [Toggle(DO_ALPHA_PLS)] _UsesAlpha("Is transparent", Float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 2
		_Alpha_Threshold ("Alpha threshold",Range(-0.01,1.0)) = 0.99

		[Header(ZWriteZTest Settings)]
		[Header(Opaque Forward Base)]
		[Enum(Off, 0, On, 1)] _ZWriteOFWB ("ZWrite Opaque ForwardBase", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestOFWB ("Ztest Opaque ForwardBase", Int) = 4
		[Header(Transparent ForwardBase)]
		[Enum(Off, 0, On, 1)] _ZWriteTFWB ("ZWrite Transparent ForwardBase", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestTFWB ("Ztest Transparent ForwardBase", Int) = 2
		[Header(Other Passes)]
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestFWA ("Ztest ForwardAdd", Int) = 4
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestOL ("Ztest Outline", Int) = 4
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestSP ("Ztest Shadow Pass", Int) = 4
		
		[Header(Extra textures)]
        [Space]
        [NoScaleOffset] _Mask ("Mask", 2D) = "black" {}
        _EmissionStrength ("Emission strength", Range(0.0,2.0)) = 1.0
		[Space]
        _Spacey ("Spacey Texture", 2D) = "black" {}
		[Space]
		[Header(Normal mapping)]
		[Space]
		[NoScaleOffset] [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
		[HideInInspector] [Toggle(NORMAL_MAPPING)] _UsesNormalMap("Enable normal map", Float) = 1

		[Header(Specular and Smooth)]
		[Space]
		[NoScaleOffset] _SpecSmoothMap ("Specular (rgb) and Smoothness (a) map", 2D) = "black" {}
		[HideInInspector] [Toggle(SPECSMOOTH_MAP_ENABLED)] _EnableSpecularSmooth ("Enable Specular & Smoothness map", Range(0.0,1.0)) = 0.0

		[Header(Ambient Occlusion)]
		[Space]
		[NoScaleOffset] _OcclusionMap ("Ambient occlusion map", 2D) = "white" {}
		[HideInInspector] [Toggle(AMBIENT_OCCLUSION_ENABLED)] _AOEnabled ("Enabled Ambient Occlusion",Range(0.0,1.0)) = 0.0
		_OcclusionStrength("Occlusion Strength", Range(0, 1.0)) = 1.0

		[Space]
		[Header(Lighting)]
		[Space]
		_LightSmoothness ("Shadow smoothness",Range(0.0,1.0)) = 1.0
		[IntRange] _LightSteps ("Light steps", Range(0,256)) = 1
		[Space]
		_MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.005
		_Transmissivity ("Transmission of light through the material", Range(0.0,1.0)) = 0.2

		[Header(3rdParty lighting)]
		[Space]
		_VRSLGIStrength ("VRSL-GI Strength", Range(0.0,1.0)) = 0.25
		[Toggle(LTCGI_ENABLED)] _EnableLTCGI ("Enable LTCGI", Range(0.0,1.0)) = 0.0
		_LTCGIStrength ("LTCGI Strenght", Range(0.0,2.0)) = 1.0

		[Header(Audiolink world theme colors)]
		[Space]
		_AL_Theme_Weight("Weight", Range(0.0, 1.0)) = 1.0
		_AL_TC_BassReactive("Bassreactivity", Range(0.0,1.0)) = 0.75

		[Header(Effects)]
		[Space]
		_MonoChrome("MonoChrome", Range(0.0,1.0)) = 0.0
		_Voronoi("Voronoi", Range(0.0,1.0)) = 0.0
		_OutlineWidth ("Outline Width", Range(0.0,1.0)) = 0.0
		[Toggle(ROUNDING_DISABLED)] _RoundingDisabled ("Disable Rounding effect",Range(0.0,1.0)) = 1.0
		_Rounding ("Rounding Factor", Range(0.0,0.05)) = 0.0


		[Header(TV Square)]
		[Space]
		[Toggle(PROTV_SQUARE_ENABLED)] _EnableProTVSquare ("Enable ProTV texture render", Range(0.0,1.0)) = 0.0
		[Toggle(TV_SQUARE_TEST)] _SquareTVTest ("Enable temporarily to display tv location", Range(0.0,1.0)) = 0.0
		_TV_Square_Opacity ("TV opacity", Range(0.0,1.0)) = 1.0
		_TV_Square_Position ("TV Position & Size", Vector) = (0.0,0.0,1.0,1.0)

		[Header(Multi Texture)]
		[Space]
		_MainTexArray ("Other textures", 2DArray) = "" {}
		[HideInInspector] [Toggle(MULTI_TEXTURE)] _MultiTexture("Use multi texture", Float) = 0
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
			Cull [_Cull]
			ZWrite [_ZWriteOFWB]
			ZTest [_ZTestOFWB]
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
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiMainTex.cginc"
			#include "./Includes/ToonVert.cginc"
			#include "./Includes/BigiAudioLink_frag_default.cginc"

			fragOutput frag(v2f i)
			{
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				#ifdef DO_ALPHA_PLS
				if (orig_color.a < _Alpha_Threshold)
				{
					discard;
				}
				#endif
				return b_frag::bigi_frag_fwdbase(i, orig_color);
			}
			ENDCG
		}

		Pass {
			Name "TransparentForwardBase"
			Tags {
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
				"LightMode" = "ForwardBase"
				"LTCGI"="ALWAYS"
			}
			Cull [_Cull]
			ZWrite [_ZWriteTFWB]
			ZTest [_ZTestTFWB]
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil {
				Ref 180 //148 + 32 // 1011 0100 // VRSLGI + Own stencil bit
				Comp Always
				WriteMask 180
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			#pragma multi_compile_fwdbasealpha
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiMainTex.cginc"
			#include "./Includes/ToonVert.cginc"
			#include "./Includes/BigiAudioLink_frag_default.cginc"

			v2f vert(appdata v)
			{
				#ifdef DO_ALPHA_PLS
				return bigi_toon_vert(v);
				#else
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				return o;
				#endif
			}

			fragOutput frag(v2f i)
			{
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				#ifdef DO_ALPHA_PLS
				if(orig_color.a > _Alpha_Threshold)
				{
					discard;
				}
				#endif
				return b_frag::bigi_frag_fwdbase(i, orig_color);
			}
			ENDCG
		}

		Pass {
			Name "ForwardAdd"
			Tags {
				"LightMode" = "ForwardAdd"
				"LTCGI"="ALWAYS"
			}
			Cull [_Cull]
			ZWrite Off
			ZTest [_ZTestFWA]
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
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/ToonVert.cginc"
			#include "./Includes/Lighting/NormalDefines.cginc"
			#include "./Includes/Lighting/LightUtilsDefines.cginc"
			#include "./Includes/Effects/BigiEffects.cginc"

			fragOutput frag(v2f i)
			{
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				fragOutput o;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				RECALC_NORMALS();

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
			Cull [_Cull]
			ZWrite Off
			ZTest [_ZTestOL]
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

			#include_with_pragmas "./Includes/Pragmas/VRCLighting.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiShaderStructs.cginc"
			#include "./Includes/Core/BigiShaderParams.cginc"
			#include "./Includes/Effects/SoundUtilsDefines.cginc"
			#include "./Includes/ToonVert.cginc"


			v2f vert(appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				if (AudioLinkIsAvailable())
				{
					float4 heightPos = v.vertex * 10.0 + float4(0.0, 7.0, 0.0, 0.0);
					float3 offset = (normalize(v.normal.xyz)*2.0) * (_OutlineWidth * 0.01) * b_sound::GetWaves(length(heightPos));

					offset = lerp(0.0, offset, smoothstep(0.0, Epsilon, _OutlineWidth));
					v.vertex = v.vertex + float4(offset,0.0);
					o = bigi_toon_vert(v);
					GET_SOUND_COLOR(scol);
					o.staticTexturePos = scol;
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
					clip(i.staticTexturePos.a - Epsilon);
					o.color = half4(i.staticTexturePos.rgb * i.staticTexturePos.a,
							smoothstep(0.0, 0.05, i.staticTexturePos.a));
					clip(o.color.a - Epsilon);
				}
				else
				{
					discard;
					o.color = fixed4(0, 0, 0, 0);
				}
				return o;
			}
			ENDCG

		}

		Pass {
			Name "ShadowPass"
			Tags {
				"LightMode"="ShadowCaster"
				"LTCGI"="ALWAYS"
			}
			Cull Off
			ZWrite On
			ZTest [_ZTestSP]
			CGPROGRAM
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			#include_with_pragmas "./Includes/Pragmas/ShadowCaster.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			
			#define BIGI_DEFAULT_V2F_DEFINED

			#include "./Includes/Core/BigiShaderStructs.cginc"
			#include "./Includes/Core/BigiShaderParams.cginc"
			#include <UnityCG.cginc>
			
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
				UNITY_INITIALIZE_OUTPUT(v2f, o);
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
				#ifndef ROUNDING_DISABLED
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
				#endif
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