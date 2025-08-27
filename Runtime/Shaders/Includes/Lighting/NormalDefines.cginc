#ifndef BIGI_NORMAL_DEFINES_H
#define BIGI_NORMAL_DEFINES_H

#ifndef RECALC_NORMALS
	#ifdef GET_NORMAL

	#include "../Core/BigiGetColor.cginc"
	#include "./NormalUtils.cginc"
	#ifdef GET_2NDNORMAL
		#define RECALC_NORMALS() i.normal = b_normalutils::recalculate_normals_double(i.normal, GET_NORMAL(GETUV), GET_2NDNORMAL(GETUV), i.tangent, i.bitangent)
	#else
		#define RECALC_NORMALS() i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent, i.bitangent)
	#endif

	#elif defined(GET_2NDNORMAL)

		#include "../Core/BigiGetColor.cginc"
		#include "./NormalUtils.cginc"
		#define RECALC_NORMALS() i.normal = b_normalutils::recalculate_normals(i.normal, GET_2NDNORMAL(GETUV), i.tangent, i.bitangent)

	#else
		#define RECALC_NORMALS()
	#endif
#endif

#endif