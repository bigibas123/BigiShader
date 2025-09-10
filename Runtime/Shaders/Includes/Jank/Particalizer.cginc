#ifndef PARTICALIZER_INCLUDED
#define PARTICALIZER_INCLUDED

#if defined(PARTICALIZER_DEFINES_INCLUDED)

#ifndef glsl_mod
#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
#endif


#include <UnityInstancing.cginc>
#include <UnityShaderUtilities.cginc>

[instance(INSTANCE_COUNT_TOTAL)]
[maxvertexcount(POINT_COUNT_PER_INSTANCE_TOTAL)]
void b_particalizer_geomBase(triangle B_P_V2G input[3], uint pid : SV_PrimitiveID,
                             inout PointStream<B_P_V2G> os,
                             uint instanceID : SV_GSInstanceID)
{
	const float3 scale = 1.0 / float3(
		length(unity_ObjectToWorld._m00_m10_m20),
		length(unity_ObjectToWorld._m01_m11_m21),
		length(unity_ObjectToWorld._m02_m12_m22)
	);

	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);
	UNITY_SETUP_INSTANCE_ID(input[0]);
	b_particalizer::min_step_obj min_step;
	UNITY_INITIALIZE_OUTPUT(b_particalizer::min_step_obj, min_step);
	
	UNITY_INITIALIZE_OUTPUT(B_P_V2G, min_step.step);
	UNITY_INITIALIZE_OUTPUT(B_P_V2G, min_step.min);
	
	UNITY_TRANSFER_INSTANCE_ID(input[0], min_step.step);
	UNITY_TRANSFER_INSTANCE_ID(input[0], min_step.min);
	
	UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], min_step.step);
	UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], min_step.min);

	b_particalizer::calc_min_step(min_step, input, POINT_COUNTS);


	float4 instanceIds = int4(
		glsl_mod(instanceID, INSTANCE_COUNTS.x),
		glsl_mod(instanceID / INSTANCE_COUNTS.x, INSTANCE_COUNTS.y),
		glsl_mod(instanceID / INSTANCE_COUNTS.x / INSTANCE_COUNTS.y,
		         INSTANCE_COUNTS.z),
		glsl_mod(
			instanceID / INSTANCE_COUNTS.x / INSTANCE_COUNTS.y/
			INSTANCE_COUNTS.z, INSTANCE_COUNTS.w)
	);

	#define FORSHORT(axis) UNITY_UNROLL for(float i##axis = 0; i##axis < POINT_COUNTS_PER_INSTANCE.axis; ++i##axis)

	FORSHORT(x)
	{
		float x = ix + (POINT_COUNTS_PER_INSTANCE.x * instanceIds.x);
		FORSHORT(y)
		{
			float y = iy + (POINT_COUNTS_PER_INSTANCE.y * instanceIds.y);
			FORSHORT(z)
			{
				float z = iz + (POINT_COUNTS_PER_INSTANCE.z * instanceIds.z);

				FORSHORT(w)
				{
					float w = iw + (POINT_COUNTS_PER_INSTANCE.w * instanceIds.w);

					B_P_V2G curVal;
					UNITY_INITIALIZE_OUTPUT(B_P_V2G, curVal);
					UNITY_TRANSFER_INSTANCE_ID(input[0], curVal);
					UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], curVal);
					b_particalizer::calc_v2g(curVal, min_step, float4(x, y, z, w));
					os.Append(curVal);
					os.RestartStrip();
				}
			}
		}
	}
}

#else
#error "Particalizer defines should be included first and functions should be implemented"
#endif

#endif
