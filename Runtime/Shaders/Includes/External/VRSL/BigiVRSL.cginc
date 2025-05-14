#ifndef BIGI_VRSLS_INCL
#define BIGI_VRSLS_INCL

#include <UnityLightingCommon.cginc>
#include "./VRSLGI-ParameterSettings.cginc"
#include "../../Core/BigiShaderStructs.cginc"
#include "../../Core/BigiShaderParams.cginc"


#ifdef BIGI_AVATARDMX_ENABLED
//#include <UnityInstancing.cginc>
//#include "Assets/VRSL Addons/VRSL-AvatarCarePackage/VRSLDMX.cginc"

//TODO figure out some standard fixtures, or wait for OMF and grab that if it ever comes out

#endif

namespace b_light
{
	void GetVRSLGI(const world_info wi, inout UnityIndirect result)
	{
		#ifdef UNITY_PASS_FORWARDBASE
		b_vrslgi::setParams();
		result.diffuse += VRSLGI(wi.worldPos, wi.normal, 1.0 - wi.smoothness, wi.viewDir, wi.albedo,
		                         float2(wi.oneMinusReflectivity, wi.smoothness), wi.shadowmapUvs.xy,
		                         wi.ambientOcclusion);
		#endif
	}
}
#endif
