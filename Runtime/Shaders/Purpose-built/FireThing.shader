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
			HLSLPROGRAM
			#pragma target 5.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include <UnityCG.cginc>
			#include <Packages/lygia/generative/cnoise.hlsl>
			#include <Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc>

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2g
			{
				UNITY_POSITION(vertex);
				float3 normal : NORMAL;
				float distance: BLENDWEIGHT0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct g2f
			{
				UNITY_POSITION(vertex);
				float distance : BLENDWEIGHT0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#pragma target 5.0
			#pragma fragmentoption ARB_precision_hint_fastest

			v2g vert(appdata v)
			{
				v2g o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2g, o);
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
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(a, res);
				SetMiddle(vertex);
				res.normal = (a.normal + b.normal) / 2.0;
				SetMiddle(distance);
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
				UNITY_INITIALIZE_OUTPUT(g2f, res);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(a, res);
				res.distance = a.distance;
				res.vertex = UnityObjectToClipPos(a.vertex);
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

			float2 getPos(const in float4 objPos, const in float3 scale)
			{
				const float3 pos = objPos / scale;
				return float2(
					(pos.x * 2.0) + (pos.y * 4.0) + (pos.z * 8.0) + (_Time.w / 4.0),
					(pos.z * 2.0) + (pos.y * 4.0) + (pos.x * 8.0) + (_Time.w / 4.0)
				);
			}

			float3 getWorldPos(const in float3 objPos, const in float3 scale)
			{
				const float4 wp = mul(unity_ObjectToWorld, objPos);
				return wp;
			}

			float getMax(const in float4 val)
			{
				return max(val.x, max(val.y, max(val.z, val.w)));
			}

			float getAl(const in float2 coord)
			{
				float dist = abs((coord.x * 2.0 + coord.y) * 20.0) % (AUDIOLINK_WIDTH);
				float4 audio = float4(
					AudioLinkLerp(ALPASS_AUDIOLINK + float2(dist, 0)).r,
					AudioLinkLerp(ALPASS_AUDIOLINK + float2(dist, 1)).r,
					AudioLinkLerp(ALPASS_AUDIOLINK + float2(dist, 2)).r,
					AudioLinkLerp(ALPASS_AUDIOLINK + float2(dist, 3)).r
				);

				return (getMax(audio) + 0.1).x;
			}

			float4 getOffset(const in float4 pos, const in float3 normal, const in float3 scale)
			{
				float result;
				if (false && AudioLinkIsAvailable())
				{
					result = getAl(getPos(pos, scale) * 20.0);
				}
				else
				{
					result = cnoise(getPos(pos, scale)) * 0.5 + 0.5;
				}
				result = clamp(result, 0.0, 1.0);
				return float4((normalize(normal.xyz) * 0.35 * 0.35 * 0.35) * result, result);
			}

			arrayContainer split3(const in v2g input[3], const in float3 scale)
			{
				v2g output[9];
				v2g a = input[0];
				v2g b = input[1];
				v2g c = input[2];
				v2g ab = getMiddleV2g(a, b);
				v2g abc = getMiddleV2g(ab, c);
				float4 offset = getOffset(abc.vertex, abc.normal, scale);
				abc.vertex = abc.vertex + float4(offset.xyz * scale, 0.0);
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

			[instance(3 * 3 * 3)]
			[maxvertexcount(3 * 3 * 3)]
			void geom(
				triangle v2g input[3], uint pid : SV_PrimitiveID,
				inout TriangleStream<g2f> os,
				uint instanceID : SV_GSInstanceID
			)
			{
				const float3 scale = 1.0 / float3(
					length(unity_ObjectToWorld._m00_m10_m20),
					length(unity_ObjectToWorld._m01_m11_m21),
					length(unity_ObjectToWorld._m02_m12_m22)
				);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0])
				v2g splitList1[9] = split3(input, scale).output;
				v2g input2[3] = {
					splitList1[0 + (glsl_mod(instanceID, 3) * 3)],
					splitList1[1 + (glsl_mod(instanceID, 3) * 3)],
					splitList1[2 + (glsl_mod(instanceID, 3) * 3)]
				};
				v2g splitList2[9] = split3(input2, scale).output;
				v2g input3[3] = {
					splitList2[0 + (glsl_mod(instanceID / 3, 3) * 3)],
					splitList2[1 + (glsl_mod(instanceID / 3, 3) * 3)],
					splitList2[2 + (glsl_mod(instanceID / 3, 3) * 3)]
				};
				v2g splitList3[9] = split3(input3, scale).output;
				v2g input4[3] = {
					splitList3[0 + (glsl_mod(instanceID / 3 / 3, 3) * 3)],
					splitList3[1 + (glsl_mod(instanceID / 3 / 3, 3) * 3)],
					splitList3[2 + (glsl_mod(instanceID / 3 / 3, 3) * 3)]
				};
				v2g splitList4[9] = split3(input4, scale).output;
				for (int i = 0; i <= 2; ++i)
				{
					v2g input5[3] = {
						splitList4[0 + i * 3],
						splitList4[1 + i * 3],
						splitList4[2 + i * 3]
					};
					v2g splitList5[9] = split3(input5, scale).output;

					for (int k = 0; k <= 2; ++k)
					{
						addTriangle(
							splitList5[0 + (k * 3)],
							splitList5[1 + (k * 3)],
							splitList5[2 + (k * 3)],
							os);
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
				const float scale = 7.5;
				const float pos = (i.distance - 0.2) * scale;
				const float selection = fireColorCount - (glsl_mod(pos, fireColorCount));
				const uint iSelection = selection;
				if (true)
				{
					const float3 sel1 = fireColors[clamp(iSelection, 0, fireColorCount - 1)];
					const float3 sel2 = fireColors[clamp(iSelection + 1.0, 0, fireColorCount - 1)];
					return float4(lerp(sel1, sel2, frac(selection)), 1.0);
				}
				else
				{
					return float4(fireColors[clamp(iSelection, 0, fireColorCount - 1)], 1.0);
				}
			}
			ENDHLSL
		}
	}
}