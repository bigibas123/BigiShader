#ifndef BIGI_TOONVERT_INCL
#define BIGI_TOONVERT_INCL


#include <UnityCG.cginc>
#include <AutoLight.cginc>
#include "./LightUtilsDefines.cginc"

#ifndef BIGI_DEFAULT_FRAGOUT
#define BIGI_DEFAULT_FRAGOUT
struct fragOutput {
    fixed4 color : SV_Target;
};
#endif
#ifndef BIGI_DEFAULT_APPDATA
#define BIGI_DEFAULT_APPDATA

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 texcoord : TEXCOORD0;
	float4 color : COLOR;
	float2 uv1 : TEXCOORD1; //Lightmap Uvs
	float2 uv2 : TEXCOORD2; //Realtime lightmap Uvs
	float2 uv3 : TEXCOORD3;
	uint vertexId : SV_VertexID;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
#endif

//intermediate
struct v2f
{
	UNITY_POSITION(pos); //float4 pos : SV_POSITION;

	float3 normal : NORMAL; //(World) Normal
	half2 uv : TEXCOORD0; //texture coordinates
	UNITY_LIGHTING_COORDS(1, 2)
	UNITY_FOG_COORDS(3)
	float4 staticTexturePos : TEXCOORD4;
	float3 worldPos: TEXCOORD5;
	float3 tangent : TEXCOORD6; // vect in left direction of texture coordinates
	float3 bitangent : TEXCOORD7; // vect in up direction of texture coordinates
	float3 vertexLighting : TEXCOORD8;
	#if defined(LIGHTMAP_ON) || defined(ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS)
	float2 lightmapUV : TEXCOORD9;
	#endif
	#if defined(DYNAMICLIGHTMAP_ON)
	float2 dynamicLightmapUV : TEXCOORD10;
	#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

#ifndef BIGI_V1_TOONVERTSHADER
#define BIGI_V1_TOONVERTSHADER

float4 round_val(float4 snapToPixel)
{
	float gridSize = 1.0 / (_Rounding + Epsilon);
	float4 vt = snapToPixel;
	vt.xyz = snapToPixel.xyz / snapToPixel.w;
	vt.xy = floor(gridSize * vt.xy) / gridSize;
	vt.xyz *= snapToPixel.w;
	return vt;
}


v2f bigi_toon_vert(appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


	if (_Rounding > Epsilon)
	{
		o.pos = UnityObjectToClipPos(round_val(v.vertex));
		o.uv = (DO_TRANSFORM(v.texcoord)) * o.pos.w;
		o.normal = UnityObjectToWorldNormal(round_val(float4(v.normal, 1.0)).xyz);
		o.tangent = UnityObjectToWorldDir(round_val(v.tangent));
	}
	else
	{
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = (DO_TRANSFORM(v.texcoord));
		o.normal = UnityObjectToWorldNormal(v.normal);
		o.tangent = UnityObjectToWorldDir(v.tangent);
	}
	const float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.bitangent = cross(o.normal, o.tangent) * tangentSign;


	#if defined(DIRECTIONAL) || defined(POINT) || defined(SPOT) || defined(DIRECTIONAL) || defined(POINT_COOKIE) || defined(DIRECTIONAL_COOKIE)
	o._ShadowCoord = 0;
	#endif


	UNITY_TRANSFER_SHADOW(o, v.uv1)
	UNITY_TRANSFER_LIGHTING(o, v.uv1)
	UNITY_TRANSFER_FOG(o, o.pos);
	o.staticTexturePos = ComputeScreenPos(o.pos);
	//TODO make this object space relative or something?
	// Update: Orels has a shader that I can checkout: https://shaders.orels.sh/docs/ui/layered-parallax

	o.worldPos = UnityObjectToWorldDir(v.vertex);

	#if defined(LIGHTMAP_ON) || defined(ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS)
		o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
	o.dynamicLightmapUV =
		v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif

	#ifdef VERTEXLIGHT_ON
    BIGI_GETLIGHT_VERTEX(vlight);
    o.vertexLighting = vlight;
	#else
	o.vertexLighting = 0;
	#endif
	
	return o;
}
#endif
#endif
