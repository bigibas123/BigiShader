#ifndef BIGIAUDIOLINK_FRAG_DEFAULT_FRAG
#define BIGIAUDIOLINK_FRAG_DEFAULT_FRAG

#include <UnityInstancing.cginc>
#include "./Core/BigiShaderStructs.cginc"
#include "./Core/BigiShaderParams.cginc"
#include "./Lighting/NormalDefines.cginc"
#include "./Lighting/LightUtilsDefines.cginc"
#include "./Effects/EffectsDefines.cginc"

namespace b_frag
{
	fragOutput bigi_frag_fwdbase(in v2f i, const in float4 orig_color)
	{
		fragOutput o;
		UNITY_INITIALIZE_OUTPUT(fragOutput, o);
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		RECALC_NORMALS();
		
		BIGI_GETLIGHT_DEFAULT(lighting);

		o.color = GET_EFFECTS_COLOR(i.distance,i.staticTexturePos);
		UNITY_APPLY_FOG(i.fogCoord, o.color);
		return o;
	}

}


#endif