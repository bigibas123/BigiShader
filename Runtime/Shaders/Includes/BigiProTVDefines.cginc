#ifndef BIGI_PROTV_DEFINES_H
#define BIGI_PROTV_DEFINES_H
#include "./BigiShaderTextures.cginc"
#include "./BigiShaderParams.cginc"

#ifndef PROTV_TEXTURES_INCLUDED
#define PROTV_TEXTURES_INCLUDED
//ProTV Textures
#if !defined(SHADER_API_D3D11)
uniform sampler2D _Udon_VideoTex;
float4 _Udon_VideoTex_TexelSize;
float4 _Udon_VideoTex_ST;
#define PROTV_PRESENT(outVar) bool outVar = (_Udon_VideoTex_TexelSize.z > 16)
#define GET_PROTV(uv) tex2D(_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex))
#else
UNITY_DECLARE_TEX2D(_Udon_VideoTex);
float4 _Udon_VideoTex_ST;
#define PROTV_PRESENT(outVar) int videoWidth; int videoHeight; _Udon_VideoTex.GetDimensions(videoWidth, videoHeight); bool outVar = (videoWidth > 16)
#define GET_PROTV(uv) _Udon_VideoTex.Sample(sampler_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex))
#endif
#endif

#ifdef PROTV_SQUARE_ENABLED

namespace b_protv_util
{
	float4 getTexColor(float2 uv)
	{
		if(_TV_Square_Opacity > Epsilon)
		{
			PROTV_PRESENT(tvPresent);
			tvPresent = tvPresent || (_SquareTVTest > 0.1);
			if (tvPresent
				&& (uv.x >= _TV_Square_Position.x && uv.x <= (_TV_Square_Position.x + _TV_Square_Position.z))
				&& (uv.y >= _TV_Square_Position.y && uv.y <= (_TV_Square_Position.y + _TV_Square_Position.w))
			)
			{
				const float2 newUv = float2(
					(uv.x - _TV_Square_Position.x) / _TV_Square_Position.z,
					(uv.y - _TV_Square_Position.y) / _TV_Square_Position.w
				);
				const float4 original_color =  GET_TEX_COLOR_REAL(uv);
				const float4 protv_color = GET_PROTV(newUv);
				return lerp(original_color, protv_color, max(_TV_Square_Opacity, _SquareTVTest));
			}
		}
		return GET_TEX_COLOR_REAL(uv);
	}
}
#endif

#endif