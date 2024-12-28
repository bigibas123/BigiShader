Shader "Bigi/FireThing" {
	Properties {}
	SubShader {
		Tags {
			"RenderType"="Opaque"
		}
		LOD 100
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
			ZTest On
			Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag
			#include <UnityCG.cginc>
			#include <Packages/lygia/generative/cnoise.hlsl>
			#include <Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc>

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2g
			{
				UNITY_POSITION(vertex);
				float3 normal : NORMAL;
				float distance: BLENDWEIGHT;
				UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct g2f
			{
				UNITY_POSITION(vertex);
				float distance : BLENDWEIGHT0;
				UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#pragma target 5.0
			#pragma fragmentoption ARB_precision_hint_fastest

			v2g vert(appdata v)
			{
				v2g o;
				UNITY_INITIALIZE_OUTPUT(v2g, o);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.distance = 1.0;
				return o;
			}

			#define SetMiddle(prop) res.prop = (((b.prop - a.prop) / 2.0) + a.prop)
			#define UnitIfy(prop) res.prop = normalize(res.prop)

			v2g getMiddleV2g(const in v2g a, const in v2g b)
			{
				v2g res;
					UNITY_INITIALIZE_OUTPUT(v2g, res);
					SetMiddle(vertex);
					SetMiddle(normal);
					UnitIfy(normal);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(a, res);
				UNITY_TRANSFER_INSTANCE_ID(a, res);
				return res;
			}

			void addTriangle(in g2f a, in g2f b, in g2f c, inout TriangleStream<g2f> outStream)
			{
				outStream.Append(a);
				outStream.Append(b);
				outStream.Append(c);
				outStream.RestartStrip();
			}

			g2f v2gToG2f(const in v2g a)
			{
				g2f res;
				res.distance = a.distance;
				res.vertex = UnityObjectToClipPos(a.vertex);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(a, res);
				UNITY_TRANSFER_INSTANCE_ID(a, res);
				return res;
			}

			void addTriangle(const in v2g a, const in v2g b, const in v2g c, inout TriangleStream<g2f> outStream)
			{
				addTriangle(v2gToG2f(a), v2gToG2f(b), v2gToG2f(c), outStream);
			}

			struct arrayContainer
			{
				v2g output[9];
			};

			float2 getPos(const in float4 pos)
			{
				return (mul(unity_ObjectToWorld, pos).xz * 20.0) + (_Time.w / 2.0);
			}

			float4 getOffset(const in float4 pos, const in float3 normal)
			{
				float result;
				float2 coord = getPos(pos);
				if (AudioLinkIsAvailable())
				{
					float dist = (coord.x * 8.0 + coord.y * 4.0) % (AUDIOLINK_WIDTH * 1.0);
					result = (AudioLinkLerp(ALPASS_AUDIOLINK + float2(dist, 0)) + 0.1).x;
				}
				else
				{
					result = cnoise(coord) * 0.5 + 0.5;
				}
				return float4(normalize(normal) * result, result);
			}

			arrayContainer split3(const in v2g input[3], const uint id)
			{
				v2g output[9];
				v2g a = input[0];
				v2g b = input[1];
				v2g c = input[2];
				v2g ab = getMiddleV2g(a, b);
				v2g abc = getMiddleV2g(ab, c);
				float4 offset = getOffset(abc.vertex, abc.normal);
				abc.vertex.xyz += offset.xyz;
				abc.distance = 1.0 - offset.w;
				output[0] = a;
				output[1] = b;
				output[2] = abc;
				output[3] = abc;
				output[4] = b;
				output[5] = c;
				output[6] = a;
				output[7] = abc;
				output[8] = c;
				arrayContainer ret;
				ret.output = output;
				return ret;
			}

			//[maxvertexcount(3 * 3 * 3 * 3)]
			[maxvertexcount(128)]
			void geom(
				triangle v2g input[3], uint pid : SV_PrimitiveID,
				inout TriangleStream<g2f> os
			)
			{
				DEFAULT_UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0])
				const uint rid = pid * 10;
				v2g splitList1[9] = split3(input, rid).output;
				[unroll]
				for (int i = 0; i <= 2; ++i)
				{
					v2g input2[3] = {
						splitList1[0 + (i * 3)],
						splitList1[1 + (i * 3)],
						splitList1[2 + (i * 3)]
					};
					v2g splitList2[9] = split3(input2, rid + i).output;
					UNITY_UNROLL
					for (int j = 0; j <= 2; ++j)
					{
						v2g input3[3] = {
							splitList2[0 + (j * 3)],
							splitList2[1 + (j * 3)],
							splitList2[2 + (j * 3)]
						};
						v2g splitList3[9] = split3(input3, rid + i).output;
						UNITY_UNROLL
						for (int k = 0; k <= 2; ++k)
						{
							addTriangle(
								splitList3[0 + (k * 3)],
								splitList3[1 + (k * 3)],
								splitList3[2 + (k * 3)],
								os);
						}
					}
				}
			}


			float4 frag(const g2f i) : SV_Target
			{
				const uint fireColorCount = 6;
				const float3 fireColors[6] = {
					float3(0.5, 0.07, 0.0),
					float3(0.71, 0.13, 0.01),
					float3(0.84, 0.21, 0.01),
					float3(0.99, 0.39, 0.0),
					float3(1.0, 0.46, 0.0),
					float3(0.98, 0.75, 0.0),
				};
				const float scale = 10.0;
				const float pos = (i.distance + 0.2) * scale;
				const uint selection = (pos % fireColorCount);
				return float4(fireColors[(fireColorCount - 1) - selection], 1.0);
			}
			ENDCG
		}
	}
}