﻿#ifndef BIGI_EFFECTS_INCLUDE
#define BIGI_EFFECTS_INCLUDE
#include <HLSLSupport.cginc>
#include "./ColorUtil.cginc"
#include "./SoundUtilsDefines.cginc"

#ifndef BIGI_LYGIA_PATCHES
#ifndef RANDOM_SCALE_4
#define RANDOM_SCALE_4 float4(443.897, 441.423, .0973, 1.6334)
#endif
#endif
#include <Packages/lygia/generative/voronoi.hlsl>


namespace b_effects
{
	struct BEffectsTracker
	{
		float totalWeight;
		fixed3 totalColor;
	};

	void doMixProperly(inout BEffectsTracker obj, in const fixed3 color, in const float weight, in const float force)
	{
		obj.totalWeight += weight;
		obj.totalColor = lerp(obj.totalColor, color, (weight * force) / obj.totalWeight);
	}

	fixed3 Monochromize(half3 input, float alpha)
	{
		half colorValue = RGBToHSV(input.rgb * alpha).z;
		return fixed3(colorValue, colorValue, colorValue);
	}

	float3 get_voronoi(in half2 uv)
	{
		float3 voronoiOutput = voronoi(uv * 10.0, b_sound::GetTimeRaw());
		return HSVToRGB(half3((voronoiOutput.x + voronoiOutput.y) / 2.0f, 1.0, 1.0));
	}

	// float3 get_quantize()
	// {
	//     return float3(0,0,0);
	// }

	half3 get_meta_emissions(in const half3 orig_color,
							in const fixed4 mask,
							in const float emission_strength
	)
	{
		BEffectsTracker mix;
		mix.totalColor = 0.0;
		mix.totalWeight = 0.0;

		doMixProperly(mix, orig_color.rgb * emission_strength * max(1.0, emission_strength), mask.r, 1.0);

		GET_SOUND_COLOR(soundC);
		doMixProperly(mix, soundC.rgb, mask.b * RGBtoHCV(soundC).z * soundC.a, mix.totalWeight + 1.0);

		return mix.totalColor;
	}

	fixed4 apply_effects(in half2 uv, in fixed4 mask, in fixed4 orig_color, fixed4 lighting,
						in float4 staticTexturePos)
	{
		BEffectsTracker mix;
		mix.totalWeight = 1.0;
		mix.totalColor = orig_color.rgb * (lighting.rgb * lighting.a);
		//AudioLink
		{
			GET_SOUND_COLOR(soundC);
			doMixProperly(mix, soundC.rgb, mask.b * RGBtoHCV(soundC).z * soundC.a, 2.0);
		}
		//"Emissions"
		{
			doMixProperly(mix, orig_color.rgb * (max(1.0, _EmissionStrength) * max(1.0, _EmissionStrength)),
						mask.r * _EmissionStrength, 1.0);
		}
		#ifdef OTHER_BIGI_TEXTURES
		//Screenspace images
		{
			//ProTV Check
			if (_Udon_VideoTex_TexelSize.z <= 16)
			{
				// no video texture
				const half2 screen_texture_pos = TRANSFORM_TEX((staticTexturePos.xy / staticTexturePos.w), _Spacey);
				float4 spaceyColor= UNITY_SAMPLE_TEX2D(_Spacey, screen_texture_pos);
				doMixProperly(mix, spaceyColor.rgb, mask.g * spaceyColor.a, 1.0);
			}
			else
			{
				
				//const half2 tv_texture_pos = TRANSFORM_TEX((staticTexturePos.xy/staticTexturePos.w), _Udon_VideoTex);
				const half2 tv_texture_pos = TRANSFORM_TEX(uv, _Udon_VideoTex);
				float4 protvColor = UNITY_SAMPLE_TEX2D(_Udon_VideoTex, tv_texture_pos);
				doMixProperly(mix, protvColor.rgb, mask.g * protvColor.a, 1.0);
			}
		}
		#endif

		//Voronoi
		{
			if (_Voronoi > Epsilon)
			{
				//TODO move somewhere earlier so it respects lighting
				doMixProperly(mix, get_voronoi(uv) * lighting, _Voronoi, mix.totalWeight + _Voronoi);
			}
		}

		//Monochrome
		{
			if (_MonoChrome > Epsilon)
			{
				doMixProperly(mix, Monochromize(mix.totalColor, orig_color.a), _MonoChrome,
							mix.totalWeight + _MonoChrome);
			}
		}

		// //Quantize?
		// {
		//     if(0 > Epsilon)
		//     {
		//         
		//     }
		// }
		return half4(mix.totalColor, orig_color.a);
	}
}

#endif
