#ifndef VRSLGI_PARAMS_SETUP_INCL
#define VRSLGI_PARAMS_SETUP_INCL



#define _VRSL_GI
#define _VRSL_GI_SPECULARHIGHLIGHTS 0
#define _VRSL_SPECFUNC_GGX
#define _VRSL_GLOBALLIGHTTEXTURE

#include "./VRSLGI-Functions.cginc"


namespace b_vrslgi
{
	void setParams()
	{
		_UseVRSLShadowMask1 = 1.0;
		_UseVRSLShadowMask1RStrength = 1.0;
		_UseVRSLShadowMask1GStrength = 1.0;
		_UseVRSLShadowMask1BStrength = 1.0;
		_UseVRSLShadowMask1AStrength = 1.0;
		
		_UseVRSLShadowMask2 = 1.0;
		_UseVRSLShadowMask2RStrength = 1.0;
		_UseVRSLShadowMask2GStrength = 1.0;
		_UseVRSLShadowMask2BStrength = 1.0;
		_UseVRSLShadowMask2AStrength = 1.0;

		_UseVRSLShadowMask3 = 1.0;
		_UseVRSLShadowMask3RStrength = 1.0;
		_UseVRSLShadowMask3GStrength = 1.0;
		_UseVRSLShadowMask3BStrength = 1.0;
		_UseVRSLShadowMask3AStrength = 1.0;

		_VRSLInvertSmoothnessMap = 1.0;
		_VRSLGlossMapStrength = 0.0;
		_VRSLMetallicMapStrength = 0.0;
		
		_VRSLSpecularShine = 0.5;
		_VRSLSpecularMultiplier = 0.5;
		_VRSLDiffuseMix = 1.0;
		_VRSLGIDiffuseClamp = 1.0;
		_VRSLGISpecularClamp = 1.0;
	}
}

#endif