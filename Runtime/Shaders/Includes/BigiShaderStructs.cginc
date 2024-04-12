#ifndef H_INCLUDE_BIGISHADER_STRUCT
#define H_INCLUDE_BIGISHADER_STRUCT

namespace b_light
{
	struct world_info
	{
		float3 worldLightDir;
		float4 worldLightColor;
		float3 viewDir;
		float3 worldPos;

		float3 normal;
		float2 shadowmapUv;
	};
}

#endif