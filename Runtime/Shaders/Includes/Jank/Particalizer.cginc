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
                             inout B_P_STREAMTYPE<B_P_V2G> os,
                             uint instanceID : SV_GSInstanceID)
{
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);
	UNITY_SETUP_INSTANCE_ID(input[0]);

	const float3 scale = 1.0 / float3(
		length(unity_ObjectToWorld._m00_m10_m20),
		length(unity_ObjectToWorld._m01_m11_m21),
		length(unity_ObjectToWorld._m02_m12_m22)
	);

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
		glsl_mod(((float)instanceID), INSTANCE_COUNTS.x),
		glsl_mod(((float)instanceID) / INSTANCE_COUNTS.x, INSTANCE_COUNTS.y),
		glsl_mod(((float)instanceID) / INSTANCE_COUNTS.x / INSTANCE_COUNTS.y, INSTANCE_COUNTS.z),
		glsl_mod(((float)instanceID) / INSTANCE_COUNTS.x / INSTANCE_COUNTS.y/INSTANCE_COUNTS.z, INSTANCE_COUNTS.w)
	);
	// UNITY_UNROLL creates ~3300 instructions, without it's ~120. So I decided to avoid it
	// UNITY_LOOP adds a couple of instructions +~10 ish. Not too bad
	// UNITY_FASTOPT adds about the same as UNITY_LOOP
	#define FORSHORT(axis) for(float i##axis = 0; i##axis < POINT_COUNTS_PER_INSTANCE.axis; ++i##axis)

	#if B_P_PRIMITIVE_RESTART_COUNT != -1
	uint primitiveCount = 0;
	#endif

	#if POINT_COUNT_X > 1
	FORSHORT(x)
	{
		const float x = ix + (POINT_COUNTS_PER_INSTANCE.x * instanceIds.x);
		#else
	{
		const float x = 0.0;
		#endif

		#if POINT_COUNT_Y > 1
		FORSHORT(y)
		{
			const float y = iy + (POINT_COUNTS_PER_INSTANCE.y * instanceIds.y);
			#else
		{
			const float y = 0.0;
			#endif
			#if POINT_COUNT_Z > 1
			FORSHORT(z)
			{
				const float z = iz + (POINT_COUNTS_PER_INSTANCE.z * instanceIds.z);
			#else
			{
				const float z = 0.0;
				#endif

				#if POINT_COUNT_W > 1
				FORSHORT(w)
				{
					const float w = iw + (POINT_COUNTS_PER_INSTANCE.w * instanceIds.w);
				#else
				{
					const float w = 0.0;
					#endif

					B_P_V2G curVal;
					UNITY_INITIALIZE_OUTPUT(B_P_V2G, curVal);
					UNITY_TRANSFER_INSTANCE_ID(input[0], curVal);
					UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], curVal);
					b_particalizer::calc_v2g(curVal, min_step, float4(x, y, z, w), scale);
					os.Append(curVal);
					#if B_P_PRIMITIVE_RESTART_COUNT != -1
					if ((++primitiveCount) % B_P_PRIMITIVE_RESTART_COUNT == 0)
					{
						os.RestartStrip();
					}
					#endif
				}
			}
		}
	}
}

#else
#error "Particalizer defines should be included first and functions should be implemented"
#endif

#endif
