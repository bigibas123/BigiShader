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
	#define doStep(val) smoothstep(lightThreshold, lightSmoothness+lightThreshold, val)

	struct world_info
	{
		float3 worldLightDir;
		float4 worldLightColor;
		float3 viewDir;
		float3 worldPos;
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
		wi.worldPos = worldPos;
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

	float3 BoxProjection(
		float3 direction, float3 position,
		float4 cubemapPosition, float3 boxMin, float3 boxMax
	)
	{
		#if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
		#endif
		return direction;
	}

	UnityIndirect CreateIndirectLight(in world_info wi, in float3 vertexLightColor, in float3 normal,
									const in fixed minAmbient)
	{
		UnityIndirect indirectLight;
		indirectLight.diffuse = vertexLightColor;
		indirectLight.specular = 0;

		#if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(normal, 1)));

		float3 reflectionDir = reflect(-wi.viewDir, normal);
		Unity_GlossyEnvironmentData envData;
		//envData.roughness = 1 - _Smoothness;
		envData.roughness = 0.00;
		envData.reflUVW = BoxProjection(
			reflectionDir, wi.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		);
		envData.reflUVW = BoxProjection(
			reflectionDir, wi.worldPos,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);
		#if UNITY_SPECCUBE_BLENDING
		float interpolator = unity_SpecCube0_BoxMin.w;
		UNITY_BRANCH
		if (interpolator < 0.99999) {
			float3 probe1 = Unity_GlossyEnvironment(
				UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
				unity_SpecCube0_HDR, envData
			);
			indirectLight.specular = lerp(probe1, probe0, interpolator);
		}
		else {
			indirectLight.specular = probe0;
		}
		#else
		indirectLight.specular = probe0;
		#endif
		#endif
		//indirectLight.diffuse = max(indirectLight.diffuse, minAmbient);
		return indirectLight;
	}

	float4 _get_lighting(in float3 normal, in float3 worldPos, in float3 vertexLightColor, in fixed attenuation,
						in fixed minAmbient)
	{
		float3 albedo = float4(1.0, 1.0, 1.0, 1.0);
		float3 specularTint = float3(1.0, 1.0, 1.0);
		albedo *= 1.0;
		specularTint *= 0.00;

		normal = normalize(normal);
		const world_info wi = setup_world(worldPos, attenuation);

		float oneMinusReflectivity;
		albedo = EnergyConservationBetweenDiffuseAndSpecular(
			albedo, specularTint, oneMinusReflectivity
		);

		float4 unity_pbs_output = UNITY_BRDF_PBS(
			albedo, specularTint,
			oneMinusReflectivity, 0.0,
			normal, wi.viewDir,
			CreateLight(wi, normal), CreateIndirectLight(wi, vertexLightColor, normal, minAmbient)
		);

		float4 output = saturate(unity_pbs_output);
		//output = max(minAmbient,output);
		return output;
	}

	float4 get_lighting(in float3 normal, in float3 worldPos, in float3 vertexLightColor, in fixed4 ambientOcclusion,
						in fixed occlusionStrength, in fixed attenuation,
						in fixed minAmbient, in fixed transmissivity, in fixed lightSmoothness, in fixed lightThreshold)
	{
		attenuation = attenuation * lerp(1, ambientOcclusion.g, occlusionStrength);
		float4 total = _get_lighting(normal, worldPos, vertexLightColor, attenuation, minAmbient);
		if (transmissivity > Epsilon)
		{
			total += _get_lighting(normal * -1.0, worldPos, vertexLightColor, attenuation, 0) * transmissivity;
		}

		total = doStep(total);
		total.rgba = float4(
			max(minAmbient, total.r),
			max(minAmbient, total.g),
			max(minAmbient, total.b),
			max(minAmbient, total.a)
		);
		return total;
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
