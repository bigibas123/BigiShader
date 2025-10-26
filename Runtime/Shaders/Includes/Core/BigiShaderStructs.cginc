#ifndef H_INCLUDE_BIGISHADER_STRUCT
#define H_INCLUDE_BIGISHADER_STRUCT

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

		float smoothness;
		float oneMinusReflectivity;
		float ambientOcclusion;
		float3 albedo;
		float3 specular;
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
	#ifdef UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_INPUT_INSTANCE_ID
	#else
	#warning "Instancing not enabled"
	#endif
};
#endif

#ifndef BIGI_DEFAULT_V2F_DEFINED
#define BIGI_DEFAULT_V2F_DEFINED
#include <UnityCG.cginc>
#include <AutoLight.cginc>

//intermediate
struct v2f
{
	UNITY_POSITION(pos); //float4 pos : SV_POSITION;

	float4 uv : TEXCOORD0;
	//float4 uv1 : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float4 tangent : TEXCOORD3;
	float4 worldPos : TEXCOORD4;
	float4 lightmapUV : TEXCOORD5;
	UNITY_FOG_COORDS(6)
	UNITY_LIGHTING_COORDS(8, 7)
	float3 bitangent : TEXCOORD9;
	float4 staticTexturePos : TEXCOORD10;
	#ifdef VERTEXLIGHT_ON
	float3 vertexLighting : TEXCOORD11;
	#endif
	float4 distance : POSITION1; // barycentric coordinates (xyz) and distance from arbitrary point (w)

	#ifdef UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_INPUT_INSTANCE_ID
	#else
	#warning "Instancing not enabled"
	#endif
	#ifdef 	UNITY_VERTEX_OUTPUT_STEREO
	UNITY_VERTEX_OUTPUT_STEREO
	#else
	#warning "Instancing not enabled"
	#endif
};
#endif

#ifndef BIGI_DEFAULT_AL_MODES_DEFINED
#define BIGI_DEFAULT_AL_MODES_DEFINED
#define AudioLinkMode_e uint
namespace b_sound
{
	namespace AudioLinkMode
	{
		const static AudioLinkMode_e ALM_Off = 0;
		const static AudioLinkMode_e ALM_Flat = 1;
		const static AudioLinkMode_e ALM_CenterOut = 2;
		const static AudioLinkMode_e ALM_WireFrame = 3;
	}
}
#endif


#ifndef BIGI_DEFAULT_FRAGOUT_DEFINED
#define BIGI_DEFAULT_FRAGOUT_DEFINED
#include <HLSLSupport.cginc>
struct fragOutput {
	fixed4 color : SV_Target;
};
#endif

#endif