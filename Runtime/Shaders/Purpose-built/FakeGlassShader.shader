Shader "Bigi/FakeGlass"
{
    Properties
    {
        [Enum(Off,0,RenderQueue,1,DepthTexture,2)] _SelectedFunction ("Inspection subject", Range(0,2)) = 1
        [Enum(Background,1,Geometry,2,AlphaTest,3,Geometry501,4,Transparent,5,Overlay,6)] _SelectedQueue ("Render QueueId", Range(0,4)) = 1
        [PowerSliderDrawer] _SampleDistance("Sample distance multiplier",Range(1.0,100.0)) = 1.0
        [PowerSliderDrawer] _DetectionDiff("Edge detection difference multiplier",Range(1.0,100.0)) = 16.0
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
                "RenderType" = "Transparent" "Queue"="Overlay+1001"
            }
            ZWrite Off
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include <UnityCG.cginc>
            #include "../Includes/Epsilon.cginc"

            uniform uint _SelectedQueue;
            uniform uint _SelectedFunction;
            uniform float _SampleDistance;
            uniform float _DetectionDiff;

            sampler2D _BackgroundTexture;
            sampler2D _GeometryTexture;
            sampler2D _AlphaTestTexture;
            sampler2D _2501Texture;
            sampler2D _TransparentTexture;
            sampler2D _OverlayTexture;

            sampler2D _CameraDepthTexture;
            sampler2D _CameraMotionVectorsTexture;

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

            half4 DoQueueShow(const in v2f i)
            {
                //Background,1,Geometry,2,AlphaTest,3,Transparent,4;
                const float4 uv = i.grabPos;
                half4 result;
                switch (_SelectedQueue)
                {
                case 1:
                    {
                        result = tex2Dproj(_BackgroundTexture, uv);
                        break;
                    }
                case 2:
                    {
                        result = tex2Dproj(_GeometryTexture, uv);
                        break;
                    }
                case 3:
                    {
                        result = tex2Dproj(_AlphaTestTexture, uv);
                        break;
                    }
                case 4:
                    {
                        result = tex2Dproj(_2501Texture, uv);
                        break;
                    }
                case 5:
                    {
                        result = tex2Dproj(_TransparentTexture, uv);
                        break;
                    }
                case 6:
                    {
                        result = tex2Dproj(_OverlayTexture, uv);
                        break;
                    }
                default:
                    {
                        result = half4(0, 0, 0, 0);
                        break;
                    }
                }

                result.a = 1.0;
                return result;
            }

            half4 DoDepthTexture(const in v2f i)
            {
                const float4 uv = i.grabPos;
                half4 result;
                const float diff = Epsilon * _DetectionDiff;
                const float sampleDist = Epsilon * _SampleDistance;
                switch (_SelectedQueue)
                {
                case 1:
                    {
                        result = tex2Dproj(_CameraDepthTexture, uv).rrrr;
                        break;
                    }
                case 2:
                    {
                        result = half4(0, 0, 0, 1);
                        const half4 _00 = tex2Dproj(_CameraDepthTexture,
                                                    float4(uv.x - sampleDist, uv.y - sampleDist, uv.z, uv.w));
                        const half4 _01 = tex2Dproj(_CameraDepthTexture,
                                                    float4(uv.x - sampleDist, uv.y + sampleDist, uv.z, uv.w));
                        const half4 _10 = tex2Dproj(_CameraDepthTexture,
                                                    float4(uv.x + sampleDist, uv.y - sampleDist, uv.z,
                                                           uv.w));
                        const half4 _11 = tex2Dproj(_CameraDepthTexture,
                                                    float4(uv.x + sampleDist,
                                                           uv.y + sampleDist, uv.z, uv.w));
                        const half4 centre = tex2Dproj(_CameraDepthTexture, float4(uv.x, uv.y, uv.z, uv.w));
                        const half4 minimum = min(_00, min(_01, min(_10, _11)));
                        const half4 maximum = max(_00, max(_01, max(_10, _11)));

                        const half mindiff = distance(centre, minimum);
                        const half maxdiff = distance(centre, maximum);

                        if (mindiff > diff)
                        {
                            result.r = 1.0;
                        }
                        if (distance(minimum, maximum) > diff)
                        {
                            result.g = 1.0;
                        }
                        if (maxdiff > diff)
                        {
                            result.b = 1.0;
                        }
                        break;
                    }
                case 3:
                    {
                        break;
                    }
                case 4:
                    {
                        result = tex2Dproj(_CameraMotionVectorsTexture, uv);
                        break;
                    }

                case 5:
                    {
                        break;
                    }
                case 6:
                    {
                        break;
                    }

                default:
                    {
                        result = half4(0, 0, 0, 0);
                        break;
                    }
                }

                return result;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 bgcolor;
                // Off,0,RenderQueue,1,DepthTexture,2
                switch (_SelectedFunction)
                {
                case 1:
                    {
                        bgcolor = DoQueueShow(i);
                        break;
                    }
                case 2:
                    {
                        bgcolor = DoDepthTexture(i);
                        break;
                    }
                case 0:
                default:
                    {
                        bgcolor = half4(0, 0, 0, 0);
                        break;;
                    }
                }
                bgcolor.a = 1.0;
                return bgcolor;
            }
            ENDHLSL
        }

    }
}