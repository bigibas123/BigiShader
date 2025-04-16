#ifndef BIGI_LIGHTUTILDEFINES_H
#define BIGI_LIGHTUTILDEFINES_H


#include <UnityPBSLighting.cginc>
#include <AutoLight.cginc>
#include <UnityLightingCommon.cginc>
#include "./BigiLightUtils.cginc"
#include "../Core/BigiGetColor.cginc"
#include "../Core/BigiShaderParams.cginc"

#ifdef VERTEXLIGHT_ON
#define BIGI_GETLIGHT_VERTEX(outName) \
outName.vertexLighting = b_light::ProcessVertexLights( \
unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, \
unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb, \
unity_4LightAtten0, o.worldPos, o.normal \
)
#define GET_VERTEXLIGHT() (i.vertexLighting)

#else
#define BIGI_GETLIGHT_VERTEX(outName)
#define GET_VERTEXLIGHT() (float3(0,0,0))

#endif


#define BIGI_GETLIGHT_DEFAULT(outName) UNITY_LIGHT_ATTENUATION(shadowAtt, i, i.worldPos.xyz);\
    const fixed4 outName = b_light::get_lighting(\
    i.normal,\
    i.worldPos,\
    GET_VERTEXLIGHT(),\
    GET_AO(GETUV),\
    _OcclusionStrength,\
    shadowAtt,\
    i.lightmapUV,\
    _MinAmbient,\
    _Transmissivity,\
    _LightSmoothness,\
    _LightSteps,\
    GET_SPEC_SMOOTH(GETUV),\
    half3(_LightVertexMultiplier, _LightEnvironmentMultiplier, _LightMainMultiplier)\
    )
#endif
