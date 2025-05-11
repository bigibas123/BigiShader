#ifndef H_BIGI_VRC_LIGHT_VOLUMES_INCL
#define H_BIGI_VRC_LIGHT_VOLUMES_INCL
// Query VRC Lightvolumes (by RED_SIM) for light volumes

//#include <Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc>
#include "./LightVolumes.cginc"

#include "../../Core/BigiShaderStructs.cginc"
#include "../../Core/BigiShaderParams.cginc"

namespace b_light
{
	float3 GetLightVolumesLighting(const in world_info wi)
	{
		if (_UdonLightVolumeEnabled && _UdonLightVolumeCount > 0)
		{
			float3 L0 = float3(0, 0, 0);
			float3 L1r = float3(0, 0, 0);
			float3 L1g = float3(0, 0, 0);
			float3 L1b = float3(0, 0, 0);

			LightVolumeSH(wi.worldPos, L0, L1r, L1g, L1b);

			return LightVolumeEvaluate(wi.normal, L0, L1r, L1g, L1b) * _VRCLVStrength;
		}
		else
		{
			return float3(0.0, 0.0, 0.0);
		}
	}
}


#endif
