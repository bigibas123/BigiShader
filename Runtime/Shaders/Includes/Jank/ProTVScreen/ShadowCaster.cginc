#ifndef PART_SCR_SHADOWCASTER_INCLUDED
#define PART_SCR_SHADOWCASTER_INCLUDED

#define B_P_V2G v2f
#define B_P_USE_LINESTREAM
#define B_P_PRIMITIVE_RESTART_COUNT 9
#include "../Includes/Jank/ParticalizerDefines.cginc"


namespace b_particalizer
{
	void calc_min_step(inout min_step_obj output, const in v2f input[3], const in float4 point_counts)
	{
		B_P_MS_CALC(float4, pos, input, output, xyzw, point_counts);
		B_P_MS_CALC(float3, normal, input, output, xyz, point_counts);
	}

	void calc_v2g(inout v2f output, const in min_step_obj min_step, const in float4 coords,
	              const in float3 world_scale)
	{
		B_P_V_CALC(pos, min_step, output, xyzw, coords);
		B_P_V_CALC(normal, min_step, output, xyz, coords);
		struct
		{
			float4 vertex;
			float3 normal;
		} v;
		v.vertex = output.pos;
		v.normal = output.normal;
		TRANSFER_SHADOW_CASTER_NOPOS(output, output.pos)
	}
}

#include "../Includes/Jank/Particalizer.cginc"
#endif
