#ifndef BIGI_LIGHTUTILDEFINES_H
#define BIGI_LIGHTUTILDEFINES_H


#include <UnityPBSLighting.cginc>
#include <AutoLight.cginc>
#include <UnityLightingCommon.cginc>
#include "./BigiShaderParams.cginc"
#include "./BigiLightUtils.cginc"
#include "./BigiShaderTextures.cginc"



#define BIGI_GETLIGHT_DEFAULT(outName) UNITY_LIGHT_ATTENUATION(shadowAtt, i, i.worldPos.xyz);\
    const fixed4 outName = b_light::get_lighting(\
    i.normal,\
    i.worldPos,\
    i.vertexLighting,\
    GET_AO(GETUV),\
    _OcclusionStrength,\
    shadowAtt,\
    i.lightmapUV,\
    _MinAmbient,\
    _Transmissivity,\
    _LightSmoothness,\
    _LightThreshold,\
    _Smoothness,\
    _SpecularIntensity\
    )

#define BIGI_GETLIGHT_NOAO(outName) UNITY_LIGHT_ATTENUATION(shadowAtt, i, i.worldPos.xyz);\
    const fixed4 outName = b_light::get_lighting(\
    i.normal,\
    i.worldPos,\
    i.vertexLighting,\
    fixed4(1.0,1.0,1.0,1.0),\
    0.0,\
    shadowAtt,\
    i.lightmapUV,\
    _MinAmbient,\
    _Transmissivity,\
    _LightSmoothness,\
    _LightThreshold,\
    _Smoothness,\
    _SpecularIntensity\
    )


#ifdef VERTEXLIGHT_ON

#define BIGI_GETLIGHT_VERTEX(outName) \
const float3 outName = b_light::ProcessVertexLights( \
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, \
    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb, \
    unity_4LightAtten0, o.worldPos, o.normal \
)

#else
#define BIGI_GETLIGHT_VERTEX(outName) const float3 outName = 0

#endif
#endif
