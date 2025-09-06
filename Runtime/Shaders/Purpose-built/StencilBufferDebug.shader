Shader "Bigi/StencilBufferDebug"
{
    
    Properties
    {
        [IntRange] _Scale ("Grid scale",Range(1,128)) = 64
    }
    SubShader
    {
        
        Stencil
        {
            Comp Equal
            WriteMask 0
            Pass Keep
        }
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Tags
        {
            "RenderType" = "Overlay" "Queue" = "Overlay" "IgnoreProjector" = "True" "LightMode" = "ForwardBase" "VRCFallback"="Hidden" "LTCGI"="ALWAYS"
        }
        HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        #include <UnityShaderUtilities.cginc>
        #include <UnityShaderVariables.cginc>
        #include <HLSLSupport.cginc>
        #include <UnityInstancing.cginc>
        #define SHIFT_AND_BYTE(val,shift) (((val >> (shift * 8)) & 0xFF) / 16.0)
        #define CONVERT_HEX(val) float3(SHIFT_AND_BYTE(0x##val,2),SHIFT_AND_BYTE(0x##val,1),SHIFT_AND_BYTE(0x##val,0))
        uniform float _Scale;
        
        struct appdata
        {
            float4 vertex : POSITION;
            float4 uv0 : TEXCOORD0;
            uint vertexId : SV_VertexID;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            UNITY_POSITION(pos); //float4 pos : SV_POSITION;
            float4 uv : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert(appdata v)
        {
            v2f o;
            UNITY_INITIALIZE_OUTPUT(v2f, o);
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_TRANSFER_INSTANCE_ID(v, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv0;
            return o;
        }

        fixed4 doFrag(v2f i, int stencilVal) : SV_Target
        {
            int bit = log2(stencilVal);
            fixed3 colour;
            switch (bit)
            {
            case 0:
                {
                    colour = CONVERT_HEX(FF0000);
                    break;
                }
            case 1:
                {
                    colour = CONVERT_HEX(00FF00);
                    break;
                }
            case 2:
                {
                    colour = CONVERT_HEX(0000FF);
                    break;
                }
            case 3:
                {
                    colour = CONVERT_HEX(7F0000);
                    break;
                }
            case 4:
                {
                    colour = CONVERT_HEX(007F00);
                    break;
                }
            case 5:
                {
                    colour = CONVERT_HEX(00007F);
                    break;
                }
            case 6:
                {
                    colour = CONVERT_HEX(00FFFF);
                    break;
                }
            case 7:
                {
                    colour = CONVERT_HEX(FFFF00);
                    break;
                }
            default:
                {
                    colour = CONVERT_HEX(000000);
                    break;
                }
            }
            half2 currentPos = (((abs(i.uv.xy) * _Scale) % 1.0)) * 3.0;
            const float eps = 0.1;
            if ((currentPos.x < eps && currentPos.x > -eps) || (currentPos.y < eps && currentPos.y > -eps))
            {
                return float4(0.0, 0.0, 0.0, 1.0);
            }

            int currentBlock = (floor(currentPos.x) + (floor(currentPos.y) * 3.0));
            if (currentBlock == bit)
            {
                return float4(colour, 1.0);
            }
            else
            {
                discard;
                return float4(0.0, 0.0, 0.0, 0.0);
            }
        }

        #define FRAG(stencilVal) fixed4 frag(v2f i) : SV_Target {  return doFrag(i,stencilVal); }
        ENDHLSL


        Pass
        {
            Stencil
            {
                Ref 1 ReadMask 1
            } HLSLPROGRAM
              FRAG(1)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 2 ReadMask 2
            } HLSLPROGRAM
              FRAG(2)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 4 ReadMask 4
            } HLSLPROGRAM
              FRAG(4)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 8 ReadMask 8
            } HLSLPROGRAM
              FRAG(8)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 16 ReadMask 16
            } HLSLPROGRAM
              FRAG(16)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 32 ReadMask 32
            } HLSLPROGRAM
              FRAG(32)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 64 ReadMask 64
            } HLSLPROGRAM
              FRAG(64)
              ENDHLSL
        }
        Pass
        {
            Stencil
            {
                Ref 128 ReadMask 128
            } HLSLPROGRAM
              FRAG(128)
              ENDHLSL
        }


    }

}