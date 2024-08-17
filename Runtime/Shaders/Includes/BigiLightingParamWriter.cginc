#ifndef BIGI_LIGHTING_PARAM_WRITER
#define BIGI_LIGHTING_PARAM_WRITER
#include "./BigiShaderParams.cginc"

namespace b_light
{
	void setVars()
	{
		_DMX_Weight = 0.0;
		_AL_Theme_Weight = 0.0;
		_DMX_Group = 0.0;
		_AL_TC_BassReactive = 1.0;
		_OutlineWidth = 0.0;
		_UsesNormalMap = 0.0;
		_UsesAlpha = 0.0;
		_EmissionStrength = 0.5;
		_MinAmbient = 0.0;
		_Transmissivity = 0.2;
		_OcclusionStrength = 0.0;
		_Smoothness = 0.0;
		_SpecularIntensity = 0.0;
		_MonoChrome = 0.0;
		_Voronoi = 0.0;
		_LightSmoothness = 1.0;
		_LightThreshold = 0.0;
		_LTCGIStrength = 1.0;
		_Rounding = 0.0;

		#ifdef UNITY_PASS_FORWARDBASE
		_VRSLGIStrength = 0.25;
		#endif

	}
}

#endif