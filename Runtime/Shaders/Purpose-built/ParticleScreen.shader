/*
Modification of the ProTV/VideoScreen Shader by ArchiTechVR.

This version outputs a bunch of opengl points instead of being a normal screen.
It only request a single tris to set the min-max position of the particles
and will generate a grid of points in object space.
At the time of writing it is configured to generate 64x36 grid in the xy direction to neatly space out the points in a 16:9 viewport,
These counts can be reconfigured in the `Runtime/Shaders/Includes/Jank/ParticalizerDefines.cginc` 
file using the POINT_COUNT_* and INSTANCE_COUNT_* variables, It should be ifdef'd enough to not have to modify that file.
If you want to add way more points to the the screen, make it consist of more triangles.


ProTV/VideoScreen License:

(based on the ISC License)

Copyright (c) 2020-2024 ArchiTechVR

Permission to use, copy, modify, and/or distribute this asset for any
purpose, except for resale in whole or in part, with or without fee is hereby granted, 
provided that the above copyright notice and this permission notice appear in all copies.
For clarity, permission is expressly granted to distribute and sell assets and prefabs
which make use of the functions and/or content of this asset.

THE ASSET IS PROVIDED "AS IS" AND THE AUTHOR(S) DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS ASSET INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS ASSET.

*/

Shader "Bigi/ParticleScreen(ProTVBased)"
{
	Properties
	{
		[MainTexture] _MainTex("Standby Texture", 2D) = "black" {}
		_VideoTex("Video Texture (Render Texture from the TV goes here)", 2D) = "" {}
		[Toggle(_USEGLOBALTEXTURE)] _UseGlobalTexture("Use Global Texture Instead (_Udon_VideoTex)", Float) = 0
		_Aspect("Mesh Aspect Ratio (0 to ignore)", Float) = 1.77777
		[Enum(Fit Inside, 0, Fit Outside, 1)] _AspectFitMode("Aspect Fit Mode", Integer) = 0
		_Brightness("Screen Brightness", Float) = 1
		_GIBrightness("Global Illumination Brightness", Float) = 3
		[Enum(Disabled, 0, Standard, 1, Dynamic, 2)] _Mirror("Mirror Flip Mode", Float) = 1
		[Enum(None, 0, Side by Side, 1, Side By Side Swapped, 2, Over Under, 3, Over Under Swapped, 4)] _3D("Standby 3D Mode", Float) = 0
		[Enum(Half Size 3D, 2, Full Size 3D, 0)] _Wide("Standby 3D Mode Size", Float) = 2
		[ToggleUI] _Force2D("Force Standby to 2D", Float) = 0
		[Toggle(_CLIP_BORDERS)] _Clip("Clip Aspect", Float) = 0
		[Toggle(_CROP_GAMMAZONE)] _CropGammaZone("Crop to GammaZone", Float) = 0
		[Toggle(_USEFOG)] _Fog("Enable Fog", Float) = 1
		[ToggleUI] _FadeEdges("Anti-alias Edges", Float) = 1
		[KeywordEnum(Normal, Overlay)] _RenderMode ("Render Mode", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
	}
	SubShader
	{
		Tags
		{
			"PerformanceChecks" = "False"
		}
		CGINCLUDE
		#pragma target 5.0
		ENDCG
		Pass
		{

			Name "STANDARD"
			Tags
			{
				"Queue" = "AlphaTest+50"
			}
			Cull [_Cull]
			CGPROGRAM
			#pragma vertex vertBase
			#pragma geometry b_particalizer_geomBase
			#pragma fragment fragBase
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma shader_feature_local _USEFOG
			#pragma shader_feature_local _USEGLOBALTEXTURE
			#pragma shader_feature_local _CLIP_BORDERS
			#pragma shader_feature_local _CROP_GAMMAZONE
			// GPU Instancing support https://docs.unity3d.com/2022.3/Documentation/Manual/gpu-instancing-shader.html
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#include <UnityCG.cginc>
			#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

			struct vertdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct fragdata
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				// fog support
				UNITY_FOG_COORDS(1)
			};

			#include "../Includes/Jank/ProTVScreen/Standard.cginc"

			fragdata vertBase(vertdata v)
			{
				fragdata o = (fragdata)0;
				#if _RENDERMODE_OVERLAY
                // send vertex to NaN land for the invalid render mode
                o.vertex = asfloat(-1);
                return o;
				#else
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_OUTPUT(fragdata, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;
				// fog support
				UNITY_TRANSFER_FOG(o, o.vertex);
				o.uv = v.uv;
				return o;
				#endif
			}

			float4 fragBase(const fragdata i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				FragmentProcessingData data = InitializeFragmentData(i.uv);
				float4 tex = ProcessFragment(data);
				// apply fog adjustment
				#if _USEFOG
                UNITY_APPLY_FOG(i.fogCoord, tex);
				#endif
				// final color
				return tex;
			}
			ENDCG
		}

		Pass
		{
			Name "OVERLAY"
			Tags
			{
				"Queue"="Overlay-1"
			}

			Cull [_Cull]
			ZTest Always

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry b_particalizer_geomBase
			#pragma fragment frag
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma shader_feature_local _USEGLOBALTEXTURE
			#pragma shader_feature_local _CLIP_BORDERS
			#pragma shader_feature_local _CROP_GAMMAZONE
			// GPU Instancing support https://docs.unity3d.com/2019.4/Documentation/Manual/GPUInstancing.html
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

			float2 getScreenUV(float4 screenPos)
			{
				float2 uv = screenPos / (screenPos.w + 0.0000000001);
				return uv;
			}

			struct vertdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				// SPS-I support
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct fragdata
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				// SPS-I support
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#include "../Includes/Jank/ProTVScreen/Overlay.cginc"

			fragdata vert(const vertdata v)
			{
				fragdata o = (fragdata)0;
				#if _RENDERMODE_NORMAL
				// send vertex to NaN land for the invalid render mode
				o.vertex = asfloat(-1);
				return o;
				#else
                // SPS-I support
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_OUTPUT(fragdata, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                //o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;
                o.uv = v.uv;
                o.screenPos = ComputeNonStereoScreenPos(o.vertex);
                return o;
				#endif
			}

			float4 frag(const fragdata i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				FragmentProcessingData data = InitializeFragmentData(getScreenUV(i.screenPos));
				data.outputAspect = _ScreenParams.x / _ScreenParams.y;
				float4 tex = ProcessFragment(data);
				return tex;
			}
			ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass is not used during regular rendering.
		Pass
		{
			Name "META"
			Tags
			{
				"LightMode" = "Meta"
			}

			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma geometry b_particalizer_geomBase
			#pragma fragment frag_meta2

			#pragma shader_feature EDITOR_VISUALIZATION
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma shader_feature_local _USEGLOBALTEXTURE
			#pragma shader_feature_local _CLIP_BORDERS
			#pragma shader_feature_local _CROP_GAMMAZONE
			#include "UnityStandardMeta.cginc"
			#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

			float _GIBrightness;

			#include "../Includes/Jank/ProTVScreen/Meta.cginc"

			v2f_meta vert_meta2(const VertexInput i)
			{
				#if _RENDERMODE_OVERLAY
                v2f_meta o = (v2f_meta)0;
                // send vertex to NaN land for the invalid render mode
                o.pos = asfloat(-1);
                return o;
				#else
				v2f_meta o = vert_meta(i);
				o.pos = i.vertex;
				#if !defined(EDITOR_VISUALIZATION)
				o.uv.xy = i.uv1.xy;
				#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
				o.uv.zw = i.uv2.xy;
				#endif
				#endif
				return o;
				#endif
			}

			float4 frag_meta2(const v2f_meta i): SV_Target
			{
				FragmentProcessingData data = InitializeFragmentData(i.uv);
				float brightness = data.brightness;
				data.brightness = 1;
				float4 tex = ProcessFragment(data);

				UnityMetaInput o = (UnityMetaInput)0;
				o.Albedo = half3(tex.rgb) * brightness;
				o.Emission = half3(tex.rgb) * _GIBrightness;
				#ifdef EDITOR_VISUALIZATION
                o.VizUV = i.vizUV;
                o.LightCoord = i.lightCoord;
				#endif
				return UnityMetaFragment(o);
			}
			ENDCG
		}

		Pass
		{
			Name "SHADOWCASTER"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM
			#pragma vertex vertShadow
			#pragma geometry b_particalizer_geomBase
			#pragma fragment fragShadow
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal: NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#include "../Includes/Jank/ProTVScreen/ShadowCaster.cginc"

			v2f vertShadow(const appdata v)
			{
				v2f o = (v2f)0;
				#if _RENDERMODE_OVERLAY
                // send vertex to NaN land for the invalid render mode
                o.pos = asfloat(-1);
                return o;
				#else
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				//TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.pos = v.vertex;
				o.normal = v.normal;
				return o;
				#endif
			}

			float4 fragShadow(v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				return 0;
			}
			ENDCG
		}

		// DepthNormals Pass
		Pass
		{
			Name "DEPTHNORMALS"
			Tags
			{
				"LightMode" = "DepthNormals"
			}

			Cull [_Cull]
			ZWrite On

			CGPROGRAM
			#pragma vertex vertDepthNormals
			#pragma geometry b_particalizer_geomBase
			#pragma fragment fragDepthNormals
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma skip_variants _RENDERMODE_OVERLAY
			#pragma shader_feature_local _USEGLOBALTEXTURE
			#pragma shader_feature_local _CLIP_BORDERS
			#pragma shader_feature_local _CROP_GAMMAZONE
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"
			#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

			struct vertdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct fragdata
			{
				float4 vertex : SV_POSITION;
				float4 nz : TEXCOORD0;
				float2 uv : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#include "../Includes/Jank/ProTVScreen/DepthNormals.cginc"

			fragdata vertDepthNormals(vertdata v)
			{
				fragdata o = (fragdata)0;
				#if _RENDERMODE_OVERLAY
                // send vertex to NaN land for the invalid render mode
                o.vertex = asfloat(-1);
                return o;
				#else
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_OUTPUT(fragdata, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.nz.xyz = COMPUTE_VIEW_NORMAL;
				o.nz.w = COMPUTE_DEPTH_01;
				return o;
				#endif
			}

			fixed4 fragDepthNormals(fragdata i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				// Process fragment to handle potential clip() calls
				FragmentProcessingData data = InitializeFragmentData(i.uv);
				ProcessFragmentClipOnly(data);

				return EncodeDepthNormal(i.nz.w, i.nz.xyz);
			}
			ENDCG
		}

		// DepthOnly Pass
		Pass
		{
			Name "DEPTHONLY"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			Cull [_Cull]
			ZWrite On
			ColorMask 0

			CGPROGRAM
			#pragma vertex vertDepthOnly
			#pragma geometry b_particalizer_geomBase
			#pragma fragment fragDepthOnly
			#pragma multi_compile_local _RENDERMODE_NORMAL _RENDERMODE_OVERLAY
			#pragma skip_variants _RENDERMODE_OVERLAY
			#pragma shader_feature_local _USEGLOBALTEXTURE
			#pragma shader_feature_local _CLIP_BORDERS
			#pragma shader_feature_local _CROP_GAMMAZONE
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"
			#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

			struct vertdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct fragdata
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#include "../Includes/Jank/ProTVScreen/DepthOnly.cginc"

			fragdata vertDepthOnly(vertdata v)
			{
				fragdata o = (fragdata)0;
				#if _RENDERMODE_OVERLAY
                // send vertex to NaN land for the invalid render mode
                o.vertex = asfloat(-1);
                return o;
				#else
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_OUTPUT(fragdata, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
				#endif
			}

			void fragDepthOnly(fragdata i)
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				#if _CLIP_BORDERS
                FragmentProcessingData data = InitializeFragmentData(i.uv);
                ProcessFragmentClipOnly(data);
				#endif
			}
			ENDCG
		}

	}
	FallBack "VertexLit"
	CustomEditor "VideoScreenGUI"
}