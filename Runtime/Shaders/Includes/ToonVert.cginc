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
	float4 uv0 : TEXCOORD0;
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

	float4 uv : TEXCOORD0;
	float4 uv1 : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float4 tangent : TEXCOORD3;
	float4 worldPos : TEXCOORD4;
	float4 localPos : TEXCOORD5;
	float4 lightmapUV : TEXCOORD6;
	float2 fogCoord: TEXCOORD7;
	UNITY_LIGHTING_COORDS(9,8)
	float3 bitangent : TEXCOORD10;
	float4 staticTexturePos : TEXCOORD11;
	float3 vertexLighting : TEXCOORD12;
	

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
		o.localPos = round_val(v.vertex);
		o.pos = UnityObjectToClipPos(o.localPos);
		o.uv.xy = (DO_TRANSFORM(v.uv0)) * o.pos.w;
		o.uv1 = float4(v.uv1,v.uv2);
		o.normal = UnityObjectToWorldNormal(round_val(float4(v.normal, 1.0)).xyz);
		float4 rounded_tangent = round_val(v.tangent);
		o.tangent.xyz = UnityObjectToWorldDir(rounded_tangent).xyz;
		o.tangent.w = rounded_tangent.w;
	}
	else
	{
		o.localPos = v.vertex;
		o.pos = UnityObjectToClipPos(o.localPos);
		o.uv.xy = DO_TRANSFORM(v.uv0);
		o.uv1 = float4(v.uv1,v.uv2);
		o.normal = UnityObjectToWorldNormal(v.normal);
		o.tangent.xyz = UnityObjectToWorldDir(v.tangent);
		o.tangent.w = v.tangent.w;
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

	o.worldPos = mul(unity_ObjectToWorld, o.localPos);
	
	#if defined(LIGHTMAP_ON)
	o.lightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif
	#ifdef DYNAMICLIGHTMAP_ON
	o.lightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
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
