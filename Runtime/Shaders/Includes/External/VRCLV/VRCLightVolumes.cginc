#ifndef H_BIGI_VRC_LIGHT_VOLUMES_INCL
#define H_BIGI_VRC_LIGHT_VOLUMES_INCL
// Query VRC Lightvolumes (by RED_SIM) for light volumes
#ifdef UNITY_PASS_FORWARDBASE
#include <UnityCG.cginc>
#include <Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc>

#include "../../Core/BigiShaderStructs.cginc"
#include "../../Core/BigiShaderParams.cginc"
#endif

namespace b_light
{
	void GetLightVolumesLighting(const in world_info wi, inout UnityIndirect result)
	{
		#ifdef UNITY_PASS_FORWARDBASE
		[branch] if (_UdonLightVolumeEnabled && _UdonLightVolumeCount > 0.0f && _VRCLVStrength > 0.0f &&
			_UdonLightVolumeVersion >= VRCLV_MIN_SUPPORTED_VERSION)
		{
			float3 L0 = float3(0, 0, 0);
			float3 L1r = float3(0, 0, 0);
			float3 L1g = float3(0, 0, 0);
			float3 L1b = float3(0, 0, 0);

			float3 specular;
			LightVolumeSHSpecular(wi.worldPos, L0, L1r, L1g, L1b, specular, wi.albedo, wi.smoothness, 1.0, wi.normal, wi.viewDir);
			result.specular += specular * _VRCLVStrength;
			
			float3 diffuse = LightVolumeEvaluate(wi.normal, L0, L1r, L1g, L1b);
			result.diffuse += diffuse * _VRCLVStrength;
		}
		#endif
	}
}


#endif
