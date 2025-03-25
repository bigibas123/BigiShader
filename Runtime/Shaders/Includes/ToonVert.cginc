#ifndef BIGI_TOONVERT_INCL
#define BIGI_TOONVERT_INCL
#include <UnityCG.cginc>
#include <AutoLight.cginc>

#include "./Core/BigiShaderStructs.cginc"
#include "./Core/BigiShaderParams.cginc"
#include "./Core/BigiMainTex.cginc"
#include "./Lighting/LightUtilsDefines.cginc"
#include "./Effects/LengthDefine.cginc"

#ifdef MIRROR_THING
#include "./ScruffyRufflesAndMerlinDerivatives.cginc"
#endif

#ifndef BIGI_V1_TOONVERTSHADER
#define BIGI_V1_TOONVERTSHADER

float4 round_val(const in float4 snapToPixel, const uniform in float rounding)
{
	float gridSize = 1.0 / (rounding + Epsilon);
	float4 vt = snapToPixel;
	vt.xyz = snapToPixel.xyz / snapToPixel.w;
	vt.xy = floor(gridSize * vt.xy) / gridSize;
	vt.xyz *= snapToPixel.w;
	return vt;
}

v2f do_v2fCalc(in v2f o, const in appdata v)
{
	#ifdef ROUNDING_ENABLED
	if (ROUNDING_VAR_NAME > Epsilon)
	{
		//o.localPos = round_val(v.vertex, ROUNDING_VAR_NAME);
		o.pos = UnityObjectToClipPos(round_val(v.vertex, ROUNDING_VAR_NAME));
		o.uv.xy = (DO_TRANSFORM(v.uv0));// * o.pos.w;
		//o.uv1 = float4(v.uv1, v.uv2);
		o.normal = UnityObjectToWorldNormal(round_val(float4(v.normal, 1.0), ROUNDING_VAR_NAME).xyz);
		float4 rounded_tangent = round_val(v.tangent, ROUNDING_VAR_NAME);
		o.tangent.xyz = UnityObjectToWorldDir(rounded_tangent).xyz;
		o.tangent.w = rounded_tangent.w;
		o.worldPos = mul(unity_ObjectToWorld, round_val(v.vertex, ROUNDING_VAR_NAME));
	}
	else
	{
		//o.localPos = v.vertex;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = DO_TRANSFORM(v.uv0);
		//o.uv1 = float4(v.uv1, v.uv2);
		o.normal = UnityObjectToWorldNormal(v.normal);
		o.tangent.xyz = UnityObjectToWorldDir(v.tangent);
		o.tangent.w = v.tangent.w;
		o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	}
	#else
	//o.localPos = v.vertex;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.xy = DO_TRANSFORM(v.uv0);
	//o.uv1 = float4(v.uv1, v.uv2);
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.tangent.xyz = UnityObjectToWorldDir(v.tangent);
	o.tangent.w = v.tangent.w;
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	#endif
	o.distance = GET_DISTANCE(v.vertex);
	return o;
}

v2f bigi_toon_vert(appdata v)
{
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o = do_v2fCalc(o, v);

	o.uv.zw = v.uv0.zw;
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

	o.lightmapUV.xy = v.uv1.xy; // * unity_LightmapST.xy + unity_LightmapST.zw;
	o.lightmapUV.zw = v.uv2.xy; // * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	BIGI_GETLIGHT_VERTEX(o);

	#ifdef MIRROR_THING
	// Neitri
	// UNITY_BRANCH
	// if (_DoMirrorThing && IsInMirror())
	// {
	// 	// https://docs.microsoft.com/en-us/windows/win32/direct3d9/viewports-and-clipping
	// 	o.pos.z = min(o.pos.z, o.pos.w);
	// }

	// d4rkpl4y3r
	UNITY_BRANCH
	if(IsInMirror())
	{
		o.pos.z = o.pos.w / pow(1 + length(_WorldSpaceCameraPos - o.worldPos.xyz), .01);
	}
	#endif
	return o;
}
#endif
#endif
