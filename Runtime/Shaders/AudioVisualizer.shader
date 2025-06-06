Shader "Bigi/AudioVisualizer" {
	Properties {
		_Size ("Size", Range(0.0,0.0025)) = 0.01
		_Spacing ("Spacing", Range(0.0, 1.0)) = 0.1
		_AudioMult("Audio multiplier",Range(0.0,100.0)) = 5.0
	}
	SubShader {
		Tags {
			"RenderType"="Opaque"
			"PreviewType" = "Plane"
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
			#pragma target 5.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include <UnityCG.cginc>
			#include <Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc>

			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2g
			{
				UNITY_POSITION(vertex);
				float audioValue : BLENDWEIGHT;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct g2f
			{
				UNITY_POSITION(vertex);
				float audioValue : BLENDWEIGHT;
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
				o.audioValue = 0.0;
				return o;
			}

			#define UnitIfy(prop) res.prop = normalize(res.prop)

			v2g getMiddleV2g(const in v2g a, const in v2g b, const in v2g c)
			{
				v2g res;
				UNITY_INITIALIZE_OUTPUT(v2g, res);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(a, res);
				res.vertex = ((a.vertex + b.vertex + c.vertex) / 3.0);
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
				res.vertex = UnityObjectToClipPos(a.vertex);
				res.audioValue = a.audioValue;
				return res;
			}

			void addTriangleC(const in v2g a, const in v2g b, const in v2g c, inout TriangleStream<g2f> outStream)
			{
				addTriangle(v2gToG2f(a), v2gToG2f(b), v2gToG2f(c), outStream);
			}

			struct quadContainer
			{
				v2g bottomLeft;
				v2g topLeft;
				v2g bottomRight;
				v2g upRight;
			};

			void addQuad(const in quadContainer qq, inout TriangleStream<g2f> os)
			{
				addTriangleC(qq.bottomLeft, qq.topLeft, qq.bottomRight, os);
				addTriangleC(qq.topLeft, qq.upRight, qq.bottomRight, os);
			}

			uniform float _AudioMult;

			quadContainer makeVertQuad(v2g m, const in float size)
			{
				quadContainer res;
				res.bottomLeft = m;
				res.bottomLeft.vertex.x -= size;
				res.bottomLeft.vertex.y -= size;

				res.bottomRight = m;
				res.bottomRight.vertex.x -= size;
				res.bottomRight.vertex.y += size;

				res.topLeft = m;
				res.topLeft.vertex.x += (size * m.audioValue * _AudioMult);
				res.topLeft.vertex.y -= size;

				res.upRight = m;
				res.upRight.vertex.x += (size * m.audioValue * _AudioMult);
				res.upRight.vertex.y += size;
				return res;
			}

			uniform float _Size;
			uniform float _Spacing;
			#define INSTANCE_COUNT (32)
			#define QUAD_COUNT (AUDIOLINK_ETOTALBINS / INSTANCE_COUNT)
			#define TOTAL_QUADS (INSTANCE_COUNT * QUAD_COUNT)

			#define SIZE (_Size)
			#define SPACING (SIZE * 2.0 * (_Spacing + 1.0))

			[instance(INSTANCE_COUNT)]
			[maxvertexcount(6 * QUAD_COUNT * 2)]
			void geom(
				triangle v2g input[3], uint pid : SV_PrimitiveID,
				inout TriangleStream<g2f> os,
				uint i : SV_GSInstanceID
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);
				v2g middle = getMiddleV2g(input[0], input[1], input[2]);
				for (int j = 0; j <= QUAD_COUNT; ++j)
				{
					uint total = j + (i * QUAD_COUNT);
					v2g m = middle;
					m.vertex.y += (((int)total) - (TOTAL_QUADS / 2)) * SPACING;
					float4 audio = AudioLinkLerpMultiline(
						ALPASS_DFT + float2((total * AUDIOLINK_ETOTALBINS) / TOTAL_QUADS, 0));
					m.audioValue = audio.b + audio.g + audio.r;

					quadContainer main = makeVertQuad(m,SIZE);
					addQuad(main, os);
				}
			}

			#include "./Includes/ColorUtil.cginc"

			float4 frag(const g2f i) : SV_Target
			{
				float3 a = HSVToRGB(clamp(i.audioValue / 2.5, 0.0, 1.0), 1.0, 1.0);
				return float4(a, 1.0);
			}
			ENDCG
		}
	}
}