Shader "Bigi/LogoPlane" {
	Properties {
		_MainTexArray ("Texture", 2DArray) = "black" {}
		_Logo_FlipBookID ("CellNumber", Int) = 0
		_AL_Weight("Audiolink Intensity",Range(0.0,1.0)) = 0.0
		_MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.2
		[Toggle(ALPHA_MUL)] _Alpha_Multiply("Multiply alpha with itself", Float) = 1
		[Toggle(LTCGI_ENABLED)] _EnableLTCGI ("Enable LTCGI", Range(0.0,1.0)) = 0.0
	}
	SubShader {
		Blend SrcAlpha OneMinusSrcAlpha
		Tags {
			"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "LightMode" = "ForwardBase" "VRCFallback"="Hidden" "LTCGI"="ALWAYS" "PreviewType" = "Plane"
		}

		CGINCLUDE
		#ifndef MULTI_TEXTURE
		#define MULTI_TEXTURE
		#endif


		#include <UnityCG.cginc>
		uniform float _AL_Weight;

		uniform int _Logo_FlipBookID;
		#define MULTI_TEXTURE
		#define OTHER_TEXTURE_ID_REF _Logo_FlipBookID
		#define OTHER_BIGI_TEXTURES
		#define NO_RESET_MINAMBIENT

		#include "./Includes/ToonVert.cginc"
		#include "./Includes/Lighting/BigiLightingParamWriter.cginc"
		#include "./Includes/Effects/SoundUtilsDefines.cginc"


		v2f vert(appdata v)
		{
			b_light::setVars();
			return bigi_toon_vert(v);
		}

		fragOutput frag(v2f i)
		{
			b_light::setVars();
			fragOutput o;
			UNITY_INITIALIZE_OUTPUT(fragOutput, o);
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
			fixed4 orig_color = GET_TEX_COLOR(GETUV);
			clip(orig_color.a - Epsilon);
			#ifdef ALPHA_MUL
			orig_color.a = orig_color.a * orig_color.a;
			#endif


			BIGI_GETLIGHT_DEFAULT(lighting);
			fixed4 normal_color = orig_color * lighting;

			_AL_Theme_Weight = _AL_Weight;
			float distance = 0.0;
			GET_SOUND_COLOR(sound);

			o.color = lerp(normal_color,fixed4(sound.rgb, normal_color.a), sound.a);
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
			#pragma shader_feature_local_fragment LTCGI_ENABLED
			#pragma shader_feature_local_fragment ALPHA_MUL
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
			#pragma shader_feature_local_fragment LTCGI_ENABLED
			#pragma shader_feature_local_fragment ALPHA_MUL
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
			#pragma shader_feature_local_fragment LTCGI_ENABLED
			#pragma shader_feature_local_fragment ALPHA_MUL

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
			#pragma shader_feature_local_fragment LTCGI_ENABLED
			#pragma shader_feature_local_fragment ALPHA_MUL

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			ENDCG
		}

	}
}