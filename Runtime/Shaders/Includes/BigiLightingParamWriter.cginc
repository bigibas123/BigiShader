#ifndef BIGI_LIGHTING_PARAM_WRITER
#define BIGI_LIGHTING_PARAM_WRITER
#include "./BigiShaderParams.cginc"

#ifndef Epsilon
#include <UnityCG.cginc>
#define Epsilon UNITY_HALF_MIN
#endif

#define IFZEROAPPLY(varname, val) if (varname < Epsilon && varname > -Epsilon){ varname = val;}
namespace b_light
{
	void setVars()
	{
		IFZEROAPPLY(_DMX_Weight, 0.0);
		IFZEROAPPLY(_AL_Theme_Weight, 0.0);
		IFZEROAPPLY(_DMX_Group, 0.0);
		IFZEROAPPLY(_AL_TC_BassReactive, 1.0);
		IFZEROAPPLY(_OutlineWidth, 0.0);
		IFZEROAPPLY(_UsesNormalMap, 0.0);
		IFZEROAPPLY(_UsesAlpha, 0.0);
		IFZEROAPPLY(_EmissionStrength, 0.5);
		IFZEROAPPLY(_MinAmbient, 0.20);
		IFZEROAPPLY(_Transmissivity, 0.2);
		IFZEROAPPLY(_OcclusionStrength, 0.0);
		IFZEROAPPLY(_Smoothness, 0.2);
		IFZEROAPPLY(_SpecularIntensity, 0.2);
		IFZEROAPPLY(_MonoChrome, 0.0);
		IFZEROAPPLY(_Voronoi, 0.0);
		IFZEROAPPLY(_LightSmoothness, 1.0);
		IFZEROAPPLY(_LightThreshold, 0.0);
		IFZEROAPPLY(_LTCGIStrength, 1.0);
		IFZEROAPPLY(_Rounding, 0.0);

		#ifdef UNITY_PASS_FORWARDBASE
		IFZEROAPPLY(_VRSLGIStrength, 0.25);
		#endif
	}
}

#endif