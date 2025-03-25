#ifndef BIGI_EFFECTS_DEFINES
#define BIGI_EFFECTS_DEFINES

#include "./BigiEffects.cginc"
#include "./LengthDefine.cginc"
#include "../Core/BigiGetColor.cginc"
#include "../Core/BigiShaderParams.cginc"


#define GET_EFFECTS_COLOR(dist, staticTextureUv) (b_effects::apply_effects(GETUV, GET_MASK_COLOR(GETUV), orig_color, lighting, dist, staticTextureUv))


#endif
