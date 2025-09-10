#ifndef PART_SCR_TEXSAMPLE_UTILS_INCLUDED
#define PART_SCR_TEXSAMPLE_UTILS_INCLUDED
/*
Geometry stage compatible partial re-implementation of some functions in ProTV: `Resources/Shaders/ProTVCore.cginc`
Makes it so the particles get offset in the z direction in object space if they're bright.
I'll later make it so functions can be re-implemented or values changed via defines and the like. 

ProTV License:
(based on the ISC License)

Copyright (c) 2020-2024 ArchiTechVR

Permission to use, copy, modify, and/or distribute this asset for any
purpose, except for resale in whole or in part, with or without fee is hereby granted, 
provided that the above copyright notice and this permission notice appear in all copies.
For clarity, permission is expressly granted to distribute and sell assets and prefabs
which make use of the functions and/or content of this asset.

THE ASSET IS PROVIDED "AS IS" AND THE AUTHOR(S) DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS ASSET INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS ASSET.
 */

#include "../../ColorUtil.cginc"
#include <Packages/dev.architech.protv/Resources/Shaders/ProTVCore.cginc>

namespace b_particalizer
{
	#ifndef TEMP_IS_MIRROR_MODE
	#define TEMP_IS_MIRROR_MODE(mode) (step(mode-0.5, _Mirror) * (1.0 - step(mode+0.5, _Mirror)))
	#define TIMM_INCLUDED_DEFINED
	#endif
	#ifndef TEMP_DDX_NEGATIVE
	#define TEMP_DDX_NEGATIVE(uv) step(0.0, -0.0001)
	#define TDXN_INCLUDED_DEFINED
	#endif
	#ifndef TEMP_DDY_NEGATIVE
	#define TEMP_DDY_NEGATIVE(uv) step(0.0, -0.0001)
	#define TDYN_INCLUDED_DEFINED
	#endif

	// adjust uv if rendering in mirror
	void TVMirrorAdjustment_geom(inout float2 uv)
	{
		float mode1 = TEMP_IS_MIRROR_MODE(1);
		float mode2 = TEMP_IS_MIRROR_MODE(2);
		float2 flipMask = float2(
			mode1 * IsMirror() + mode2 * TEMP_DDX_NEGATIVE(uv), // Flip X conditions
			mode2 * TEMP_DDY_NEGATIVE(uv) // Flip Y conditions
		);
		uv = lerp(uv, 1.0 - uv, flipMask);
	}
	#ifdef TIMM_INCLUDED_DEFINED
	#undef TEMP_IS_MIRROR_MODE
	#undef TIMM_INCLUDED_DEFINED
	#endif
	#ifdef TDXN_INCLUDED_DEFINED
	#undef TEMP_DDX_NEGATIVE
	#undef TDN_INCLUDED_DEFINED
	#endif
	#ifdef TDYN_INCLUDED_DEFINED
	#undef TEMP_DDY_NEGATIVE
	#undef TDYN_INCLUDED_DEFINED
	#endif

	float2 ProcessFragmentUV_geom(const FragmentProcessingData data, out float visible)
	{
		float2 uv = data.inputUV;
		float2 videoDims = data.videoSize;
		bool noVideo = data.noVideo;
		const float4x4 videoData = data.videoData;

		float4 uvClip;
		float2 uvCenter;
		// use the 3D value from the TVData object when 3D is None
		const float mode3D = noVideo ? data.mode3D : Mode3D(videoData);
		const float wide3D = noVideo ? data.wide3D : Wide3D(videoData);
		// Setting force 2D to 1 makes both eyes render
		const float force2D = noVideo ? data.force2D : IsForce2D(videoData);

		float4 videoST = noVideo ? _MainTex_ST : data.videoST;
		uv = uv * videoST.xy + videoST.zw;

		// correct for any non-standard viewing orientations
		TVMirrorAdjustment_geom(uv);
		// normalize uv space for 3d considerations
		TV3DAdjustment(uv, videoDims, uvClip, uvCenter, mode3D, wide3D, force2D);
		// update uv to ensure source image aspect is respected
		#if _CROP_GAMMAZONE// && !_USEGLOBALTEXTURE
		if (!noVideo) TVGammaZoneAdjustment(uv, uvClip, uvCenter, data.gammaST);
		#endif
		TVAspectRatio(uv, data.outputAspect, videoDims, uvCenter, data.aspectFit);
		// calculate what pixels are a part of the image or are outside the image.
		TVAspectVisibility(uv, videoDims, uvClip, visible);

		// optionally clip pixels outside the image
		#if _CLIP_BORDERS
		clip((1 - ceil(visible)) * -1);
		#endif

		return uv;
	}

	float4 ProcessFragment_geom(const FragmentProcessingData data)
	{
		// The fragment processor goes in the following order:
		// - Correct uv for respective _ST values.
		// - If the uv is detected to be rendering in a mirror, flip as needed
		// - Adjust uv for the different 3D modes
		// - Apply any necessary aspect ratio correction
		// - Detect pixels that are outside the resulting texture space
		// - Optionally clip the pixels
		// - Get the target pixel for the uv
		// - Fade edge pixels for anti-aliasing
		// - Apply a brightness multiplier to the returned pixel

		float visible;
		float2 uv = ProcessFragmentUV_geom(data, visible);
		// sample the texture
		float4 tex;
		if (data.noVideo) tex = tex2Dlod(_MainTex, float4(uv, 0, 0));
		#if _USEGLOBALTEXTURE
		else tex = _Udon_VideoTex.SampleLevel(sampler_Udon_VideoTex, uv, 0);
		#else
		else tex = _VideoTex.SampleLevel(sampler_VideoTex, uv, 0);
		#endif
		// blend edge pixels to black/transparent
		// serves as a poor man's anti-alias
		::TVFadeEdges(tex, visible, data.fadeEdges);
		return tex * data.brightness;
	}


	float4 SampleTexture(const in B_P_V2G input)
	{
		FragmentProcessingData data = InitializeFragmentData(input.uv);
		float4 tex = ProcessFragment_geom(data);
		return tex;
	}


	float4 GetOffset(const in B_P_V2G input)
	{
		return float4(0.0f, 0.0f, 1.0 - RGBToHSV(SampleTexture(input).rgb).z, 0.0f);
	}
}

#endif
