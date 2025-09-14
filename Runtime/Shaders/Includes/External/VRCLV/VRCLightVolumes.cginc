#ifndef H_BIGI_VRC_LIGHT_VOLUMES_INCL
#define H_BIGI_VRC_LIGHT_VOLUMES_INCL
// Query VRC Lightvolumes (by RED_SIM) for light volumes
#ifdef UNITY_PASS_FORWARDBASE
#include <Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc>

#include "../../Core/BigiShaderStructs.cginc"
#include "../../Core/BigiShaderParams.cginc"
#endif

namespace b_light
{
	void GetLightVolumesLighting(const in world_info wi, inout UnityIndirect result)
	{
		#ifdef UNITY_PASS_FORWARDBASE
		if (_UdonLightVolumeEnabled && _UdonLightVolumeCount > 0)
		{
			float3 L0 = float3(0, 0, 0);
			float3 L1r = float3(0, 0, 0);
			float3 L1g = float3(0, 0, 0);
			float3 L1b = float3(0, 0, 0);

			LightVolumeSH(wi.worldPos, L0, L1r, L1g, L1b);

			float3 specular = LightVolumeSpecular(wi.albedo, wi.smoothness, wi.normal, wi.viewDir,
			                                      L0, L1r, L1g, L1b);
			float3 diffuse = LightVolumeEvaluate(wi.normal, L0, L1r, L1g, L1b);
			result.specular += specular * _VRCLVStrength;

			result.diffuse += diffuse * _VRCLVStrength;
		}
		#endif
	}
}


#endif
