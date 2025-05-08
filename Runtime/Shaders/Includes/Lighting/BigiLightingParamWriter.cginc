#ifndef BIGI_LIGHTING_PARAM_WRITER
#define BIGI_LIGHTING_PARAM_WRITER
#include "../Core/BigiShaderParams.cginc"

#ifndef Epsilon
#include <UnityCG.cginc>
#define Epsilon UNITY_HALF_MIN
#endif

#define IFZEROAPPLY(varName, val) if (varName < Epsilon && varName > -Epsilon){ varName = val;}

namespace b_light
{
	void setVars()
	{
		IFZEROAPPLY(_Alpha_Threshold, 1.0 - Epsilon);
		IFZEROAPPLY(_Alpha_Multiplier, 1.0);
		IFZEROAPPLY(_DMX_Weight, 0.0);
		IFZEROAPPLY(_AL_Theme_Weight, 0.0);
		IFZEROAPPLY(_DMX_Group, 0.0);
		IFZEROAPPLY(_AL_TC_BassReactive, 1.0);
		IFZEROAPPLY(_OutlineWidth, 0.0);
		IFZEROAPPLY(_SquareTVTest, 0.0);
		IFZEROAPPLY(_TV_Square_Opacity, 0.0);
		IFZEROAPPLY(_TV_Square_Position.x, 0.0);
		IFZEROAPPLY(_TV_Square_Position.y, 0.0);
		IFZEROAPPLY(_TV_Square_Position.z, 0.0);
		IFZEROAPPLY(_TV_Square_Position.w, 0.0);
		IFZEROAPPLY(_EmissionStrength, 0.5);
		#ifndef NO_RESET_MINAMBIENT
		IFZEROAPPLY(_MinAmbient, 0.20);
		#endif
		IFZEROAPPLY(_Transmissivity, 0.0);
		IFZEROAPPLY(_OcclusionStrength, 0.0);
		IFZEROAPPLY(_Smoothness, 0.0);
		IFZEROAPPLY(_SpecularIntensity, 0.0);
		IFZEROAPPLY(_MonoChrome, 0.0);
		IFZEROAPPLY(_Voronoi, 0.0);
		IFZEROAPPLY(_LightSmoothness, 1.0);
		IFZEROAPPLY(_LightSteps, 128);
		IFZEROAPPLY(_LTCGIStrength, 1.0);
		IFZEROAPPLY(_VRCLVStrength, 1.0);

		IFZEROAPPLY(_LightVertexMultiplier, 1.0);
		IFZEROAPPLY(_LightEnvironmentMultiplier, 1.0);
		IFZEROAPPLY(_LightMainMultiplier, 1.0);

		IFZEROAPPLY(_AL_Mode, 0.0);
		#ifdef BIGI_BLOCK_WIREFRAME
		_AL_BlockWireFrame = 1;
		#else
		IFZEROAPPLY(_AL_BlockWireFrame, 0.0);
		#endif
		
		
		#ifdef ROUNDING_VAR_NAME
		IFZEROAPPLY(ROUNDING_VAR_NAME, 0.0);
		#else
		IFZEROAPPLY(_Rounding, 0.0);
		#endif
		#ifdef MIRROR_THING
		#ifndef NO_RESET_MIRROR_THING
		IFZEROAPPLY(_DoMirrorThing, 0.0);
		#endif
		#endif

		#ifdef UNITY_PASS_FORWARDBASE
		IFZEROAPPLY(_VRSLGIStrength, 0.25);
		#endif
	}
}

#endif
