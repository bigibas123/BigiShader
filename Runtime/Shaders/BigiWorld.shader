Shader "Bigi/World (WIP)"
{
    Properties
    {
        [MainTexture] _MainTex ("Texture", 2D) = "black" {}
        [Toggle(DO_ALPHA_PLS)] _UsesAlpha("Is transparent (NOT ANIMATABLE)", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 2
        _Alpha_Threshold ("Alpha threshold",Range(-0.01,1.0)) = 0.99
        _Alpha_Multiplier ("Alpha Multiplier", Range(0.0,2.0)) = 1.0

        [Header(ZWriteZTest Settings)]
        [Header(Opaque Forward Base)]
        [Enum(Off, 0, On, 1)] _ZWriteOFWB ("ZWrite Opaque ForwardBase", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestOFWB ("Ztest Opaque ForwardBase", Int) = 4
        [Header(Transparent ForwardBase)]
        [Enum(Off, 0, On, 1)] _ZWriteTFWB ("ZWrite Transparent ForwardBase", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestTFWB ("Ztest Transparent ForwardBase", Int) = 2
        [Header(Other Passes)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestFWA ("Ztest ForwardAdd", Int) = 4
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestOL ("Ztest Outline", Int) = 4
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestSP ("Ztest Shadow Pass", Int) = 4

        [Header(Extra textures)]
        [Space]
        _Mask ("Mask", 2D) = "black" {}
        _EmissionStrength ("Emission strength", Range(0.0,2.0)) = 1.0
        [Space]
        _Spacey ("Spacey Texture", 2D) = "black" {}
        [Space]
        [Header(Normal mapping)]
        [Space]
        [NoScaleOffset] [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        [Toggle(NORMAL_MAPPING)] _UsesNormalMap("Enable normal map (NOT ANIMATABLE)", Float) = 1
        [Space]
        [Space]
        [Header(Decals)]
        [NoScaleOffset] _Decal1 ("Decal 1", 2D) = "black" {}
        [Toggle(DECAL_1_ENABLED)] _Decal1Enabled ("Enable decal 1 (NOT ANIMATABLE)", Float) = 0
        [Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal1_BlendMode ("Decal 1 blend mode",Range(0,4)) = 0
        _Decal1_Opacity ("Decal 1 opacity", Range(0.0,1.0)) = 1.0
        _Decal1_Position ("Decal 1 Position & Size", Vector) = (0.0,0.0,1.0,1.0)
        [Space]
        [NoScaleOffset] _Decal2 ("Decal 2", 2D) = "black" {}
        [Toggle(DECAL_2_ENABLED)] _Decal2Enabled ("Enable decal 2 (NOT ANIMATABLE)", Float) = 0
        [Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal2_BlendMode ("Decal 2 blend mode",Range(0,4)) = 0
        _Decal2_Opacity ("Decal 2 opacity", Range(0.0,1.0)) = 1.0
        _Decal2_Position ("Decal 2 Position & Size", Vector) = (0.0,0.0,1.0,1.0)
        [Space]
        [NoScaleOffset] _Decal3 ("Decal 3", 2D) = "black" {}
        [Toggle(DECAL_3_ENABLED)] _Decal3Enabled ("Enable decal 3 (NOT ANIMATABLE)", Float) = 0
        [Enum(Replace,0,Multiply,1,Screen,2,Add,3,Subtract,4)] _Decal3_BlendMode ("Decal 3 blend mode",Range(0,4)) = 0
        _Decal3_Opacity ("Decal 3 opacity", Range(0.0,1.0)) = 1.0
        _Decal3_Position ("Decal 3 Position & Size", Vector) = (0.0,0.0,1.0,1.0)

        [Header(Specular and Smooth)]
        [Space]
        [NoScaleOffset] _SpecSmoothMap ("Specular (rgb) and Smoothness (a) map (Deprecated)", 2D) = "black" {}
        [NoScaleOffset] _SpecGlossMap ("Specular (rgb) and Glossiness/Smoothness (a) map", 2D) = "black" {}

        [Header(Ambient Occlusion)]
        [Space]
        [NoScaleOffset] _OcclusionMap ("Ambient occlusion map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0, 1.0)) = 1.0

        [Space]
        [Header(Lighting)]
        [Space]
        _LightSmoothness ("Shadow smoothness",Range(0.0,1.0)) = 1.0
        [IntRange] _LightSteps ("Light steps", Range(0,256)) = 1
        [Space]
        _MinAmbient ("Minimum ambient intensity", Range(0.0,1.0)) = 0.005
        _Transmissivity ("Transmission of light through the material", Range(0.0,1.0)) = 0.2

        [Header(Lighting System strengths)]
        [Space]
        _FinalLightMultiply ("Master Light Multiplier",Range(0.0,5.0)) = 1.0
        _LightVertexMultiplier ("Vertex Multiplier",Range(0.0,5.0)) = 1.0
        _LightEnvironmentMultiplier ("Environment Multiplier",Range(0.0,5.0)) = 1.0
        _LightMainMultiplier ("Main Light Multiplier",Range(0.0,5.0)) = 1.0
        _LightAddMultiplier ("Added Pixel Light Multiplier",Range(0.0,5.0)) = 1.0
        _VRSLGIStrength ("VRSL-GI Strength", Range(0.0,5.0)) = 0.25
        _LTCGIStrength ("LTCGI Strenght", Range(0.0,5.0)) = 1.0
        _VRCLVStrength ("VRC Light Volumes Strength",Range(0.0,5.0)) = 1.0

        [Header(Audiolink)]
        [Space]
        [Enum(Flat,0,CenterOut,1,WireFrame,2)] _AL_Mode ("Audiolink mode", Range(0,2)) = 0
        [ToggleUI] _AL_BlockWireFrame ("Block wireframe mode, fallback to CenterOut", Range(0,1)) = 0
        [Space]
        _AL_Theme_Weight("Weight", Range(0.0, 1.0)) = 1.0
        _AL_TC_BassReactive("Bassreactivity", Range(0.0,1.0)) = 0.75
        _AL_WireFrameWidth ("Wireframe Width", Range(0.0,1.0)) = 0.05

        [Header(Effects)]
        [Space]
        _MonoChrome("MonoChrome", Range(0.0,1.0)) = 0.0
        _Voronoi("Voronoi", Range(0.0,1.0)) = 0.0
        _OutlineWidth ("Outline Width", Range(0.0,1.0)) = 0.0
        _Rounding ("Rounding Factor", Range(0.0,0.05)) = 0.0
        [ToggleUI] _DoMirrorThing ("Voronoi in mirror", Range(0.0,1.0)) = 1.0


        [Header(TV Square)]
        [Space]
        [ToggleUI] _EnableProTVSquare ("Enable ProTV texture render", Range(0.0,1.0)) = 0.0
        _TV_Square_Opacity ("TV opacity", Range(0.0,1.0)) = 0.0
        [ToggleUI] _SquareTVTest ("Enable temporarily to display tv location", Range(0.0,1.0)) = 0.0
        _TV_Square_Position ("TV Position & Size", Vector) = (0.0,0.0,1.0,1.0)

        [Header(Stencil settings (NOT ANIMATABLE))]
        [Space]
        [IntRange] _MainStencilRef ("Write this stencil value for the main avatar passes", Range(0, 255)) = 148
        [IntRange] _MainStencilWriteMask ("Use this mask while writing main passes", Range(0, 255)) = 255
        [Enum(UnityEngine.Rendering.StencilOp)] _MainStencilPass ("Operation on the value of the stencil buffer in main passes", Float) = 2

        [Header(Multi Texture)]
        [Space]
        _MainTexArray ("Other textures", 2DArray) = "" {}
        [Toggle(MULTI_TEXTURE)] _MultiTexture("Use multi texture (NOT ANIMATABLE)", Float) = 0
        _OtherTextureId ("Other texture Id", Int) = 0


    }

    CustomEditor "cc.dingemans.bigibas123.bigishader.BigiShaderEditor"
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags
        {
            "VRCFallback" = "ToonCutout" "LTCGI"="ALWAYS"
        }

        UsePass "Bigi/Main/OPAQUEFORWARDBASE"
        UsePass "Bigi/Main/TRANSPARENTFORWARDBASE"
        UsePass "Bigi/Main/FORWARDADD"
        UsePass "Bigi/Main/OUTLINE"
        UsePass "Bigi/Main/SHADOWPASS"
        
        Pass
        {
            Name "MetaPass"
            Tags
            {
                "LightMode"="Meta"
                "LTCGI"="ALWAYS"
            }
            Cull Off
            CGPROGRAM
            #include_with_pragmas "./Includes/Pragmas/Meta.cginc"
            #include"UnityStandardMeta.cginc"

            #include "./Includes/Core/BigiShaderParams.cginc"
            #include "./Includes/Core/BigiGetColor.cginc"
            #include "./Includes/Effects/BigiEffects.cginc"
            
            float4 frag_meta2(v2f_meta i): SV_Target
            {
                FragmentCommonData data = UNITY_SETUP_BRDF_INPUT(i.uv);
                // TODO for data:
                /*
                    float3 normalWorld;
                    float3 eyeVec;
                    half alpha;
                    float3 posWorld;
                 */
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
                float4 orig_color = GET_TEX_COLOR(GETUV);
                o.Albedo = orig_color.rgb;

                o.Emission = b_effects::apply_effects(
                    i.pos,
                    GETUV,
                    GET_MASK_COLOR(GETUV),
                    orig_color,
                    fixed4(0.0, 0.0, 0.0, 0.0),
                    float4(1.0, 1.0, 1.0, 1.0),
                    float4(0.0, 0.0, 0.0, 1.0)
                );
                o.SpecularColor = data.specColor;
                #ifdef EDITOR_VISUALIZATION
                    o.VisUV = ;//float2
                    o.LightCoord = ;//float4
                #endif
                return UnityMetaFragment(o);
            }

            #pragma vertex vert_meta
            #pragma fragment frag_meta2
            ENDCG
        }
    }
}