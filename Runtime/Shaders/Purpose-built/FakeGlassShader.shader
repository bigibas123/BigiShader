Shader "Bigi/FakeGlass"
{
    Properties
    {
        [Enum(Off,0,Background,1,Geometry,2,AlphaTest,3,Geometry501,4,Transparent,5,Overlay,6)] _SelectedQueue ("Render QueueId", Range(0,4)) = 1
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags
        {
            "IgnoreProjector" = "True"
        }

        LOD 100
        GrabPass
        {
            "_BackgroundTexture"
            Tags
            {
                "Queue"="Background"
            }
        }
        GrabPass
        {
            "_GeometryTexture"
            Tags
            {
                "Queue"="Geometry"
            }
        }
        GrabPass
        {
            "_AlphaTestTexture"
            Tags
            {
                "Queue"="AlphaTest"
            }
        }
        GrabPass
        {
            "_2501Texture"
            Tags
            {
                "Queue"="Geometry+501"
            }
        }
        GrabPass
        {
            "_TransparentTexture"
            Tags
            {
                "Queue"="Transparent"
            }
        }
        GrabPass
        {
            "_OverlayTexture"
            Tags
            {
                "Queue"="Overlay"
            }
        }

        Pass
        {
            Tags
            {
                "RenderType" = "Opaque" "Queue"="Overlay+1001"
            }
            ZWrite On
            ZTest LEqual
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform uint _SelectedQueue;
            sampler2D _BackgroundTexture;
            sampler2D _GeometryTexture;
            sampler2D _AlphaTestTexture;
            sampler2D _2501Texture;
            sampler2D _TransparentTexture;
            sampler2D _OverlayTexture;

            struct v2f
            {
                float4 grabPos : TEXCOORD0;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // use UnityObjectToClipPos from UnityCG.cginc to calculate 
                // the clip-space of the vertex
                o.pos = UnityObjectToClipPos(v.vertex);

                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                //Off,0,Background,1,Geometry,2,AlphaTest,3,Transparent,4;
                const float4 uv = i.grabPos;
                half4 bgcolor;
                switch (_SelectedQueue)
                {
                case 1:
                    {
                        bgcolor = tex2Dproj(_BackgroundTexture, uv);
                        break;
                    }
                case 2:
                    {
                        bgcolor = tex2Dproj(_GeometryTexture, uv);
                        break;
                    }
                case 3:
                    {
                        bgcolor = tex2Dproj(_AlphaTestTexture, uv);
                        break;
                    }
                case 4:
                    {
                        bgcolor = tex2Dproj(_2501Texture, uv);
                        break;
                    }
                case 5:
                    {
                        bgcolor = tex2Dproj(_TransparentTexture, uv);
                        break;
                    }
                case 6:
                    {
                        bgcolor = tex2Dproj(_OverlayTexture, uv);
                        break;
                    }
                case 0:
                default:
                    {
                        bgcolor = half4(0, 0, 0, 0);
                        break;
                    }
                }

                bgcolor.a = 1.0;
                return bgcolor;
            }
            ENDHLSL
        }

    }
}