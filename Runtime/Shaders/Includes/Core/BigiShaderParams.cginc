#ifndef BIGI_SHADER_PARAMS
#define BIGI_SHADER_PARAMS

#ifndef BIGI_UNIFORMS
#define BIGI_UNIFORMS

uniform float _Alpha_Threshold;

#ifndef BIGI_UNIFORMS_DMXAL
#define BIGI_UNIFORMS_DMXAL

uniform float _DMX_Weight;
uniform float _AL_Theme_Weight;

uniform uint _DMX_Group;

uniform float _AL_TC_BassReactive;

//Both
uniform float _OutlineWidth;

//TV
uniform float _SquareTVTest;
uniform float _TV_Square_Opacity;
uniform float4 _TV_Square_Position;

#endif


#ifndef BIGI_UNIFORMS_LIGHTING
#define BIGI_UNIFORMS_LIGHTING
//Other
uniform float _EmissionStrength;
uniform float _MinAmbient;
uniform float _Transmissivity;
uniform float _OcclusionStrength;
uniform float _Smoothness;
uniform float _SpecularIntensity;

//Effects
uniform float _MonoChrome;
uniform float _Voronoi;
uniform float _LightSmoothness;
uniform uint _LightSteps;
#ifdef MIRROR_THING
uniform float _DoMirrorThing;
#endif

uniform float _LTCGIStrength;

#ifndef ROUNDING_VAR_NAME
	#ifdef ROUNDING_ENABLED
		uniform float _Rounding;
		#define ROUNDING_VAR_NAME _Rounding
	#endif
#endif

#if defined(ROUNDING_VAR_NAME) && defined(ROUNDING_ENABLED)
#ifndef GET_UV
#define GET_UV(origuv,iposw) (ROUNDING_VAR_NAME > Epsilon ? origuv/iposw : origuv)
#endif
#ifndef GETUV
#define GETUV GET_UV(i.uv.xy,i.pos.w)
#endif
#else
#ifndef GET_UV
#define GET_UV(origuv) origuv
#endif
#ifndef GETUV
#define GETUV GET_UV(i.uv.xy)
#endif
#endif


#endif

#endif
#endif
