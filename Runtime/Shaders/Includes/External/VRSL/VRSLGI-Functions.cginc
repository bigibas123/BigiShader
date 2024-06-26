


#ifdef      _VRSL_GLOBALLIGHTTEXTURE
    Texture2D   _Udon_VRSL_GI_LightTexture;
#else
    Texture2D   _VRSL_LightTexture;
#endif

uniform float4  _VRSL_LightTexture_TexelSize;
SamplerState    VRSL_BilinearClampSampler, VRSLGI_PointClampSampler;
int     _Udon_VRSL_GI_LightCount;

//float _LTCGIStrength;
float _AreaLitStrength;
float _AreaLitRoughnessMult;
Texture2D _AreaLitOcclusion;
float4 _AreaLitOcclusion_ST;
int _OcclusionUVSet;




#ifndef VRSL_GI_PROJECTOR
sampler2D   _VRSLMetallicGlossMap;
half        _VRSLMetallicMapStrength;
half        _VRSLGlossMapStrength;
half        _VRSLSmoothnessChannel;
half        _VRSLMetallicChannel;
half        _VRSLInvertMetallicMap;
half        _VRSLInvertSmoothnessMap;

Texture2D   _VRSLShadowMask1;
Texture2D   _VRSLShadowMask2;
Texture2D   _VRSLShadowMask3;

int         _UseVRSLShadowMask1;
int         _UseVRSLShadowMask2;
int         _UseVRSLShadowMask3;

#else
int         _VRSLGIVertexFalloff;
float       _VRSLGIVertexAttenuation;

#endif

half        _VRSLGISpecularClamp;
half        _VRSLGIDiffuseClamp;

half        _VRSLSpecularShine;
half        _VRSLGlossiness;
half        _VRSLSpecularStrength;
half        _VRSLGIStrength;
half        _VRSLDiffuseMix;
half        _VRSLSpecularMultiplier;

half        _UseVRSLShadowMask1RStrength;
half        _UseVRSLShadowMask1GStrength;
half        _UseVRSLShadowMask1BStrength;
half        _UseVRSLShadowMask1AStrength;

half        _UseVRSLShadowMask2RStrength;
half        _UseVRSLShadowMask2GStrength;
half        _UseVRSLShadowMask2BStrength;
half        _UseVRSLShadowMask2AStrength;

half        _UseVRSLShadowMask3RStrength;
half        _UseVRSLShadowMask3GStrength;
half        _UseVRSLShadowMask3BStrength;
half        _UseVRSLShadowMask3AStrength;
half        _RenderTextureMultiplier;

half        _VRSLShadowMaskUVSet;

//float4      _ProjectorColor;
half        _VRSLProjectorStrength;






#if _VRSL_GI_SPECULARHIGHLIGHTS
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles

    

    //GGX Specular function found here http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
    float GGXSpec(float3 N, float3 V, float3 L, float roughness)
    {
        float alpha = roughness*roughness;

        float3 H = normalize(V+L);

        float dotNL = saturate(dot(N,L));
        //float dotNV = saturate(dot(N,V));
        float dotNH = saturate(dot(N,H));
        float dotLH = saturate(dot(L,H));

        float D, vis;

        // D
        float alphaSqr = alpha*alpha;
        float pi = 3.14159f;
        float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
        D = alphaSqr/(pi * denom * denom);

        // F
        //float dotLH5 = pow(1.0f-dotLH,5);
        //F = F0 + (1.0-F0)*(dotLH5);

        // V
        float k = alpha/2.0f;
        float k2 = k*k;
        float invK2 = 1.0f-k2;
        vis = rcp(dotLH*dotLH*invK2 + k2);
        //vis = G1V(dotLH,k)*G1V(dotLH,k);
        //vis = G1V(dotNL,k)*G1V(dotNV,k);

        float specular = dotNL * D * vis;
        return specular;
    }

    float BeckmanSpec(float3 N, float3 V, float3 L, float roughness)
    {
        float3 H = normalize(V+L);
        float NdotH = saturate(dot(N,H));
        float roughnessSqr = roughness*roughness * (roughness * 0.5);
        float NdotHSqr = NdotH*NdotH;
        return max(0.000001,(1.0 / (3.1415926535*roughnessSqr*NdotHSqr*NdotHSqr))
        * exp((NdotHSqr-1)/(roughnessSqr*NdotHSqr)));
    }

    float PhongSpec(float3 N, float3 V, float3 L, float roughness)
    {
    //float r = lerp(roughness * 0.01, roughness * 2, roughness);
    float speculargloss = (1/(roughness * roughness)) * 20;
    float specularpower = lerp(15, 2, roughness);
    float3 H = normalize(V+L);
    float NdotH = saturate(dot(N,H));
    float Distribution = pow(NdotH,speculargloss) * specularpower;
    Distribution *= (2+specularpower) / (2*3.1415926535);
    return Distribution;
    }
    

#endif
#if !defined(VRSL_GI_PROJECTOR)
    half4 VRSLShadowMask1(float2 uv)
    {
        return _VRSLShadowMask1.SampleLevel(VRSL_BilinearClampSampler, uv, 0);
    }
    half4 VRSLShadowMask2(float2 uv)
    {
        return _VRSLShadowMask2.SampleLevel(VRSL_BilinearClampSampler, uv, 0);
    }
    half4 VRSLShadowMask3(float2 uv)
    {
        return _VRSLShadowMask3.SampleLevel(VRSL_BilinearClampSampler, uv, 0);
    }
#endif

float AngleBetweenVecotrs(float3 v1, float3 v2)
{
    return dot(v1, v2) / (length(v1) * length(v2));
}
    #if defined(_VRSL_GI_ENFORCELIMIT)
    struct VRSLVertLightData
    {
       // uint4 data[16];
        float4 colors[4];
        float4 positions[4];
        float4 directions[4];
            #if defined(VERTEXLIGHT_ON)
            // Non Important Lights
            float4 vDotNL;
            float4 vertexVDotNL;
            float3 vColor[4];
            float4 vCorrectedDotNL;
            float4 vAttenuation;
            float4 vAttenuationDotNL;
            float3 vPosition[4];
            float3 vDirection[4];
            float3 vFinalLighting;
            float3 vHalfDir[4];
            half4 vDotNH;
            half4 vertexVDotNH;
            half4 vDotLH;
            #endif
        

    };
    #endif

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // uniform uint lightIndexes[64];
//#if _VRSL_GI

    #if defined(_VRSL_GI_ENFORCELIMIT) && defined(VRSL_GI_PROJECTOR) && defined(VERTEXLIGHT_ON)

    float3 VRSLGI_QuadVertexLighting(VRSLVertLightData ld, 
    float3 worldPos, 
    float3 vertNormal, 
    float3 worldNormal, 
    float4 meshWorldPos, 
    float3 eyeVec, 
    float roughness,
    float3 diffuseColor,
    int lightCount)
    {
        float3 viewDirection = normalize(eyeVec.xyz);
        #if _VRSL_GI_SPECULARHIGHLIGHTS
            float metallic = _VRSLSpecularStrength;
            #ifndef VRSL_GI_PROJECTOR
                roughness = lerp(roughness,mg.y,_VRSLGlossMapStrength);
                metallic =  lerp(metallic,mg.x,_VRSLMetallicMapStrength);
            #endif
            roughness = max(roughness, 0.002);
        #endif

        float3 vertexLighting = float3(0, 0, 0);
        [unroll(4)]
        for (int index = 0; index < lightCount; index++)
        {

            float4 rawLightColor = ld.colors[index];

            float3 lightColor = rawLightColor.rgb * (0.5 * rawLightColor.a);

            float4 lightPos = ld.positions[index];

            float specular = 1.0;
            
            float range = distance(worldPos, lightPos.xyz);
            float3 lightDirection = normalize(lightPos.xyz - worldPos);
            #if _VRSL_DIFFUSETOON
                float atten = saturate(dot(lightDirection, worldNormal) );
                atten = lerp(0.0025, 1.0, atten);
                atten = smoothstep(0,0.01,atten);
            #elif _VRSL_DIFFUSETINT
                float atten = 1.0f;
            #else
                float atten = saturate(dot(lightDirection, worldNormal) );
            #endif
            //float range = lightDist / 1.0;
            range*= rawLightColor.a;
            float falloff = 1.0 / (range * range);
            //End Diffuse Stuff

            //Begin Specular Stuff
            #if _VRSL_GI_SPECULARHIGHLIGHTS
                #ifdef _VRSL_SPECFUNC_GGX
                    specular = GGXSpec(worldNormal, viewDirection, lightDirection, roughness);
                #elif _VRSL_SPECFUNC_BECKMAN
                    specular = BeckmanSpec(worldNormal, viewDirection, lightDirection, roughness);
                #elif _VRSL_SPECFUNC_PHONG
                    specular = PhongSpec(worldNormal, viewDirection, lightDirection, roughness);
                #endif
                specular = lerp(1.0, specular, metallic) * _VRSLSpecularMultiplier;
                specular = lerp(specular, specular * specular, _VRSLSpecularShine);

                specular *= (1/(range*0.5));
            #endif

            lightColor = lightColor * ((_VRSLGIStrength));
            diffuseColor = lerp(float3(1,1,1), diffuseColor, _VRSLDiffuseMix);

            #if _VRSL_GI_ANGLES

                    float4 rawLightDirection = ld.directions[index];
                    float3 spotlightDir = rawLightDirection.xyz;
                    //float angle = trunc(rawLightDirection.w) - 1000;
                    float angle = (floor(rawLightDirection.w - 1)) / 255;
                    angle = angle * 180.0;
                    float theta = dot(lightDirection, normalize(-spotlightDir));
                    float outerCone = cos(radians(angle));
                    float spotlight = clamp(theta - outerCone,0.0,1.0);

                    atten = atten*spotlight;
                    specular = specular*spotlight;

            #endif
            #ifdef VRSL_GI_PROJECTOR
                lightColor = clamp(lightColor, float3(0,0,0), float3(_VRSLGIDiffuseClamp, _VRSLGIDiffuseClamp, _VRSLGIDiffuseClamp));
            #endif

            vertexLighting += falloff * lightColor * atten * diffuseColor * clamp(specular, 0.0, _VRSLGISpecularClamp);

        }
        return vertexLighting;
    }

    #endif


    void SetShadowMaskChannel(int maskChannel, out float s1, out float s1Strength, float4 mask, float4 strength)
    {
        s1 = 1.0;
        s1Strength = 0.0;
        #if _VRSL_SHADOWMASK_RG
            [branch]
            switch(maskChannel)
            {
                case 0:
                    s1 = mask.r;
                    s1Strength = strength.r;
                    break;
                case 1:
                    s1 = mask.g;
                    s1Strength = strength.g;
                    break;
                default:
                    break;
            }
        #elif _VRSL_SHADOWMASK_RGB
            [branch]
            switch(maskChannel)
            {
                case 0:
                    s1 = mask.r;
                    s1Strength = strength.r;
                    break;
                case 1:
                    s1 = mask.g;
                    s1Strength = strength.g;
                    break;
                case 2:
                    s1 = mask.b;
                    s1Strength = strength.b;
                    break;
                default:
                    break;
            }
        #elif _VRSL_SHADOWMASK_RGBA
            s1 = mask[maskChannel];
            s1Strength = strength[maskChannel];
        #else
        if(maskChannel == 0)
        {
            s1 = mask.r;
            s1Strength =strength.r;
        }
        #endif
    }

    float CalculateShadowMask(float4 mask1Strength, 
    float4 mask2Strength, 
    float4 mask3Strength, 
    int maskChannel,
    int maskSelection,
    float4 shadowMask1,
    float4 shadowMask2,
    float4 shadowMask3)
    {
        float s1 =  1.0f;
        float s1Strength = 0.0f;

        [branch]
        switch(maskSelection)
        {
            default:
                break;
            #if defined(_VRSL_SHADOWMASK1)
            case 1:
                SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask1,mask1Strength);
                break;
            #endif
            #if defined(_VRSL_SHADOWMASK2)
            case 2:
                SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask2,mask2Strength);
                break;
            #endif
            #if defined(_VRSL_SHADOWMASK3)
            case 3:
                SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask3,mask3Strength);
                break;  
            #endif              
        }

        return lerp(1,s1,s1Strength);
    }

    float3 VRSLGI(float3 worldPos, float3 worldNormal, float roughness, float3 eyeVec, float3 diffuseColor, float2 mg, float2 uv, float occlusion)
    {
        float3 finalOut = 0.0;
        float3 viewDirection = normalize(eyeVec.xyz);
            float4 shadowmask1 = float4(1,1,1,1);
            float4 shadowmask2 = float4(1,1,1,1);
            float4 shadowmask3 = float4(1,1,1,1);
        #ifndef VRSL_GI_PROJECTOR
            #ifdef _VRSL_SHADOWMASK1
                shadowmask1 = VRSLShadowMask1(uv);
            #endif
            #ifdef _VRSL_SHADOWMASK2
                shadowmask2 = VRSLShadowMask2(uv);
            #endif
            #ifdef _VRSL_SHADOWMASK3
                shadowmask3 = VRSLShadowMask3(uv);
            #endif
        #endif
        #ifndef VRLSGI_USE_BUILTIN_SPECULAR
            #if _VRSL_GI_SPECULARHIGHLIGHTS
                float metallic = _VRSLSpecularStrength;
                #ifndef VRSL_GI_PROJECTOR
                    roughness = lerp(roughness,mg.y,_VRSLGlossMapStrength);
                    metallic =  lerp(metallic,mg.x,_VRSLMetallicMapStrength);

                    #ifndef VRSL_GI_PROJECTOR
                        metallic = abs(_VRSLInvertMetallicMap - metallic);
                        roughness = abs(_VRSLInvertSmoothnessMap - roughness);
                    #endif
                #endif
                roughness = max(roughness, 0.002);
            #endif
        #else
            float metallic = mg.x;
            roughness = mg.y;
        #endif


        float shadowmask = 1.0;


        
        #ifdef _VRSL_GLOBALLIGHTTEXTURE
            int lightCount = _Udon_VRSL_GI_LightTexture.Load( int3(0, 2, 0) );
        #else
            int lightCount = _VRSL_LightTexture.Load( int3(0, 2, 0) );
        #endif


        [loop]
        for (int x = 0; x < lightCount; x++)
        {
            
            //Begin Diffuse Stuff


            #if _VRSL_GI_ANGLES
                #ifdef _VRSL_GLOBALLIGHTTEXTURE
                    float4 rawLightColor = _Udon_VRSL_GI_LightTexture.Load( int3(x, 0, 0) );
                    float4 lightPos = _Udon_VRSL_GI_LightTexture.Load( int3(x, 1, 0) );
                #else 
                    float4 rawLightColor = _VRSL_LightTexture.Load( int3(x, 0, 0) );
                    float4 lightPos = _VRSL_LightTexture.Load( int3(x, 1, 0) );
                #endif
                float isSpotlight = lightPos.w;
            #else
                #ifdef _VRSL_GLOBALLIGHTTEXTURE
                    float4 rawLightColor = _Udon_VRSL_GI_LightTexture.Load( int3(x, 0, 0) );   
                    float4 lightPos = _Udon_VRSL_GI_LightTexture.Load( int3(x, 1, 0) );
                #else
                    float4 rawLightColor = _VRSL_LightTexture.Load( int3(x, 0, 0) );   
                    float4 lightPos = _VRSL_LightTexture.Load( int3(x, 1, 0) );
                #endif
            #endif

            float3 lightColor = rawLightColor.rgb * (0.5 * rawLightColor.a);
            float specular = 1.0;
            
            
            
            //Begin Diffuse Stuff
            float range = distance(worldPos, lightPos.xyz);
            float3 lightDirection = normalize(lightPos.xyz - worldPos);
            #if _VRSL_DIFFUSETOON
                float atten = saturate(dot(lightDirection, worldNormal) );
                atten = lerp(0.0025, 1.0, atten);
                atten = smoothstep(0,0.01,atten);
            #elif _VRSL_DIFFUSETINT
                float atten = 1.0f;
            #else
                float atten = saturate(dot(lightDirection, worldNormal) );
            #endif        
            range*= rawLightColor.a;
            float falloff = 1.0 / (range * range);
            //End Diffuse Stuff

            //Begin Specular Stuff
            #if _VRSL_GI_SPECULARHIGHLIGHTS
                #ifdef _VRSL_SPECFUNC_GGX
                    specular = GGXSpec(worldNormal, viewDirection, lightDirection, roughness);
                #elif _VRSL_SPECFUNC_BECKMAN
                    specular = BeckmanSpec(worldNormal, viewDirection, lightDirection, roughness);
                #elif _VRSL_SPECFUNC_PHONG
                    specular = PhongSpec(worldNormal, viewDirection, lightDirection, roughness);
                #endif
                specular = lerp(1.0, specular, metallic) * _VRSLSpecularMultiplier;
                specular = lerp(specular, specular * specular, _VRSLSpecularShine);

                specular *= (1/(range*0.5));
                //specular *= CalcLuminance(rawLightColor.rgb);
            #endif
            //End SPecular Stuff

            //Begin ShadowMask Stuff
            #ifndef VRSL_GI_PROJECTOR
                #if defined(_VRSL_SHADOWMASK1) || defined(_VRSL_SHADOWMASK2) || defined(_VRSL_SHADOWMASK3)
                    lightPos.w = (frac(lightPos.w * 0.1)) * 10;

                    int maskSelection = (int) floor(lightPos.w);
                    int maskChannel = (int) floor(frac(lightPos.w) * 10);

                    shadowmask = saturate(CalculateShadowMask(float4(_UseVRSLShadowMask1RStrength,
                    _UseVRSLShadowMask1GStrength,_UseVRSLShadowMask1BStrength, _UseVRSLShadowMask1AStrength),
                    float4(_UseVRSLShadowMask2RStrength, _UseVRSLShadowMask2GStrength, _UseVRSLShadowMask2BStrength, _UseVRSLShadowMask2AStrength),
                    float4(_UseVRSLShadowMask3RStrength, _UseVRSLShadowMask3GStrength, _UseVRSLShadowMask3BStrength, _UseVRSLShadowMask3AStrength)
                    , maskChannel, maskSelection,
                    shadowmask1, shadowmask2, shadowmask3));
                #endif             
                
            #endif
            //End Shadowmask Stuff

            //Combine
            lightColor = lerp(float3(0,0,0), lightColor * _VRSLGIStrength, shadowmask);
            diffuseColor = lerp(float3(1,1,1), diffuseColor, _VRSLDiffuseMix);
            
            #if _VRSL_GI_ANGLES
                
               if(isSpotlight > 180.0f)
               {
                    #ifdef _VRSL_GLOBALLIGHTTEXTURE
                        float4 rawLightDirection = _Udon_VRSL_GI_LightTexture.Load( int3(x, 3, 0) );    
                    #else
                        float4 rawLightDirection = _VRSL_LightTexture.Load( int3(x, 3, 0) );    
                    #endif
                    float3 spotlightDir = rawLightDirection.xyz;
                    float angle = (floor(rawLightDirection.w - 1)) / 255;
                    float blend = frac(rawLightDirection.w);
                    angle = angle * 180.0;

                    float theta = dot(lightDirection, normalize(-spotlightDir));
                    float outerCone = cos(radians(angle));
                    float spotlight = clamp(theta - outerCone,0.0,1.0);
                    atten = lerp(atten, atten*spotlight, blend);
                    specular = lerp(specular, specular*spotlight, blend);
               }
            #endif

            #ifdef VRSL_GI_PROJECTOR
                lightColor = clamp(lightColor, float3(0,0,0), float3(_VRSLGIDiffuseClamp, _VRSLGIDiffuseClamp, _VRSLGIDiffuseClamp));
            #endif

            finalOut += falloff * lightColor  * atten * diffuseColor * clamp(specular, 0.0, _VRSLGISpecularClamp);
            //finalOut += (spotlight);
            
        }
        return finalOut * occlusion;
    }
//#endif

