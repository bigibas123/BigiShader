#ifndef H_BIGI_LTCGI_FUNCTION_INCL
#define H_BIGI_LTCGI_FUNCTION_INCL

#define LTCGI_API_V2

#include <UnityLightingCommon.cginc>
#include "../../Core/BigiShaderStructs.cginc"
#include <Packages/at.pimaker.ltcgi/Shaders/LTCGI_structs.cginc>

void callback_diffuse(inout UnityIndirect acc, in ltcgi_output output);
void callback_specular(inout UnityIndirect acc, in ltcgi_output output);

// tell LTCGI that we want the V2 API, and which constructs to use
#define LTCGI_V2_CUSTOM_INPUT UnityIndirect
#define LTCGI_V2_DIFFUSE_CALLBACK callback_diffuse
#define LTCGI_V2_SPECULAR_CALLBACK callback_specular


#include <Packages/at.pimaker.ltcgi/Shaders/LTCGI.cginc>
#include "../../Core/BigiShaderParams.cginc"

// now we declare LTCGI APIv2 functions for real
void callback_diffuse(inout LTCGI_V2_CUSTOM_INPUT acc, in ltcgi_output output)
{
	// you can do whatever here! check out the ltcgi_output struct in
	// "LTCGI_structs.cginc" to see what data you have available
	float3 adjusted_diffuse = output.color;
	adjusted_diffuse *= output.intensity;
	acc.diffuse += adjusted_diffuse;
}

void callback_specular(inout LTCGI_V2_CUSTOM_INPUT acc, in ltcgi_output output)
{
	// same here, this example one is pretty boring though.
	// you could accumulate intensity separately for example,
	// to emulate total{Specular,Diffuse}Intensity from APIv1
	float3 adjusted_specular = output.color;
	adjusted_specular *= output.intensity;
	acc.specular += adjusted_specular;
}

void GetLTCGI(const in b_light::world_info wi, inout LTCGI_V2_CUSTOM_INPUT result)
{
	#ifdef UNITY_PASS_FORWARDBASE
	LTCGI_V2_CUSTOM_INPUT acc;
	acc.specular = 0.0;
	acc.diffuse = 0.0;
	LTCGI_Contribution(
		acc, // our accumulator
		wi.worldPos, // world position of the shaded point
		wi.normal, // world space normal
		wi.viewDir, // view vector to shaded point, normalized
		1.0f - wi.smoothness, // roughness
		wi.shadowmapUvs.xy // shadowmap coordinates (the normal Unity ones, they should be in sync with LTCGI maps)
	);
	result.specular += (acc.specular * _LTCGIStrength);
	result.diffuse += ((acc.diffuse * wi.albedo) * _LTCGIStrength);
	#endif
}

#endif
