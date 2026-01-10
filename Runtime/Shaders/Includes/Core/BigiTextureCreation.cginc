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
		float4 realdp = float4(
			dp.z >= 0.0 ? dp.x : (dp.x + dp.z),
			dp.w >= 0.0 ? dp.y : (dp.y + dp.w),
			dp.z >= 0.0 ? dp.z : abs(dp.z),
			dp.w >= 0.0 ? dp.w : abs(dp.w)
		);

		uv = (uv.xy - realdp.xy);
		uv = (uv - floor(uv));
		return (uv.x > 0.0) && (uv.y > 0.0) && (uv.x < realdp.z) && (uv.y < realdp.w);
	}

	float2 CalcDecalUv(const in float4 dp, in float2 uv)
	{
		return (uv - dp.xy) / dp.zw;
	}

	// TODO Maybe better color mixing/layering?
	// Might already be the best it can be?
	// I'm doing color + alpha blending and using the color blending terms
	float4 DoMix(in float4 total, const in float4 input, const in float strength, const in uint mode)
	{
		const float decalWeight = (input.a * strength);
		float3 result;
		switch (mode)
		{
		default:
		case 0: // Replace
			{
				result = input.rgb * (input.a * total.a);
				break;
			}
		case 1: // Multiply
			{
				result = total.rgb * (input.rgb * input.a);
				break;
			}
		case 2: // Screen
			{
				result = (1.0 - ((1.0 - (total.rgb * total.a)) * (1.0 - (input.rgb * input.a))))
					* ((input.a + total.a) / 2.0);
				break;
			}
		case 3: // Add
			{
				result = total.rgb + (input.rgb * input.a);
				break;
			}
		case 4: // Subtract
			{
				result = total.rgb - (input.rgb * input.a);
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
		#ifndef BIGI_TEXTURE_UNIFORMS_DEFINED
		float4 MAINTEX_NAME##_ST = float4(0,0,0,0);
		#endif
		float4 color = GET_TEX_COLOR_MAINTEX(uv);
		#if defined(DO_ALPHA_PLS)
		color.a *= _Alpha_Multiplier;
		#endif
		#ifdef DECAL_1_ENABLED
		if ((_Decal1_Opacity > Epsilon) && (IsInsidePos(_Decal1_Position, uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal1(CalcDecalUv(_Decal1_Position, uv));
			color = DoMix(color, decalColor, _Decal1_Opacity, _Decal1_BlendMode);
		}
		#endif
		#ifdef DECAL_2_ENABLED
		if ((_Decal2_Opacity > Epsilon) && (IsInsidePos(_Decal2_Position, uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal2(CalcDecalUv(_Decal2_Position, uv));
			color = DoMix(color, decalColor, _Decal2_Opacity, _Decal2_BlendMode);
		}
		#endif
		#ifdef DECAL_3_ENABLED
		if ((_Decal3_Opacity > Epsilon) && (IsInsidePos(_Decal3_Position, uv)))
		{
			const float4 decalColor = b_decal::GetTexColorDecal3(CalcDecalUv(_Decal3_Position, uv));
			color = DoMix(color, decalColor, _Decal3_Opacity, _Decal3_BlendMode);
		}
		#endif
		#if defined(BIGI_PROTV_OPACITY_VAR) && defined(BIGI_PROTV_POSITION_VAR) && defined(BIGI_PROTV_ON_VAR)
		#ifndef BIGI_PROTV_TEST_VAR
		#define BIGI_PROTV_TEST_VAR (false)
		#endif
		if (BIGI_PROTV_ON_VAR && ((BIGI_PROTV_TEST_VAR || (PROTV_PRESENT() && BIGI_PROTV_OPACITY_VAR > Epsilon)) &&
			IsInsidePos(BIGI_PROTV_POSITION_VAR, uv)))
		{
			const float4 decalColor = b_protv_util::getTexColor(CalcDecalUv(BIGI_PROTV_POSITION_VAR, uv));
			color = DoMix(color, decalColor, max(BIGI_PROTV_OPACITY_VAR, BIGI_PROTV_TEST_VAR), 0.0);
		}
		#endif
		#if defined(DO_ALPHA_PLS)
		color.a = clamp(color.a, 0.0, 1.0);
		#endif

		return color;
	}
	#endif
}

#endif
