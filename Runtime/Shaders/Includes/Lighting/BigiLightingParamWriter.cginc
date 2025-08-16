#ifndef BIGI_LIGHTING_PARAM_WRITER
#define BIGI_LIGHTING_PARAM_WRITER
#include "../Epsilon.cginc"
#include "../Core/BigiShaderParams.cginc"

#define IFZEROAPPLY(varName, val) if (varName < Epsilon && varName > -Epsilon){ varName = val;}
//#define IFZEROAPPLY(varName, val) {varName = val;}

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
		#ifdef BIGI_PROTV_ON_VAR
		IFZEROAPPLY(BIGI_PROTV_ON_VAR, 0.0);
		#endif
		#ifdef BIGI_PROTV_TEST_VAR
		IFZEROAPPLY(BIGI_PROTV_TEST_VAR, 0.0);
		#endif
		#ifdef BIGI_PROTV_OPACITY_VAR
		IFZEROAPPLY(BIGI_PROTV_OPACITY_VAR, 0.0);
		#endif
		#ifdef BIGI_PROTV_POSITION_VAR
		IFZEROAPPLY(BIGI_PROTV_POSITION_VAR.x, 0.0);
		IFZEROAPPLY(BIGI_PROTV_POSITION_VAR.y, 0.0);
		IFZEROAPPLY(BIGI_PROTV_POSITION_VAR.z, 0.0);
		IFZEROAPPLY(BIGI_PROTV_POSITION_VAR.w, 0.0);
		#endif
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
		#if defined(UNITY_PASS_FORWARDBASE)
		IFZEROAPPLY(_LTCGIStrength, 1.0);
		IFZEROAPPLY(_VRCLVStrength, 1.0);
		#ifdef BIGI_VRSLGI_ENABLED
		IFZEROAPPLY(_VRSLGIStrength, 0.0);
		#endif
		#endif

		IFZEROAPPLY(_LightVertexMultiplier, 1.0);
		IFZEROAPPLY(_LightEnvironmentMultiplier, 1.0);
		
		#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
		IFZEROAPPLY(BIGI_LIGHT_MAIN_MULTI, 1.0);
		#endif
		
		IFZEROAPPLY(_FinalLightMultiply, 1.0);

		IFZEROAPPLY(_AL_Mode, 0.0);
		IFZEROAPPLY(_AL_BandMapDistance, 0.0);
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
		
	}
}

#endif
