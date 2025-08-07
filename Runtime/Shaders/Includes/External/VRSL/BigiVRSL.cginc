#ifndef BIGI_VRSLS_INCL
#define BIGI_VRSLS_INCL

#include <UnityLightingCommon.cginc>
#ifdef BIGI_VRSLGI_ENABLED
#include "./VRSLGI-ParameterSettings.cginc"
#endif
#include "../../Core/BigiShaderStructs.cginc"
#include "../../Core/BigiShaderParams.cginc"


#ifdef BIGI_AVATARDMX_ENABLED
//#include <UnityInstancing.cginc>
//#include "Assets/VRSL Addons/VRSL-AvatarCarePackage/VRSLDMX.cginc"

// TODO Maybe one day coordinated audiolink

#endif

namespace b_light
{
	void GetVRSLGI(const world_info wi, inout UnityIndirect result)
	{
		// Disabled, will probably be replaced with LV soon
		// had issues with the stencil mask not being overwritten by other avatars making this shader show through others
		#ifdef UNITY_PASS_FORWARDBASE
		#ifdef BIGI_VRSLGI_ENABLED
		if (_VRSLGIStrength > Epsilon)
		{
			b_vrslgi::setParams();
			result.diffuse += VRSLGI(wi.worldPos, wi.normal, 1.0 - wi.smoothness, wi.viewDir, wi.albedo,
									 float2(wi.oneMinusReflectivity, wi.smoothness), wi.shadowmapUvs.xy,
									 wi.ambientOcclusion);
		}
		#endif
		#endif
	}
}
#endif
