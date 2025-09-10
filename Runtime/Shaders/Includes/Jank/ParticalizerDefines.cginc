#ifndef PARTICALIZER_DEFINES_INCLUDED
#define PARTICALIZER_DEFINES_INCLUDED
#ifdef B_P_V2G
namespace b_particalizer
{
	struct min_step_obj
	{
		B_P_V2G min;
		B_P_V2G step;
	};
	#ifndef B_P_CALC
		#define B_P_MS_CALC(type, name, input, output, swizzle, point_counts) {\
			type vMin = min(input[0].name,min(input[1].name,input[2].name));\
			type vMax = max(input[0].name,max(input[1].name,input[2].name));\
			output.min.name = vMin;\
			output.step.name = ((vMax - vMin) / point_counts.swizzle);\
			}
	#endif

	#ifndef B_P_V_CALC
		#define B_P_V_CALC(name, min_step, output, swizzle, coords) {\
		output.name = (min_step.min.name + (coords.swizzle * min_step.step.name));\
		}
	#endif

	void calc_min_step(inout min_step_obj output, const in B_P_V2G input[3], const in float4 point_counts);

	void calc_v2g(inout B_P_V2G output, const in min_step_obj min_step, const in float4 coords, const in float3 world_scale);
}


#else
#error "Particalizer requires B_P_V2G Define
#endif

#ifndef POINT_COUNT_X
#define POINT_COUNT_X 64
#endif
#ifndef INSTANCE_COUNT_X
#define INSTANCE_COUNT_X 8
#endif

#ifndef POINT_COUNT_Y
#define POINT_COUNT_Y 36
#endif
#ifndef INSTANCE_COUNT_Y
#define INSTANCE_COUNT_Y 4
#endif

#ifndef POINT_COUNT_Z
#define POINT_COUNT_Z 1
#endif
#ifndef INSTANCE_COUNT_Z
#define INSTANCE_COUNT_Z 1
#endif

#ifndef POINT_COUNT_W
#define POINT_COUNT_W 1
#endif
#ifndef INSTANCE_COUNT_W
#define INSTANCE_COUNT_W 1
#endif

#define POINT_COUNTS (float4(POINT_COUNT_X, POINT_COUNT_Y, POINT_COUNT_Z, POINT_COUNT_W))
#define POINT_COUNT_TOTAL (POINT_COUNT_X * POINT_COUNT_Y * POINT_COUNT_Z * POINT_COUNT_W)

#define INSTANCE_COUNTS (float4(INSTANCE_COUNT_X,INSTANCE_COUNT_Y,INSTANCE_COUNT_Z,INSTANCE_COUNT_W))
#define INSTANCE_COUNT_TOTAL (INSTANCE_COUNT_X * INSTANCE_COUNT_Y * INSTANCE_COUNT_Z * INSTANCE_COUNT_W)

#define POINT_COUNTS_PER_INSTANCE (POINT_COUNTS/INSTANCE_COUNTS)
#define POINT_COUNT_PER_INSTANCE_TOTAL (POINT_COUNT_TOTAL / INSTANCE_COUNT_TOTAL)


#endif
