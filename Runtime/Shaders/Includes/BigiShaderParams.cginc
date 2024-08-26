#ifndef BIGI_SHADER_PARAMS
#define BIGI_SHADER_PARAMS

//#include "./BigiShaderTextures.cginc"

//#include <UnityShaderVariables.cginc>

#ifndef BIGI_UNIFORMS
#define BIGI_UNIFORMS

#ifndef BIGI_UNIFORMS_DMXAL
#define BIGI_UNIFORMS_DMXAL

uniform float _DMX_Weight;
uniform float _AL_Theme_Weight;

uniform uint _DMX_Group;

uniform float _AL_TC_BassReactive;

//Both
uniform float _OutlineWidth;

uniform float _UsesNormalMap;
uniform float _UsesAlpha;

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
uniform float _LightThreshold;

uniform float _LTCGIStrength;

uniform float _Rounding;
#define GET_UV(origuv,iposw) _Rounding > Epsilon ? origuv/iposw : origuv
#define GETUV GET_UV(i.uv.xy,i.pos.w)

#endif


#ifndef BIGI_DEFAULT_FRAGOUT
#define BIGI_DEFAULT_FRAGOUT

#include <HLSLSupport.cginc>

struct fragOutput
{
	fixed4 color : SV_Target;
};
#endif

#ifndef Epsilon
#include <UnityCG.cginc>
#define Epsilon UNITY_HALF_MIN
#endif

#endif
#endif
