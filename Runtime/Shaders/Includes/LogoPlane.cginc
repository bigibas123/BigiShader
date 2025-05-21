#ifndef BIGI_LOGOPLANE
#define BIGI_LOGOPLANE
#ifndef MULTI_TEXTURE
#define MULTI_TEXTURE
#endif


#include <UnityCG.cginc>
uniform float _AL_Weight;
uniform float _Alpha_Non_Premul;

uniform int _Logo_FlipBookID;
#define MULTI_TEXTURE
#define OTHER_TEXTURE_ID_REF _Logo_FlipBookID
#define OTHER_BIGI_TEXTURES
#define NO_RESET_MINAMBIENT

#include "./Includes/Epsilon.cginc"
#include "./Includes/ToonVert.cginc"
#include "./Includes/Core/BigiShaderStructs.cginc"
#include "./Includes/Lighting/BigiLightingParamWriter.cginc"
#include "./Includes/Effects/SoundUtilsDefines.cginc"


v2f vert(appdata v)
{
	b_light::setVars();
	return bigi_toon_vert(v);
}

fragOutput frag(v2f i)
{
	b_light::setVars();
	fragOutput o;
	UNITY_INITIALIZE_OUTPUT(fragOutput, o);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
	fixed4 orig_color = GET_TEX_COLOR(GETUV);
	clip(orig_color.a - Epsilon);
	if (_Alpha_Non_Premul)
	{
		orig_color.rgb = (orig_color.rgb * orig_color.a);
	}

	BIGI_GETLIGHT_DEFAULT(lighting);
	fixed4 normal_color = orig_color * lighting;

	_AL_Theme_Weight = _AL_Weight;
	float4 distance = float4(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 0.0);
	GET_SOUND_COLOR(sound);

	o.color = lerp(normal_color,fixed4(sound.rgb, normal_color.a), sound.a);
	o.color.a = orig_color.a;
	//o.color = orig_color;
	UNITY_APPLY_FOG(i.fogCoord, o.color);
	return o;
}

#endif
