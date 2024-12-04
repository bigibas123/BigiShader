Shader "Bigi/HeartRate" {
	Properties {
		_Heartrate ("Heartrate", Int) = 90
		_MinAmbient ("Minimum ambient light", Range(0.0,1.0)) = 0.01
		[Toggle(FLIP_XY)] _FlipXy ("Flip X&Y UV", Range(0.0,1.0)) = 1.0
		[Toggle(INVERT_Y)] _InvertY ("Invert Y UV", Range(0.0,1.0)) = 0.0
		[Toggle(INVERT_X)] _InvertX ("Invert X UV", Range(0.0,1.0)) = 0.0
		[Toggle(LTCGI_ENABLED)] _EnableLTCGI ("Enable LTCGI", Range(0.0,1.0)) = 0.0
	}
	SubShader {
		Blend SrcAlpha OneMinusSrcAlpha
		Tags {
			"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "LightMode" = "ForwardBase" "VRCFallback"="Hidden" "LTCGI"="ALWAYS"
		}

		CGINCLUDE
		#pragma shader_feature_local_fragment LTCGI_ENABLED
		#pragma shader_feature_local_vertex FLIP_XY
		#pragma shader_feature_local_vertex INVERT_Y
		#pragma shader_feature_local_vertex INVERT_X
		#include <UnityCG.cginc>
		#include <Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc>
		#define NO_RESET_MINAMBIENT
		#define ROUNDING_DISABLED
		#define DO_TRANSFORM(UV) (UV)
		#define GETUV (i.uv)
		#define GET_TEX_COLOR(UV)  (determineValue(UV))
		#include "./Includes/ToonVert.cginc"
		#include "./Includes/Lighting/BigiLightingParamWriter.cginc"
		#include "./Includes/Effects/SoundUtilsDefines.cginc"
		#include "./Includes/Lighting/LightUtilsDefines.cginc"

		uniform int _Heartrate;

		// Code taken and modified from: https://github.com/llealloo/audiolink/blob/965842714afbca8194c5a25882b8cd70a0ed434a/AudioLinkSandboxUnityProject/Assets/AudioLinkSandbox/Shaders/NewTextTest.shader#L51
		float4 determineValue(in float2 uv)
		{
			uv.y = 1.0 - uv.y;
			//
			// Pixel location as uint (floor)
			uint2 pixel = (uint2)uv;

			// This line of code is tricky;  We determine how much we should soften the edge of the text
			// based on how quickly the text is moving across our field of view.  This gives us realy nice
			// anti-aliased edges.
			float2 softness_uv = uv * float2(4, 6);
			float softness = 4. / (pow(length(float2(ddx(softness_uv.x), ddy(softness_uv.y))), 0.5)) - 1.;

			float2 charUV = float2(4, 6.5) - glsl_mod(uv, 1.0) * float2(4.0, 6.5);
			float value = PrintNumberOnLine(_Heartrate, charUV, softness, pixel.x, 3, 0, false, 0);
			return float4(value, value, value, value);
		}

		v2f vert(appdata v)
		{
			b_light::setVars();
			v2f o = bigi_toon_vert(v);
			#ifdef FLIP_XY
			o.uv.xy = o.uv.yx; // Flip Xy so text is flipped
			#endif
			#ifdef INVERT_Y
			o.uv.y = 1.0 - o.uv.y;
			#endif
			#ifdef INVERT_X
			o.uv.x = 1.0 - o.uv.x;
			#endif
			o.uv.xy = o.uv * float2(3, 1); // Set grid scale to 3x1 for 3 digit heartrate display
			return o;
		}

		fragOutput frag(v2f i)
		{
			b_light::setVars();
			fragOutput o;
			UNITY_INITIALIZE_OUTPUT(fragOutput, o);
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
			const fixed4 orig_color = GET_TEX_COLOR(GETUV);
			clip(orig_color.a - Epsilon);
			BIGI_GETLIGHT_DEFAULT(lighting);
			o.color = orig_color * lighting;

			o.color.a = orig_color.a;
			//o.color = orig_color;
			UNITY_APPLY_FOG(i.fogCoord, o.color);
			return o;
		}
		ENDCG

		Pass {
			ColorMask 0
			Cull Off
			ZWrite On
			ZTest Less
			CGPROGRAM
			#include_with_pragmas "./Includes/Pragmas/VRCLighting.cginc"
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
			ENDCG
		}

		Pass {
			Tags {
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
			CGPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#pragma shader_feature_local_fragment _ ALPHA_MUL
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDCG
		}

		Pass {
			Name "TransparentForwardAddBack"
			Tags {
				"RenderType" = "Transparent"
				"Queue" = "Transparent-1"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardAdd"
			}
			Cull Front
			ZWrite Off
			ZTest LEqual
			Blend One One
			CGPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardAdd.cginc"
			#pragma shader_feature_local_fragment _ ALPHA_MUL
			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDCG
		}

		Pass {
			Name "TransparentForwardBaseFront"
			Tags {
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
			CGPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardBase.cginc"
			#pragma shader_feature_local_fragment _ ALPHA_MUL

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDCG
		}


		Pass {
			Name "TransparentForwardAddFront"
			Tags {
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"LightMode" = "ForwardAdd"
			}
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend One One
			CGPROGRAM
			#include_with_pragmas "./Includes/Pragmas/ForwardAdd.cginc"
			#pragma shader_feature_local_fragment _ ALPHA_MUL

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDCG
		}

	}
}