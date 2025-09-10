#ifndef BIGI_SHADER_PARAMS
#define BIGI_SHADER_PARAMS
#include <HLSLSupport.cginc>
CBUFFER_START(UnityPerMaterial)
#ifndef BIGI_UNIFORMS
#define BIGI_UNIFORMS

uniform float _Alpha_Threshold;
uniform float _Alpha_Multiplier;

#ifndef BIGI_UNIFORMS_DMXAL
#define BIGI_UNIFORMS_DMXAL

uniform uint _AL_Mode;
uniform uint _AL_BlockWireFrame;
uniform uint _AL_BandMapDistance;

uniform float _DMX_Weight;
uniform float _AL_Theme_Weight;

uniform uint _DMX_Group;

uniform float _AL_TC_BassReactive;
uniform float _AL_WireFrameWidth;

//Both
uniform float _OutlineWidth;

//TV
#ifndef BIGI_PROTV_PARAMS_DEFINED
#define BIGI_PROTV_PARAMS_DEFINED
uniform float _EnableProTVSquare;
#define BIGI_PROTV_ON_VAR _EnableProTVSquare
uniform float _SquareTVTest;
#define BIGI_PROTV_TEST_VAR _SquareTVTest
uniform float _TV_Square_Opacity;
#define BIGI_PROTV_OPACITY_VAR _TV_Square_Opacity
uniform float4 _TV_Square_Position;
#define BIGI_PROTV_POSITION_VAR _TV_Square_Position
#endif

#endif


#ifndef BIGI_UNIFORMS_LIGHTING
#define BIGI_UNIFORMS_LIGHTING
//Other
uniform float _EmissionStrength;
uniform float _MinAmbient;
uniform float _Transmissivity;
#ifndef UNITY_STANDARD_INPUT_INCLUDED
uniform float _OcclusionStrength;
#endif
uniform float _Smoothness;
uniform float _SpecularIntensity;

//Effects
uniform float _MonoChrome;
uniform float _Voronoi;
uniform float _LightSmoothness;
uniform uint _LightSteps;
#ifdef MIRROR_THING
uniform float _DoMirrorThing;
#define MIRROR_THING_VAR (_DoMirrorThing)
#else
#define MIRROR_THING_VAR (0.0)
#endif

#ifdef UNITY_PASS_FORWARDBASE
uniform float _LTCGIStrength;
uniform float _VRCLVStrength;
#endif

uniform half _LightVertexMultiplier;
uniform half _LightEnvironmentMultiplier;

#if defined(UNITY_PASS_FORWARDBASE)
uniform half _LightMainMultiplier;
#define BIGI_LIGHT_MAIN_MULTI (_LightMainMultiplier)
#elif defined(UNITY_PASS_FORWARDADD)
uniform half _LightAddMultiplier;
#define BIGI_LIGHT_MAIN_MULTI (_LightAddMultiplier)
#else
#define BIGI_LIGHT_MAIN_MULTI (0.0)
#endif

uniform half _FinalLightMultiply;

#ifndef ROUNDING_VAR_NAME
		uniform float _Rounding;
		#define ROUNDING_VAR_NAME _Rounding
#endif

#ifndef GETUV
	#define GETUV (i.uv.xy)
#endif

#endif

#endif
CBUFFER_END
#endif
