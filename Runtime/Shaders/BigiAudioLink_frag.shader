Shader "Bigi/AudioLink_frag" {
	Properties {
		[MainTexture] _MainTex ("Texture", 2D) = "black" {}
		[Toggle(DO_ALPHA_PLS)] _UsesAlpha("Is transparent (NOT ANIMATABLE)", Float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 2
		_Alpha_Threshold ("Alpha threshold",Range(-0.01,1.0)) = 0.99
		_Alpha_Multiplier ("Alpha Multiplier", Range(0.0,2.0)) = 1.0

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
		_Mask ("Mask", 2D) = "black" {}
		_EmissionStrength ("Emission strength", Range(0.0,2.0)) = 1.0
		[Space]
		_Spacey ("Spacey Texture", 2D) = "black" {}
		[Space]
		[Header(Normal mapping)]
		[Space]
		[NoScaleOffset] [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
		[Toggle(NORMAL_MAPPING)] _UsesNormalMap("Enable normal map (NOT ANIMATABLE)", Float) = 1
		[Space]
		[Space]
		[Header(Decals)]
		[NoScaleOffset] _Decal1 ("Decal 1", 2D) = "black" {}
		[Toggle(DECAL_1_ENABLED)] _Decal1Enabled ("Enable decal 1 (NOT ANIMATABLE)", Float) = 0
		[Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal1_BlendMode ("Decal 1 blend mode",Range(0,4)) = 0
		_Decal1_Opacity ("Decal 1 opacity", Range(0.0,1.0)) = 1.0
		_Decal1_Position ("Decal 1 Position & Size", Vector) = (0.0,0.0,1.0,1.0)
		[Space]
		[NoScaleOffset] _Decal2 ("Decal 2", 2D) = "black" {}
		[Toggle(DECAL_2_ENABLED)] _Decal2Enabled ("Enable decal 2 (NOT ANIMATABLE)", Float) = 0
		[Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal2_BlendMode ("Decal 2 blend mode",Range(0,4)) = 0
		_Decal2_Opacity ("Decal 2 opacity", Range(0.0,1.0)) = 1.0
		_Decal2_Position ("Decal 2 Position & Size", Vector) = (0.0,0.0,1.0,1.0)
		[Space]
		[NoScaleOffset] _Decal3 ("Decal 3", 2D) = "black" {}
		[Toggle(DECAL_3_ENABLED)] _Decal3Enabled ("Enable decal 3 (NOT ANIMATABLE)", Float) = 0
		[Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal3_BlendMode ("Decal 3 blend mode",Range(0,4)) = 0
		_Decal3_Opacity ("Decal 3 opacity", Range(0.0,1.0)) = 1.0
		_Decal3_Position ("Decal 3 Position & Size", Vector) = (0.0,0.0,1.0,1.0)

		[Header(Specular and Smooth)]
		[Space]
		[NoScaleOffset] _SpecSmoothMap ("Specular (rgb) and Smoothness (a) map", 2D) = "black" {}
		[Toggle(SPECSMOOTH_MAP_ENABLED)] _EnableSpecularSmooth ("Enable Specular & Smoothness map (NOT ANIMATABLE)", Range(0.0,1.0)) = 0.0

		[Header(Ambient Occlusion)]
		[Space]
		[NoScaleOffset] _OcclusionMap ("Ambient occlusion map", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1.0)) = 1.0

		[Space]
		[Header(Lighting)]
		[Space]
		_LightSmoothness ("Shadow smoothness",Range(0.0,1.0)) = 1.0
		[IntRange] _LightSteps ("Light steps", Range(0,256)) = 1
		[Space]
		_MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.005
		_Transmissivity ("Transmission of light through the material", Range(0.0,1.0)) = 0.2

		[Header(Lighting System strengths)]
		[Space]
		_LightVertexMultiplier ("Vertex Multiplier",Range(0.0,5.0)) = 1.0
		_LightEnvironmentMultiplier ("Environment Multiplier",Range(0.0,5.0)) = 1.0
		_LightMainMultiplier ("Main Light Multiplier",Range(0.0,5.0)) = 1.0
		_VRSLGIStrength ("VRSL-GI Strength", Range(0.0,2.0)) = 0.25
		[Toggle(LTCGI_ENABLED)] _EnableLTCGI ("Enable LTCGI (NOT ANIMATABLE)", Range(0.0,1.0)) = 0.0
		_LTCGIStrength ("LTCGI Strenght", Range(0.0,5.0)) = 1.0

		[Header(Audiolink)]
		[Space]
		[Enum(Flat,0,CenterOut,1,WireFrame,2)] _AL_Mode ("Audiolink mode", Range(0,2)) = 0
		[Space]
		_AL_Theme_Weight("Weight", Range(0.0, 1.0)) = 1.0
		_AL_TC_BassReactive("Bassreactivity", Range(0.0,1.0)) = 0.75
		_AL_WireFrameWidth ("Wireframe Width", Range(0.0,1.0)) = 0.05

		[Header(Effects)]
		[Space]
		_MonoChrome("MonoChrome", Range(0.0,1.0)) = 0.0
		_Voronoi("Voronoi", Range(0.0,1.0)) = 0.0
		_OutlineWidth ("Outline Width", Range(0.0,1.0)) = 0.0
		_Rounding ("Rounding Factor", Range(0.0,0.05)) = 0.0
		[ToggleUI] _DoMirrorThing ("Voronoi in mirror", Range(0.0,1.0)) = 1.0


		[Header(TV Square)]
		[Space]
		[Toggle(PROTV_SQUARE_ENABLED)] _EnableProTVSquare ("Enable ProTV texture render (NOT ANIMATABLE)", Range(0.0,1.0)) = 0.0
		[ToggleUI] _SquareTVTest ("Enable temporarily to display tv location", Range(0.0,1.0)) = 0.0
		_TV_Square_Opacity ("TV opacity", Range(0.0,1.0)) = 1.0
		_TV_Square_Position ("TV Position & Size", Vector) = (0.0,0.0,1.0,1.0)
		
		[Header(Stencil settings (NOT ANIMATABLE))]
		[Space]
		[IntRange] _MainStencilRef ("Write this stencil value for the main avatar passes", Range(0, 255)) = 148
		[IntRange] _MainStencilWriteMask ("Use this mask while writing main passes", Range(0, 255)) = 255
		[Enum(UnityEngine.Rendering.StencilOp)] _MainStencilPass ("Operation on the value of the stencil buffer in main passes", Float) = 2

		[Header(Multi Texture)]
		[Space]
		_MainTexArray ("Other textures", 2DArray) = "" {}
		[Toggle(MULTI_TEXTURE)] _MultiTexture("Use multi texture (NOT ANIMATABLE)", Float) = 0
		_OtherTextureId ("Other texture Id", Int) = 0


	}

	CustomEditor "cc.dingemans.bigibas123.bigishader.BigiShaderEditor"
	SubShader {
		Blend SrcAlpha OneMinusSrcAlpha
		Tags {
			"VRCFallback" = "ToonCutout" "LTCGI"="ALWAYS"
		}

		CGINCLUDE
		#define MIRROR_THING
		ENDCG

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
				Ref [_MainStencilRef]
				Comp Always
				WriteMask [_MainStencilWriteMask]
				Pass [_MainStencilPass]
			}
			CGPROGRAM
			#pragma vertex bigi_toon_vert
			#pragma fragment frag
			#pragma geometry bigi_geom

			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiMainTex.cginc"
			#include "./Includes/ToonVert.cginc"
			#include "./Includes/BigiAudioLink_frag_default.cginc"
			#include "./Includes/GeomProcessor.cginc"

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
				Ref [_MainStencilRef]
				Comp Always
				WriteMask [_MainStencilWriteMask]
				Pass [_MainStencilPass]
			}
			CGPROGRAM
			#define TRANSPARENT_FORWARD_BASE
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			#pragma geometry geom alpha
			#pragma multi_compile_fwdbasealpha
			
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiMainTex.cginc"
			#include "./Includes/ToonVert.cginc"
			#include "./Includes/BigiAudioLink_frag_default.cginc"
			#include "./Includes/GeomProcessor.cginc"

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
			
			[instance(1)]
			[maxvertexcount(3)]
			void geom(
				triangle v2f input[3],
				inout TriangleStream<v2f> os
				)
			{
				#ifdef DO_ALPHA_PLS
				bigi_geom(input, os);
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
				Ref [_MainStencilRef]
				Comp Equal
				ReadMask [_MainStencilWriteMask]
				WriteMask 0
				Pass Keep
				Fail Keep
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

				o.color = b_effects::apply_effects(i.pos, GETUV,GET_MASK_COLOR(GETUV), orig_color, lighting, i.distance,
													i.staticTexturePos);
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
			// Check if Stencil bits are set right and do not draw on those bits
			// Can't use my own bit as a flag since vrslgi needs 148 exactly to not draw over the avatar
			Stencil {
				Ref [_MainStencilRef]
				WriteMask 0
				ReadMask [_MainStencilWriteMask]
				Comp NotEqual
				Pass Keep
				Fail Keep
				
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include_with_pragmas "./Includes/Pragmas/VRCLighting.cginc"
			#include_with_pragmas "./Includes/Pragmas/CustomVariants.cginc"
			#include "./Includes/Core/BigiShaderStructs.cginc"
			#include "./Includes/Core/BigiShaderParams.cginc"
			#include "./Includes/Effects/SoundUtilsDefines.cginc"
			#include "./Includes/Effects/LengthDefine.cginc"
			#include "./Includes/ToonVert.cginc"


			v2f vert(appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				if (AudioLinkIsAvailable())
				{
					float4 distance = float4(1.0/3.0,1.0/3.0,1.0/3.0,GET_DISTANCE(v.vertex));
					float3 offset = (normalize(v.normal.xyz) * 2.0) * (_OutlineWidth * 0.01) * b_sound::GetWaves(
						distance.w);

					offset = lerp(0.0, offset, smoothstep(0.0, Epsilon, _OutlineWidth));
					v.vertex = v.vertex + float4(offset, 0.0);
					o = bigi_toon_vert(v);

					GET_SOUND_SETTINGS(bsoundSet);
					bsoundSet.AL_Mode = b_sound::AudioLinkMode::ALM_Flat;
					GET_SOUND_COLOR_CALL(bsoundSet, scol);
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
				#ifdef ROUNDING_VAR_NAME
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
