Shader "Bigi/LogoPlane(Texture)"
{
	Properties
	{
		[MainTexture] _MainTex ("Texture", 2D) = "black" {}
		_AL_Weight("Audiolink Intensity",Range(0.0,1.0)) = 0.0
		_MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.2
		[ToggleUI] _Alpha_Non_Premul("Non premultiplied colors (Multiplies alpha with main color)", Float) = 1
	}
	SubShader
	{
		Blend SrcAlpha OneMinusSrcAlpha
		Tags
		{
			"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "LightMode" = "ForwardBase" "VRCFallback"="Hidden" "LTCGI"="ALWAYS" "PreviewType" = "Plane"
		}

		Pass
		{
			Name "DepthPrepass"
			ColorMask 0
			Cull Off
			ZWrite On
			ZTest Less
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/StageDefines.cginc"
			#include "./Includes/LogoPlane.cginc"
			#pragma vertex vertd alpha
			#pragma fragment fragd alpha
			v2f vertd(appdata v)
			{
				return vert(v);
			}

			fragOutput fragd(v2f i)
			{
				fragOutput o;
				UNITY_INITIALIZE_OUTPUT(fragOutput, o);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				clip(orig_color.a - 1.0);
				o.color = orig_color;
				return o;
			}
			ENDHLSL
		}

		Pass
		{
			Tags
			{
				"RenderType" = "Transparent"
				"Queue" = "Transparent-1"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardBase"
				"VRCFallback"="Hidden"
				"LTCGI"="ALWAYS"
			}
			Name "TransparentForwardBaseBack"
			Cull Front
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#include "./Includes/LogoPlane.cginc"
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDHLSL
		}

		Pass
		{
			Name "TransparentForwardAddBack"
			Tags
			{
				"RenderType" = "Transparent"
				"Queue" = "Transparent-1"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardAdd"
			}
			Cull Front
			ZWrite Off
			ZTest LEqual
			Blend One One
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardAdd.cginc"
			#include "./Includes/LogoPlane.cginc"
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDHLSL
		}

		Pass
		{
			Name "TransparentForwardBaseFront"
			Tags
			{
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardBase"
				"VRCFallback"="Hidden"
				"LTCGI"="ALWAYS"
			}
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#include "./Includes/LogoPlane.cginc"

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDHLSL
		}


		Pass
		{
			Name "TransparentForwardAddFront"
			Tags
			{
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardAdd"
			}
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend One One
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardAdd.cginc"
			#include "./Includes/LogoPlane.cginc"

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDHLSL
		}

		Pass
		{
			Name "META"
			Tags
			{
				"LightMode"="Meta"
			}
			Cull Off
			HLSLPROGRAM
			#include_with_pragmas "./Includes/Pragmas/Meta.cginc"
			#include <UnityCG.cginc>
			#include <UnityMetaPass.cginc>
			#include <UnityStandardInput.cginc>
			#define BIG_SHADER_PARAMS_CUSTOM_PARAMS \
				uniform float _AL_Weight; \
				uniform float _Alpha_Non_Premul;
			
			#include "./Includes/Core/BigiGetColor.cginc"

			struct v2f_meta
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				#ifdef EDITOR_VISUALIZATION
			    float2 vizUV        : TEXCOORD1;
			    float4 lightCoord   : TEXCOORD2;
				#endif
			};

			v2f_meta vert_meta(VertexInput v)
			{
				v2f_meta o;
				#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
				o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST,
											unity_DynamicLightmapST);
				#else
				o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, float2(0, 0), unity_LightmapST,
												unity_DynamicLightmapST);
				#endif
				o.uv = TexCoords(v);
				#ifdef EDITOR_VISUALIZATION
			    o.vizUV = 0;
			    o.lightCoord = 0;
			    if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
			        o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.uv0.xy, v.uv1.xy, v.uv2.xy, unity_EditorViz_Texture_ST);
			    else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
			    {
			        o.vizUV = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			        o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
			    }
				#endif
				return o;
			}

			float4 frag_meta2(v2f_meta i): SV_Target
			{
				UnityMetaInput o;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
				const fixed4 orig_color = GET_TEX_COLOR(GETUV);
				clip(orig_color.a - 1.0);
				o.Albedo = orig_color;
				o.Emission = orig_color * _AL_Weight;
				o.SpecularColor = orig_color;
				#ifdef EDITOR_VISUALIZATION
				o.VizUV = i.vizUV;
				o.LightCoord = i.lightCoord;
				#endif
				return UnityMetaFragment(o);
			}

			#pragma vertex vert_meta
			#pragma fragment frag_meta2
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			ENDHLSL
		}

	}
}