#ifndef PART_SCR_META_INCLUDED
#define PART_SCR_META_INCLUDED

#define B_P_V2G v2f_meta
#include "../ParticalizerDefines.cginc"
#include "./TexSample.cginc"

namespace b_particalizer
{
	void calc_min_step(inout min_step_obj output, const in v2f_meta input[3], const in float4 point_counts)
	{
		B_P_MS_CALC(float4, pos, input, output, xyzw, point_counts);
		B_P_MS_CALC(float4, uv, input, output, xyzw, point_counts);
		#ifdef EDITOR_VISUALIZATION
			B_P_MS_CALC(float2, vizUV, input, output, xy, point_counts);
			B_P_MS_CALC(float4, lightCoord, input, output, xyzw, point_counts);
		#endif
	}

	void calc_v2g(inout v2f_meta output, const in min_step_obj min_step, const in float4 coords,
	              const in float3 world_scale)
	{
		B_P_V_CALC(pos, min_step, output, xyzw, coords);
		B_P_V_CALC(uv, min_step, output, xyzw, coords);
		#ifdef EDITOR_VISUALIZATION
			B_P_V_CALC(vizUV, min_step,output, xy, point_counts);
			B_P_V_CALC(lightCoord, min_step,output, xyzw, point_counts);
		#endif
		output.pos += GetOffset(output);
		//UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
		#if !defined(EDITOR_VISUALIZATION)
			output.pos = UnityMetaVertexPosition(output.pos, output.uv.xy, output.uv.zw, unity_LightmapST,
			                                     unity_DynamicLightmapST);
		#else
			output.pos = UnityObjectToClipPos(output.pos);
		#endif
	}
}

#include "../Particalizer.cginc"

#endif
