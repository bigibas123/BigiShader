Shader "Bigi/DisolveTest"
{
    Properties
    {
        _Offset ("Range",Range(0,1.0)) = 0
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha

        LOD 100

        HLSLINCLUDE
        #define BIG_SHADER_PARAMS_CUSTOM_PARAMS \
            uniform float _Offset;

        #define BIGI_VERT_ONLY_OBJECTSPACE

        #include "../Includes/Core/BigiShaderStructs.cginc"
        #include "../Includes/Core/BigiShaderParams.cginc"


        #define BIGI_DISOLVE_WITH_NOISE
        #ifdef BIGI_DISOLVE_WITH_NOISE
        #include <Packages/lygia/generative/snoise.hlsl>

        float offset_positive(const float x, const float min)
        {
            return (x * (1.0 - min)) + min;
        }

        float get_random(const in float3 pos, const in float offset)
        {
            return offset_positive(snoise((pos.xyz * 16.0) + (offset)), 0.5);
        }

        float get_power(const in float3 pos, const in float offset)
        {
            return lerp(lerp(0.0, get_random(pos, offset), offset), 1.0, offset);
        }
        #else
        float get_power(const in float4 pos, const in float offset)
        {
            return offset;
        }
        #endif

        [instance(1)]
        [maxvertexcount(3)]
        void geom(triangle v2f input[3], inout TriangleStream<v2f> os
        )
        {
            const float3 scale = 1.0 / float3(
                length(unity_ObjectToWorld._m00_m10_m20),
                length(unity_ObjectToWorld._m01_m11_m21),
                length(unity_ObjectToWorld._m02_m12_m22)
            );
            // const float3 scale = 1.0;
            const float3 totalPos = input[0].pos.xyz + input[1].pos.xyz + input[2].pos.xyz;
            const float3 normal = ((normalize(totalPos) / 3.0) * scale);

            float power = get_power(totalPos, _Offset);
            input[0].pos.xyz += normal * power;
            input[1].pos.xyz += normal * power;
            input[2].pos.xyz += normal * power;

            #ifdef BIGI_VERT_ONLY_OBJECTSPACE
            input[0].pos = UnityObjectToClipPos(input[0].pos.xyz);
            input[1].pos = UnityObjectToClipPos(input[1].pos.xyz);
            input[2].pos = UnityObjectToClipPos(input[2].pos.xyz);

            input[0].normal = UnityObjectToWorldNormal(input[0].normal);
            input[1].normal = UnityObjectToWorldNormal(input[1].normal);
            input[2].normal = UnityObjectToWorldNormal(input[2].normal);

            input[0].tangent.xyz = UnityObjectToWorldDir(input[0].tangent);
            input[1].tangent.xyz = UnityObjectToWorldDir(input[1].tangent);
            input[2].tangent.xyz = UnityObjectToWorldDir(input[2].tangent);

            #else
            #error " BIGI_VERT_ONLY_OBJECTSPACE not defined!"
            #endif

            os.Append(input[0]);
            os.Append(input[1]);
            os.Append(input[2]);
            os.RestartStrip();
        }
        ENDHLSL

        Pass
        {
            Name "ForwardBase"
            Tags
            {
                "RenderType" = "TransparentCutout" "Queue" = "Geometry" "VRCFallback"="None" "LightMode" = "ForwardBase"
            }
            Cull Off
            ZWrite On
            ZTest LEqual
            Blend One OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex bigi_toon_vert
            #pragma geometry geom
            #pragma fragment frag
            #define NO_MAINTEX
            #include_with_pragmas "../Includes/Pragmas/ForwardBase.cginc"
            #include <UnityCG.cginc>
            #include <HLSLSupport.cginc>
            #pragma target 3.0
            #define GET_TEX_COLOR(uv) float4(1.0,1.0,1.0,1.0)
            #include "../Includes/ToonVert.cginc"

            #include "../Includes/Lighting/BigiLightingParamWriter.cginc"

            fragOutput frag(v2f i)
            {
                b_light::setVars();
                fixed4 orig_color = GET_TEX_COLOR(i.uv);
                clip(orig_color.a - Epsilon);
                fragOutput o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_INITIALIZE_OUTPUT(fragOutput, o);

                BIGI_GETLIGHT_DEFAULT(light);
                o.color = orig_color * light;
                UNITY_APPLY_FOG(i.fogCoord, o.color);
                return o;
            }
            ENDHLSL
        }
        Pass
        {
            Name "ForwardAdd"
            Tags
            {
                "RenderType" = "TransparentCutout" "Queue" = "Geometry" "VRCFallback"="None" "LightMode" = "ForwardAdd"
            }
            Cull Off
            ZWrite On
            ZTest LEqual
            Blend One OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex bigi_toon_vert
            #pragma geometry geom
            #pragma fragment frag
            #define NO_MAINTEX
            #include_with_pragmas "../Includes/Pragmas/ForwardAdd.cginc"
            #include <UnityCG.cginc>
            #include <HLSLSupport.cginc>
            #pragma target 3.0
            #define GET_TEX_COLOR(uv) float4(1.0,1.0,1.0,1.0)
            #include "../Includes/ToonVert.cginc"
            #include "../Includes/Lighting/BigiLightingParamWriter.cginc"

            fragOutput frag(v2f i)
            {
                b_light::setVars();
                fixed4 orig_color = GET_TEX_COLOR(i.uv);
                clip(orig_color.a - Epsilon);
                fragOutput o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_INITIALIZE_OUTPUT(fragOutput, o);

                BIGI_GETLIGHT_DEFAULT(light);
                o.color = orig_color * light;
                UNITY_APPLY_FOG(i.fogCoord, o.color);
                return o;
            }
            ENDHLSL
        }
    }
}