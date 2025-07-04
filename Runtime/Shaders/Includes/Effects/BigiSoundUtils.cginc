#ifndef BIGI_SOUND_UTILS
#define BIGI_SOUND_UTILS
#include "../Epsilon.cginc"


#ifndef BIGI_DMXAL_INCLUDES
#define BIGI_DMXAL_INCLUDES
#include <Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc>
#include "../Core/BigiShaderStructs.cginc"
#include "../ColorUtil.cginc"
#endif

namespace b_sound
{
	struct ALSettings
	{
		AudioLinkMode_e AL_Mode;
		float AL_Distance;
		float AL_Theme_Weight;
		half AL_TC_BassReactive; //bool for bass reactivity of the AL_Theme
	};

	struct MixRatio
	{
		float totalWeight;
		half3 totalColor;
	};

	/*
	Strange way of getting an autdiolink value, x [0,1] for how long ago y [0,3] for the band
	*/
	float GetAudioLink(float x)
	{
		x = (x % 1.0);
		float totalValue = 0;
		totalValue += AudioLinkLerp(ALPASS_AUDIOLINK + float2(((x * 1.0) % 1) * AUDIOLINK_WIDTH, 0)).r;
		// totalValue += AudioLinkLerp(ALPASS_AUDIOLINK + float2(((x * 2.0) % 1) * AUDIOLINK_WIDTH, 1)).r;
		// totalValue += AudioLinkLerp(ALPASS_AUDIOLINK + float2(((x * 4.0) % 1) * AUDIOLINK_WIDTH, 2)).r;
		// totalValue += AudioLinkLerp(ALPASS_AUDIOLINK + float2(((x * 8.0) % 1) * AUDIOLINK_WIDTH, 3)).r;

		return totalValue;
	}


	void doMixProperly(inout MixRatio obj, in const half3 color, in const float weight)
	{
		obj.totalWeight += weight;
		obj.totalColor = lerp(obj.totalColor, color, weight / (obj.totalWeight + Epsilon));
	}

	half4 GetDMXOrALColor(in const ALSettings conf)
	{
		MixRatio mix;
		mix.totalColor = half3(0.0, 0.0, 0.0);
		const float weightOffset = max(0.0, 1.0 - (conf.AL_Theme_Weight));
		mix.totalWeight = weightOffset;
		const uint2 cord = ALPASS_FILTEREDAUDIOLINK + uint2(5, 0);
		const float bassIntensity = AudioLinkData(cord).r;
		//AL Theme
		{
			if (conf.AL_Theme_Weight > Epsilon)
			{
				float4 color1 = AudioLinkData(ALPASS_THEME_COLOR0);
				float4 color2 = AudioLinkData(ALPASS_THEME_COLOR1);
				float4 color3 = AudioLinkData(ALPASS_THEME_COLOR2);
				float4 color4 = AudioLinkData(ALPASS_THEME_COLOR3);
				float4 intensities = float4(RGBToHSV(color1.rgb * color1.a).z, RGBToHSV(color2.rgb * color2.a).z,
				                            RGBToHSV(color3.rgb * color3.a).z, RGBToHSV(color4.rgb * color4.a).z);

				float4 finalColor;
				if (intensities.w > (Epsilon * 3.0))
				{
					finalColor = color4;
				}
				else if (intensities.z > (Epsilon * 3.0))
				{
					finalColor = color3;
				}
				else if (intensities.y > (Epsilon * 3.0))
				{
					finalColor = color2;
				}
				else if (intensities.x > (Epsilon * 3.0))
				{
					finalColor = color1;
				}
				else
				{
					finalColor = float4(0, 0, 0, 0);
				}
				const float soundIntensity = clamp(lerp(1.0, bassIntensity, conf.AL_TC_BassReactive), 0.0, 1.0);
				switch (conf.AL_Mode)
				{
				case AudioLinkMode::ALM_Flat:
					{
						doMixProperly(mix, finalColor.rgb, soundIntensity * conf.AL_Theme_Weight);
						break;
					}
				case AudioLinkMode::ALM_CenterOut:
				case AudioLinkMode::ALM_WireFrame:
					{
						doMixProperly(mix, finalColor.rgb,
						              soundIntensity * conf.AL_Theme_Weight * GetAudioLink(conf.AL_Distance));
						break;
					}
				}
			}
		}
		return half4(mix.totalColor, (mix.totalWeight - weightOffset) / (conf.AL_Theme_Weight + Epsilon));
	}

	half4 GetThemeColor(const uint ccindex)
	{
		return AudioLinkData(ALPASS_THEME_COLOR0 + uint2(ccindex, 0));
	}

	float GetTime()
	{
		return AudioLinkGetChronoTime(0, 0) % 2.0f / 2.0f;
	}

	float GetTimeRaw()
	{
		return AudioLinkGetChronoTime(0, 0);
	}

	float GetAutoCorrelator(float x)
	{
		return AudioLinkLerp(ALPASS_AUTOCORRELATOR + float2(x * AUDIOLINK_WIDTH, 0)).r;
	}

	float GetWaves(in float distance)
	{
		return (GetAudioLink(distance) * 2.5) + Epsilon; //+ (GetAutoCorrelator(distance * 10.0) * 2.5) + 1.0;
	}
}
#endif
