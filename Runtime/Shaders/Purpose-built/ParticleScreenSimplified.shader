Shader "Bigi/ParticleScreen(Simple)"
{

	Properties
	{
		_WavinessFactor("Waviness factor",Range(-2.0,2.0)) = 0.5
	}

	SubShader
	{

		Blend SrcAlpha OneMinusSrcAlpha
		Tags
		{
			"VRCFallback" = "ToonCutout" "LTCGI"="ALWAYS"
		}

		CGINCLUDE
		#define MIRROR_THING
		ENDCG

		Pass
		{
			Name "OpaqueForwardBase"
			Tags
			{
				"Queue" = "Geometry"
				"RenderType" = "Geometry"
				"LightMode" = "ForwardBase"
				"LTCGI"="ALWAYS"
			}
			Cull Off
			ZWrite On
			ZTest On
			Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex simple_vert
			#pragma geometry b_particalizer_geomBase
			#pragma fragment simple_frag
			#include <Packages/lygia/generative/cnoise.hlsl>

			#include_with_pragmas "../Includes/Pragmas/ForwardBase.cginc"
			#include_with_pragmas "../Includes/Pragmas/CustomVariants.cginc"
			#include "../Includes/External/ProTV/BigiProTV.cginc"
			#include "../Includes/ColorUtil.cginc"
			CBUFFER_START(UnityPerMaterial)
				uniform float _WavinessFactor;
			CBUFFER_END

			struct appdata
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				UNITY_POSITION(pos); //float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct fragOutput
			{
				fixed4 color : SV_Target;
			};

			v2f simple_vert(const in appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = v.vertex;
				o.uv = v.texcoord;
				#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
				o.fogCoord = 0.0;
				#endif
				
				return o;
			}

			#define B_P_V2G v2f
			#include "../Includes/Jank/ParticalizerDefines.cginc"

			namespace b_particalizer
			{
				void calc_min_step(inout min_step_obj output, const in B_P_V2G input[3], const in float4 point_counts)
				{
					B_P_MS_CALC(float4, pos, input, output, xyzw, point_counts);
					B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
				}

				void calc_v2g(inout B_P_V2G output, const in min_step_obj min_step, const in float4 coords,
								const in float3 world_scale)
				{
					B_P_V_CALC(pos, min_step, output, xyzw, coords);
					B_P_V_CALC(uv, min_step, output, xy, coords);
					if (PROTV_PRESENT())
					{
						output.pos.z += (RGBToHSV(GET_PROTV(output.uv).rgb).z - 0.5) * _WavinessFactor;
					}
					else
					{
						float2 offsetUv = output.uv.xy * 4.0;
						float2 time = float2(_Time.y / 8.0, _Time.y / 4.0);
						float n1 = cnoise(offsetUv.xy + time.xy);
						output.pos.z += n1 * _WavinessFactor;
					}
					output.pos = UnityObjectToClipPos(output.pos);
					#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
						UNITY_TRANSFER_FOG(output, output.pos);
					#endif
				}
			}

			#include "../Includes/Jank/Particalizer.cginc"

			fragOutput simple_frag(v2f i)
			{
				fragOutput o;
				if (PROTV_PRESENT())
				{
					o.color = GET_PROTV(i.uv);
				}
				else
				{
					o.color = float4(0.25, 0.25, 0.25, 0.25);
				}
				UNITY_APPLY_FOG(i.fogCoord, o.color);
				return o;
			}
			ENDCG
		}

	}
}