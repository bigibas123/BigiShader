#ifndef H_INCLUDE_BIGISHADER_STRUCT
#define H_INCLUDE_BIGISHADER_STRUCT

#ifndef Epsilon
#include <UnityCG.cginc>
#define Epsilon UNITY_HALF_MIN
#endif

#ifndef BIGI_LIGHT_BLIGHT_DEFINED
#define BIGI_LIGHT_BLIGHT_DEFINED
namespace b_light
{
	struct world_info
	{
		float3 worldLightDir;
		float4 worldLightColor;
		float3 viewDir;
		float3 worldPos;

		float3 normal;
		float4 shadowmapUvs;
	};
}
#endif

#ifndef BIGI_DEFAULT_APPDATA_DEFINED
#define BIGI_DEFAULT_APPDATA_DEFINED

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 uv0 : TEXCOORD0;
	float4 color : COLOR;
	float2 uv1 : TEXCOORD1; //Lightmap Uvs
	float2 uv2 : TEXCOORD2; //Realtime lightmap Uvs
	float2 uv3 : TEXCOORD3;
	uint vertexId : SV_VertexID;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
#endif

#ifndef BIGI_DEFAULT_V2F_DEFINED
#define BIGI_DEFAULT_V2F_DEFINED
#include <UnityCG.cginc>
#include <AutoLight.cginc>
#include <UnityInstancing.cginc>

//intermediate
struct v2f
{
	UNITY_POSITION(pos); //float4 pos : SV_POSITION;

	float4 uv : TEXCOORD0;
	float4 uv1 : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float4 tangent : TEXCOORD3;
	float4 worldPos : TEXCOORD4;
	float4 localPos : TEXCOORD5;
	float4 lightmapUV : TEXCOORD6;
	UNITY_FOG_COORDS(7)
	UNITY_LIGHTING_COORDS(9,8)
	float3 bitangent : TEXCOORD10;
	float4 staticTexturePos : TEXCOORD11;
	float3 vertexLighting : TEXCOORD12;
	

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
#endif


#ifndef BIGI_DEFAULT_FRAGOUT_DEFINED
#define BIGI_DEFAULT_FRAGOUT_DEFINED
#include <HLSLSupport.cginc>
struct fragOutput {
	fixed4 color : SV_Target;
};
#endif

#endif