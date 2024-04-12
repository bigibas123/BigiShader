#ifndef H_BIGI_LTCGI_FUNCTION_INCL
#define H_BIGI_LTCGI_FUNCTION_INCL

#include <UnityLightingCommon.cginc>
#include "../../BigiShaderStructs.cginc"
#include "Packages/at.pimaker.ltcgi/Shaders/LTCGI_structs.cginc"

void callback_diffuse(inout UnityIndirect acc, in ltcgi_output output);
void callback_specular(inout UnityIndirect acc, in ltcgi_output output);

// tell LTCGI that we want the V2 API, and which constructs to use
#define LTCGI_V2_CUSTOM_INPUT UnityIndirect
#define LTCGI_V2_DIFFUSE_CALLBACK callback_diffuse
#define LTCGI_V2_SPECULAR_CALLBACK callback_specular


#include "Packages/at.pimaker.ltcgi/Shaders/LTCGI.cginc"


// now we declare LTCGI APIv2 functions for real
void callback_diffuse(inout UnityIndirect acc, in ltcgi_output output) {
	// you can do whatever here! check out the ltcgi_output struct in
	// "LTCGI_structs.cginc" to see what data you have available
	acc.diffuse += output.intensity * output.color;
}
void callback_specular(inout UnityIndirect acc, in ltcgi_output output) {
	// same here, this example one is pretty boring though.
	// you could accumulate intensity separately for example,
	// to emulate total{Specular,Diffuse}Intensity from APIv1
	acc.specular += output.intensity * output.color;
}

UnityIndirect getLTCGI(b_light::world_info wi, in half smoothness)
{

	UnityIndirect acc;
	acc.diffuse = 0;
	acc.specular = 0;

	// then we make the LTCGI_Contribution call as usual, but with slightly different params
	LTCGI_Contribution(
		acc, // our accumulator
		wi.worldPos, // world position of the shaded point
		wi.normal, // world space normal
		wi.viewDir, // view vector to shaded point, normalized
		1.0f - smoothness, // roughness
		wi.shadowmapUv // shadowmap coordinates (the normal Unity ones, they should be in sync with LTCGI maps)
	);

	return acc;
}

#endif