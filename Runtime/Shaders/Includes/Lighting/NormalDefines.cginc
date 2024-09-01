#ifndef BIGI_NORMAL_DEFINES_H
#define BIGI_NORMAL_DEFINES_H

#ifndef RECALC_NORMALS
	#ifdef NORMAL_MAPPING
	#include "../Core/BigiGetColor.cginc"
	#include "./NormalUtils.cginc"
	#define RECALC_NORMALS() i.normal = b_normalutils::recalculate_normals(i.normal, GET_NORMAL(GETUV), i.tangent, i.bitangent)
	#else
	#define RECALC_NORMALS()
	#endif
#endif

#endif