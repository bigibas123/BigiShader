#ifndef BIGI_TEXTURE_CREATION_H
#define BIGI_TEXTURE_CREATION_H
#include "../Epsilon.cginc"
#include "./BigiMainTex.cginc"
#include "../External/ProTV/BigiProTV.cginc"

#define NOT_ONE (1.0 + Epsilon)

namespace bigi_texture
{
	bool IsInsidePos(const in float4 dp, in float2 uv)
	{
		uv = uv % 1.0;
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
	float4 DoMix(in float4 total, const in float4 input, const in float param, const in uint mode)
	{
		const float decalWeight = (input.a * param);
		float3 result;
		switch (mode)
		{
		default:
		case 0: // Replace
			{
				result = input.rgb;
				break;
			}
		case 1: // Multiply
			{
				result = total.rgb * input.rgb;
				break;
			}
		case 2: // Screen
			{
				result = 1.0 - ((1.0 - total.rgb) * (1.0 - input.rgb));
				break;
			}
		case 3: // Add
			{
				result = total.rgb + input.rgb;
				break;
			}
		case 4: // Subtract
			{
				result = total.rgb - input.rgb;
				break;
			}
		}
		total.rgb = lerp(total.rgb, result.rgb, decalWeight);
		total.rgb = clamp(total.rgb, 0.0, 1.0);
		return total;
	}

	#if defined(GET_TEX_COLOR_MAINTEX)
	float4 GetTexColor(const in float2 uv)
	{
		float4 color = GET_TEX_COLOR_MAINTEX(uv);
		#if defined(DO_ALPHA_PLS) && defined(TRANSPARENT_FORWARD_BASE)
		color.a  *= _Alpha_Multiplier;
		#endif
		#ifdef DECAL_1_ENABLED
		if ((_Decal1_Opacity > Epsilon) && (IsInsidePos(_Decal1_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal1(CalcDecalUv(_Decal1_Position,uv));
			color = DoMix(color, decalColor, _Decal1_Opacity, _Decal1_BlendMode);
		}
		#endif
		#ifdef DECAL_2_ENABLED
		if ((_Decal2_Opacity > Epsilon) && (IsInsidePos(_Decal2_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal2(CalcDecalUv(_Decal2_Position,uv));
			color = DoMix(color, decalColor, _Decal2_Opacity, _Decal2_BlendMode);
		}
		#endif
		#ifdef DECAL_3_ENABLED
		if ((_Decal3_Opacity > Epsilon) && (IsInsidePos(_Decal3_Position,uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal3(CalcDecalUv(_Decal3_Position,uv));
			color = DoMix(color, decalColor, _Decal3_Opacity, _Decal3_BlendMode);
		}
		#endif
		#if defined(BIGI_PROTV_OPACITY_VAR) && defined(BIGI_PROTV_POSITION_VAR)
		#ifndef BIGI_PROTV_TEST_VAR
		#define BIGI_PROTV_TEST_VAR (false)
		#endif
		if ((BIGI_PROTV_TEST_VAR || (PROTV_PRESENT() && BIGI_PROTV_OPACITY_VAR > Epsilon)) && IsInsidePos(BIGI_PROTV_POSITION_VAR, uv))
		{
			const float4 decalColor = b_protv_util::getTexColor(CalcDecalUv(BIGI_PROTV_POSITION_VAR, uv));
			color = DoMix(color, decalColor, max(BIGI_PROTV_OPACITY_VAR, BIGI_PROTV_TEST_VAR), 0.0);
		}
		#endif

		return color;
	}
	#endif
}

#endif
