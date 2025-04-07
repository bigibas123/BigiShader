﻿#ifndef BIGI_TEXTURE_CREATION_H
#define BIGI_TEXTURE_CREATION_H
#include "./BigiMainTex.cginc"

#define NOT_ONE (1.0 + Epsilon)

namespace bigi_texture
{
	bool IsInsidePos(const in float4 dp, const in float2 uv)
	{
		const float4 corners = float4(dp.x, dp.y, dp.x + dp.z, dp.y + dp.w);
		return ((uv.x >= corners.x && uv.x <= corners.z) || (corners.z >= 1.0 && uv.x <= (corners.z % 1.0)))
			&& ((uv.y >= corners.y && uv.y <= corners.w) || (corners.w >= 1.0 && uv.y <= (corners.w % 1.0)));
	}

	float2 CalcDecalUv(const in float4 dp, const in float2 uv)
	{
		float2 shifted = float2(uv.x - dp.x, uv.y - dp.y);
		shifted = frac(shifted) / dp.zw;
		return shifted;
	}

	// TODO Maybe better color mixing/layering
	float4 DoMix(in float4 total, const in float4 input, const in float param)
	{
		const float decalOpacity = (input.a * param);
		total.rgb = lerp(total.rgb, input.rgb, decalOpacity);
		total.a = clamp(total.a + decalOpacity, 0.0, 1.0);
		return total;
	}


	float4 GetTexColor(const in float2 uv)
	{
		float4 color = GET_TEX_COLOR_MAINTEX(uv);
		#ifdef DECAL_1_ENABLED
		if ((_Decal1_Opacity > Epsilon) && (IsInsidePos(_Decal1_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal1(CalcDecalUv(_Decal1_Position,uv));
			color = DoMix(color, decalColor, _Decal1_Opacity);
		}
		#endif
		#ifdef DECAL_2_ENABLED
		if ((_Decal2_Opacity > Epsilon) && (IsInsidePos(_Decal2_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal2(CalcDecalUv(_Decal2_Position,uv));
			color = DoMix(color, decalColor, _Decal2_Opacity);
		}
		#endif
		#ifdef DECAL_3_ENABLED
		if ((_Decal3_Opacity > Epsilon) && (IsInsidePos(_Decal3_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal3(CalcDecalUv(_Decal3_Position,uv));
			color = DoMix(color, decalColor, _Decal3_Opacity);
		}
		#endif
		return color;
	}
}

#endif
