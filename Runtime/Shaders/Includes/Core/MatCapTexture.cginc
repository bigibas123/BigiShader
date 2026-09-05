#ifndef GET_MATCAP
        #ifndef GET_MATCAP_COLOR
                uniform float4 _MatCapColor;
                #define GET_MATCAP_COLOR() (_MatCapColor)
        #endif
        #include <HLSLSupport.cginc>
        UNITY_DECLARE_TEX2D(_MatCapTex);
        float4 _MatCapTex_ST;
        #define GET_MATCAP(uv) (UNITY_SAMPLE_TEX2D(_MatCapTex, TRANSFORM_TEX((uv),_MatCapTex)) * GET_MATCAP_COLOR())
#endif

#ifndef GET_MATCAP_COLOR
        #define GET_MATCAP_COLOR() float4(0.0,0.0,0.0,0.0)
#endif
