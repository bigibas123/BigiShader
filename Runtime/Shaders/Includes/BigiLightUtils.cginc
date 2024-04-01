#ifndef BIGI_LIGHT_UTILS_H
#define BIGI_LIGHT_UTILS_H

#include <UnityCG.cginc>
#include <UnityLightingCommon.cginc>
#include <UnityPBSLighting.cginc>
#include <AutoLight.cginc>


#ifndef Epsilon
#define Epsilon UNITY_HALF_MIN
#endif

namespace b_light
{
	// A macro instead of a function because this works on more types without having to overload it a bunch of times
	// ReSharper disable once CppInconsistentNaming
	#define doStep(val) smoothstep(lightthreshold, lightsmoothness+lightthreshold, val)

	struct world_info
	{
		float3 worldLightDir;
		float4 worldLightColor;
		float3 viewDir;
	};

	world_info setup_world(in float3 worldPos, in fixed attenuation)
	{
		world_info wi;
		
		#if defined(POINT)  || defined(POINT_COOKIE) || defined(SPOT)
		wi.worldLightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos);
		#else
		wi.worldLightDir = _WorldSpaceLightPos0.xyz;
		#endif
		
		wi.worldLightColor = _LightColor0.rgba * attenuation;
		wi.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
		return wi;
	}

	
	UnityLight CreateLight(const in world_info wi, const in float3 normal)
	{
		UnityLight light;
		light.color = wi.worldLightColor;
		light.dir = wi.worldLightDir;
		light.ndotl = DotClamped(normal, wi.worldLightDir);
		return light;
	}

	UnityIndirect CreateIndirectLight(in float3 vertexLightColor, in float3 normal) {
		UnityIndirect indirectLight;
		indirectLight.diffuse = vertexLightColor;
		indirectLight.specular = 0;
		
		#if defined(FORWARD_BASE_PASS)
			indirectLight.diffuse += max(0, ShadeSH9(float4(normal, 1)));
		#endif
		return indirectLight;
	}

	float4 get_lighting(in float3 normal, in float4 albedo, in float3 worldPos, in float3 vertexLightColor, in fixed attenuation)
	{
		normal = normalize(normal);
		const world_info wi = setup_world(worldPos, attenuation);
		

		float4 unity_pbs_output = UNITY_BRDF_PBS(
			albedo, float3(0.0, 0.0, 0.0),
			1.0, 1.0,
			normal, wi.viewDir,
			CreateLight(wi, normal), CreateIndirectLight(vertexLightColor, normal)
		);


		return saturate(unity_pbs_output);
	}


	//Unity.cginc Shade4PointLights 
	float3 bigi_Shade4PointLights(
		float4 lightPosX, float4 lightPosY, float4 lightPosZ,
		float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
		float4 lightAttenSq,
		float3 pos, float3 normal
	)
	{
		// to light vectors
		float4 toLightX = lightPosX - pos.x;
		float4 toLightY = lightPosY - pos.y;
		float4 toLightZ = lightPosZ - pos.z;
		// squared lengths
		float4 lengthSq = 0;
		lengthSq += toLightX * toLightX;
		lengthSq += toLightY * toLightY;
		lengthSq += toLightZ * toLightZ;
		// don't produce NaNs if some vertex position overlaps with the light
		lengthSq = max(lengthSq, 0.000001);

		// NdotL
		float4 ndotl = 0;
		ndotl += toLightX * normal.x;
		ndotl += toLightY * normal.y;
		ndotl += toLightZ * normal.z;
		// correct NdotL
		float4 corr = rsqrt(lengthSq);
		ndotl = max(float4(0, 0, 0, 0), ndotl * corr);
		// attenuation
		float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
		float4 diff = ndotl * atten;
		// final color
		float3 col = 0;
		col += lightColor0 * diff.x;
		col += lightColor1 * diff.y;
		col += lightColor2 * diff.z;
		col += lightColor3 * diff.w;
		return col;
	}

	float3 ProcessVertexLights(
		float4 lightPosX, float4 lightPosY, float4 lightPosZ,
		float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
		float4 lightAttenSq,
		float3 pos, float3 normal
	)
	{
		float3 ret = 0;

		//#ifdef VERTEXLIGHT_ON
		ret += bigi_Shade4PointLights(
			lightPosX, lightPosY, lightPosZ,
			lightColor0, lightColor1, lightColor2, lightColor3,
			lightAttenSq, pos, normal);
		//#endif

		return ret;
	}
}

#endif
