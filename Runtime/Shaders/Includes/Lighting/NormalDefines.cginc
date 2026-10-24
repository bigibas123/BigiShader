#ifndef BIGI_NORMAL_DEFINES_H
#define BIGI_NORMAL_DEFINES_H

#ifndef RECALC_NORMALS
	#ifdef GET_NORMAL

	#include "../Core/BigiGetColor.cginc"
	#include "./NormalUtils.cginc"
	#ifdef GET_2NDNORMAL
		#define RECALC_NORMALS(matCapUV) \
			i.normal = b_normalutils::recalculate_normals_double(i.normal, GET_NORMAL(GETUV), GET_2NDNORMAL(GETUV), i.tangent, i.bitangent, NORMAL_SCALE_VAR, NORMAL_2ND_SCALE_VAR); \
			float2 matCapUV = b_normalutils::calculateMatCapUv(i.normal, i.worldPos)
	#else
		#define RECALC_NORMALS(matCapUV) \
			i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent, i.bitangent, NORMAL_SCALE_VAR); \
			float2 matCapUV = b_normalutils::calculateMatCapUv(i.normal, i.worldPos)
	#endif

	#elif defined(GET_2NDNORMAL)

		#include "../Core/BigiGetColor.cginc"
		#include "./NormalUtils.cginc"
		#define RECALC_NORMALS(matCapUV) \
			i.normal = b_normalutils::recalculate_normals(i.normal, GET_2NDNORMAL(GETUV), i.tangent, i.bitangent, NORMAL_2ND_SCALE_VAR) \
			float2 matCapUV = b_normalutils::calculateMatCapUv(i.normal, i.worldPos)
			

	#else
		#include "./NormalUtils.cginc"
		#define RECALC_NORMALS(matCapUV) float2 matCapUV = b_normalutils::calculateMatCapUv(i.normal, i.worldPos)
	#endif
#endif

#endif