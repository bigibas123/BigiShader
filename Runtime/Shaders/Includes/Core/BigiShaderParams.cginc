#ifndef BIGI_SHADER_PARAMS
#define BIGI_SHADER_PARAMS

#ifndef BIGI_UNIFORMS
#define BIGI_UNIFORMS

uniform float _Alpha_Threshold;
uniform float _Alpha_Multiplier;

#ifndef BIGI_UNIFORMS_DMXAL
#define BIGI_UNIFORMS_DMXAL

uniform uint _AL_Mode;

uniform float _DMX_Weight;
uniform float _AL_Theme_Weight;

uniform uint _DMX_Group;

uniform float _AL_TC_BassReactive;
uniform float _AL_WireFrameWidth;

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

uniform half _LightVertexMultiplier;
uniform half _LightEnvironmentMultiplier;
uniform half _LightMainMultiplier;

#ifndef ROUNDING_VAR_NAME
		uniform float _Rounding;
		#define ROUNDING_VAR_NAME _Rounding
#endif

#ifndef GETUV
	#define GETUV (i.uv.xy)
#endif

#endif

#endif
#endif
