#ifndef BIGI_LIGHT_UTILS_H
#define BIGI_LIGHT_UTILS_H

#include <UnityCG.cginc>


#ifndef Epsilon
#define Epsilon UNITY_HALF_MIN
#endif

namespace b_light
{
	// A macro instead of a function because this works on more types without having to overload it a bunch of times
	// ReSharper disable once CppInconsistentNaming
	#define doStep(val) smoothstep(lightthreshold, lightsmoothness+lightthreshold, val)


	half3 GetAmbient(
		in const float3 worldPos,
		in const float3 worldNormal,
		in const float minAmbient,
		in const float4 ambientOcclusion
	)
	{
		//Maybe do lightmapping properly sometime, not today though because it broke a bunch of stuff.
		half3 ret = 0;
		ret += max(0, ShadeSH9(half4(worldNormal, 1)));


		ret *= clamp(ambientOcclusion, 0.75, 1.0);
		return ret;
	}

	fixed3 GetWorldLightIntensity(
		const in half shadowAttenuation,
		const in float3 worldLightPos,
		const in float3 worldNormal
	)
	{
		const float nl = max(0, dot(worldNormal, worldLightPos.xyz));
		const float lightIntensity = nl * shadowAttenuation;
		return lightIntensity;
	}

	half fade_shadow(
		in const float3 worldNormal,
		#ifdef LIGHTMAP_ON
        in const float2 lightmapUv,
		#endif
		in half attenuation
	)
	{
		#if defined(HANDLE_SHADOWS_BLENDING_IN_GI) || defined(ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS)
        float viewZ = dot(_WorldSpaceCameraPos - worldNormal, UNITY_MATRIX_V[2].xyz);
        float shadowFadeDistance = UnityComputeShadowFadeDistance(worldNormal, viewZ);
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
		#ifdef LIGHTMAP_ON
        float bakedAttenuation = UnitySampleBakedOcclusion(lightmapUv,worldNormal);
		#else
        float bakedAttenuation = 0;
		#endif
        attenuation = UnityMixRealtimeAndBakedShadows(
            attenuation, bakedAttenuation, shadowFade
        );
		#endif
		return attenuation;
	}
	

	fixed4 GetLighting_real(
		const in float3 worldLightPos,
		const in float3 worldPos,
		const in float3 worldNormal,
		const in half shadowAttenuation,
		const in half4 lightColor,
		const in bool secondPass,
		in float3 vertex,
		const in float reflectivity,
		#ifdef LIGHTMAP_ON
        const in float2 lightmapUv,
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
		const in float2 dynamicLightmapUV,
		#endif
		const in float minAmbient,
		const in float4 ambientOcclusion,
		const in float lightsmoothness,
		const in float lightthreshold
	)
	{
		if (secondPass)
		{
			vertex = 0;
		}

		const half3 ambient =
			GetAmbient(
				worldPos,
				worldNormal,
				minAmbient,
				ambientOcclusion
			);

		const float fadedAttenuation = fade_shadow(
			worldNormal,
			#ifdef LIGHTMAP_ON
			lightmapUv,
			#endif
			shadowAttenuation
		);
		
		float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
		half3 worldReflectionDir = reflect(-worldViewDir, worldNormal);
		half4 reflectionData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldReflectionDir);
		half3 reflectionColor = DecodeHDR(reflectionData, unity_SpecCube0_HDR);
		reflectionColor *= reflectivity;

		const float lightIntensity = GetWorldLightIntensity(fadedAttenuation, worldLightPos, worldNormal);
		const fixed3 diff = lightIntensity * lightColor;
		fixed4 total = fixed4(
			doStep(diff)
			+ doStep(ambient)
			+ doStep(reflectionColor)
			+ doStep(vertex)
			, 1.0
		);

		#ifdef UNITY_PASS_FORWARDBASE
		total = max(total, half4(minAmbient, minAmbient, minAmbient,1.0));
		#endif
		return clamp(total, -10.0, 5.0);
	}


	fixed4 GetLighting(
		const in float3 worldLightPos,
		const in float3 worldPos,
		const in float3 worldNormal,
		const in half shadowAttenuation,
		const in half4 lightColor,
		const in float3 vertex,
		const in float reflectivity,
		#ifdef LIGHTMAP_ON
		const in float2 lightmapUv,
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
		const in float2 dynamicLightmapUV,
		#endif
		const in float minAmbient,
		const in float4 ambientOcclusion,
		const in float lightsmoothness,
		const in float lightthreshold,
		const in float transmissivity
	)
	{
		fixed4 ret = 0;
		ret += GetLighting_real(
			worldLightPos,
			worldPos,
			worldNormal,
			shadowAttenuation,
			lightColor,
			false,
			vertex,
			reflectivity,
			#ifdef LIGHTMAP_ON
		lightmapUv,
			#endif
			#ifdef DYNAMICLIGHTMAP_ON
		dynamicLightmapUV,
			#endif
			minAmbient,
			ambientOcclusion,
			lightsmoothness,
			lightthreshold
		);
		if (transmissivity > Epsilon)
		{
			ret += GetLighting_real(
				worldLightPos,
				worldPos,
				worldNormal * -1,
				shadowAttenuation,
				lightColor,
				true,
				vertex,
				reflectivity,
				#ifdef LIGHTMAP_ON
				lightmapUv,
				#endif
				#ifdef DYNAMICLIGHTMAP_ON
				dynamicLightmapUV,
				#endif
				0.0,
				ambientOcclusion,
				lightsmoothness,
				lightthreshold
			) * transmissivity;
		}
		return clamp(ret, -10.0, 5.0);
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
