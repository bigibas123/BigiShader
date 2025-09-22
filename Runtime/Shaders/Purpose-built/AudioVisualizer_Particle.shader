Shader "Bigi/AudioVisualizer(Particle)" {
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
			HLSLPROGRAM
			#pragma target 5.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag
			#include_with_pragmas "../Includes/Pragmas/ForwardBase.cginc"
			#include <UnityCG.cginc>
			#include <UnityInstancing.cginc>
			#include <Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc>

			#define BIGI_DEFAULT_APPDATA_DEFINED
			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#define BIGI_DEFAULT_V2F_DEFINED
			struct v2g
			{
				UNITY_POSITION(vertex);
				float audioValue : BLENDWEIGHT;
				float pointSize: PSIZE0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct g2f
			{
				UNITY_POSITION(vertex);
				float audioValue : BLENDWEIGHT;
				float pointSize: PSIZE0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#pragma target 5.0
			#pragma fragmentoption ARB_precision_hint_fastest
			CBUFFER_START(UnityPerMaterial)
			uniform float _AudioMult;
			uniform float _Size;
			uniform float _Spacing;
			CBUFFER_END
			#define INSTANCE_COUNT (32)
			#define QUAD_COUNT (AUDIOLINK_ETOTALBINS / INSTANCE_COUNT)
			#define TOTAL_QUADS (INSTANCE_COUNT * QUAD_COUNT)

			#define SIZE (_Size)
			#define SPACING (SIZE * 2.0 * (_Spacing + 1.0))

			#include "../Includes/Lighting/BigiLightUtils.cginc"
			#include "../Includes/ColorUtil.cginc"

			v2g vert(appdata v)
			{
				v2g o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2g, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = v.vertex;
				o.audioValue = 0.0;
				o.pointSize = 1024.0;
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

			void addTriangle(in g2f a, in g2f b, in g2f c, inout PointStream<g2f> outStream)
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
				res.pointSize = a.pointSize;
				return res;
			}

			void addTriangleC(const in v2g a, const in v2g b, const in v2g c, inout PointStream<g2f> outStream)
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

			void addQuad(const in quadContainer qq, inout PointStream<g2f> os)
			{
				addTriangleC(qq.bottomLeft, qq.topLeft, qq.bottomRight, os);
				addTriangleC(qq.topLeft, qq.upRight, qq.bottomRight, os);
			}

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

			[instance(INSTANCE_COUNT)]
			[maxvertexcount(6 * QUAD_COUNT * 2)]
			void geom(
				triangle v2g input[3], uint pid : SV_PrimitiveID,
				inout PointStream<g2f> os,
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

			fragOutput frag(g2f i)
			{
				fragOutput o;
				UNITY_INITIALIZE_OUTPUT(fragOutput, o);
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				float3 a = HSVToRGB(clamp(i.audioValue / 2.5, 0.0, 1.0), 1.0, 1.0);
				o.color.rgb = a;
				o.color.a = 1.0;
				return o;
			}
			ENDHLSL
		}
	}
}