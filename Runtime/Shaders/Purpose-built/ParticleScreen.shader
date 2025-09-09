Shader "Bigi/ParticleScreen(WIP)"
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

			#define B_P_V2G fragdata
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in fragdata input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, vertex, input, output, xyzw, point_counts);
					B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
					#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
						B_P_MS_CALC(float1, input, output, fogCoord, z, point_counts);
					#endif
				}

				void calc_v2g(inout fragdata output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(vertex, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xy, coords);
					#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
						B_P_V_CALC(fogCoord, min_step, output, z, coords);
					#endif
					output.vertex = UnityObjectToClipPos(output.vertex);
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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
			#include "Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc"

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

			#define B_P_V2G fragdata
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in fragdata input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, vertex, input, output, xyzw, point_counts);
					B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
					B_P_MS_CALC(float4, screenPos, input, output, xyzw, point_counts);
				}

				void calc_v2g(inout fragdata output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(vertex, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xy, coords);
					B_P_V_CALC(screenPos, min_step, output, xyzw, coords);
					output.vertex = UnityObjectToClipPos(output.vertex);
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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
			#include "Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc"

			float _GIBrightness;

			#define B_P_V2G v2f_meta
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in v2f_meta input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, pos, input, output, xyzw, point_counts);
					B_P_MS_CALC(float4, uv, input, output, xyzw, point_counts);
					#ifdef EDITOR_VISUALIZATION
					B_P_MS_CALC(float2, vizUV, input, output, xy, point_counts);
					B_P_MS_CALC(float4, lightCoord, input, output, xyzw, point_counts);
					#endif
				}

				void calc_v2g(inout v2f_meta output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(pos, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xyzw, coords);
					#ifdef EDITOR_VISUALIZATION
					B_P_V_CALC(vizUV, min_step,output, xy, point_counts);
					B_P_V_CALC(lightCoord, min_step,output, xyzw, point_counts);
					#endif
					//UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
					#if !defined(EDITOR_VISUALIZATION)
					output.pos = UnityMetaVertexPosition(output.pos,output.uv.xy,output.uv.zw,unity_LightmapST, unity_DynamicLightmapST);
					#else
					output.pos = UnityObjectToClipPos(output.pos);
					#endif
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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
				o.uv.zw = i.uv2.xy;
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

			#define B_P_V2G v2f
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in v2f input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, pos, input, output, xyzw, point_counts);
					B_P_MS_CALC(float3, normal, input, output, xyz, point_counts);
				}

				void calc_v2g(inout v2f output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(pos, min_step, output, xyzw, coords);
					B_P_V_CALC(normal, min_step, output, xyz, coords);
					struct
					{
						float4 vertex;
						float3 normal;
					} v;
					v.vertex = output.pos;
					v.normal = output.normal;
					TRANSFER_SHADOW_CASTER_NOPOS(output,output.pos)
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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
			#include "Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc"

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

			#define B_P_V2G fragdata
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in fragdata input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, vertex, input, output, xyzw, point_counts);
					B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
					B_P_MS_CALC(float4, nz, input, output, xyzw, point_counts);
				}

				void calc_v2g(inout fragdata output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(vertex, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xy, coords);
					B_P_V_CALC(nz, min_step, output, xyzw, coords);
					output.vertex = UnityObjectToClipPos(output.vertex);
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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
			#include "Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc"

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

			#define B_P_V2G fragdata
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in fragdata input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, vertex, input, output, xyzw, point_counts);
					B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
				}

				void calc_v2g(inout fragdata output, const in min_step_obj min_step, const in float4 coords)
				{
					B_P_V_CALC(vertex, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xy, coords);
					output.vertex = UnityObjectToClipPos(output.vertex);
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

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