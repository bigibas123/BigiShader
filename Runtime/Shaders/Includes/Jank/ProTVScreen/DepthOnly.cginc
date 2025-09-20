#ifndef PART_SCR_DEPTHONLY_INCLUDED
#define PART_SCR_DEPTHONLY_INCLUDED

#define B_P_V2G fragdata
#define B_P_USE_LINESTREAM
#define B_P_PRIMITIVE_RESTART_COUNT 9
#include "../Includes/Jank/ParticalizerDefines.cginc"
#include "./TexSample.cginc"

namespace b_particalizer
{
	void calc_min_step(inout min_step_obj output, const in fragdata input[3], const in float4 point_counts)
	{
		B_P_MS_CALC(float4, vertex, input, output, xyzw, point_counts);
		B_P_MS_CALC(float2, uv, input, output, xy, point_counts);
	}

	void calc_v2g(inout fragdata output, const in min_step_obj min_step, const in float4 coords,
	              const in float3 world_scale)
	{
		B_P_V_CALC(vertex, min_step, output, xyzw, coords);
		B_P_V_CALC(uv, min_step, output, xy, coords);
		output.vertex += GetOffset(output);
		output.vertex = UnityObjectToClipPos(output.vertex);
	}
}

#include "../Includes/Jank/Particalizer.cginc"
#endif
