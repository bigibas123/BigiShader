#ifndef BIGI_GEOMPROCESSOR_INCL
#define BIGI_GEOMPROCESSOR_INCL
#if defined(BIGI_VERT_ONLY_OBJECTSPACE) || defined(BIGI_VERT_ONLY_WORLDSPACE)
#include <UnityCG.cginc>
#include <UnityShaderUtilities.cginc>
#endif
#ifdef BIGI_V2F_DISTANCE_VAR_NAME
#include "./Effects/LengthDefine.cginc"
#endif
#include <AutoLight.cginc>
#include "./Core/BigiShaderStructs.cginc"
#include "./Core/BigiShaderParams.cginc"
#include "./TileDiscardStuff.cginc"
// Wireframe effect
// Based on work from Garrett Johnson (gkjohnson) https://github.com/gkjohnson/unity-wireframe-shader/tree/master
// Which is based on the paper "Shader-Based Wireframe Drawing" authored by J. A. Bærentzen,S. L. Nielsen, M. Gjøl & B. D. Larsen: https://cgg-journal.com/2008-2/06/index.html archived here: https://web.archive.org/web/20130322011415/http://cgg-journal.com/2008-2/06/index.html 
// Which might have come from Nvidia:
// https://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf
// And Catlikecoding: https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/

namespace bigi_geom_processor
{
	void bigi_process_vertex(inout v2f input)
	{
		// This thing is labeled v to make some of the macros below work.
		// Mostly for the UNITY_TRANSFER_LIGHTING
		appdata v;
		UNITY_INITIALIZE_OUTPUT(appdata, v);
		v.vertex = input.pos;
		#ifdef BIGI_V2F_NORMAL_VAR_NAME
		v.normal = input.BIGI_V2F_NORMAL_VAR_NAME;
		#endif
		#ifdef BIGI_V2F_TANGENT_VAR_NAME
		v.tangent.xyz = input.BIGI_V2F_TANGENT_VAR_NAME;
		#endif
		#ifdef BIGI_V2F_UV_VAR_NAME
		v.uv0 = input.BIGI_V2F_UV_VAR_NAME;
		#endif
		#ifdef BIGI_V2F_LIGHTMAP_UV_VAR_NAME
		v.uv1 = input.BIGI_V2F_LIGHTMAP_UV_VAR_NAME.xy;
		v.uv2 = input.BIGI_V2F_LIGHTMAP_UV_VAR_NAME.zw;
		#endif
		UNITY_TRANSFER_INSTANCE_ID(input,v);
		
		#if defined(BIGI_VERT_ONLY_OBJECTSPACE)
		input.pos = UnityObjectToClipPos(input.pos.xyz);
		#ifdef BIGI_V2F_NORMAL_VAR_NAME
		input.BIGI_V2F_NORMAL_VAR_NAME = UnityObjectToWorldNormal(input.BIGI_V2F_NORMAL_VAR_NAME);
		#endif
		#ifdef BIGI_V2F_TANGENT_VAR_NAME
		input.BIGI_V2F_TANGENT_VAR_NAME.xyz = UnityObjectToWorldDir(input.BIGI_V2F_TANGENT_VAR_NAME);
		#endif
		
		#elif defined(BIGI_VERT_ONLY_WORLDSPACE)
		input.pos = UnityWorldToClipPos(input.pos);
		// tangent & normal only have to be converted to world and thus are already correct
		#else
		// NOOP
		#endif
		
		#ifdef BIGI_V2F_BITANGENT_VAR_NAME
		input.BIGI_V2F_BITANGENT_VAR_NAME = cross(input.normal, input.tangent) * input.BIGI_V2F_BITANGENT_VAR_NAME.x;
		#endif
		UNITY_TRANSFER_FOG(input, input.pos);
		#ifdef BIGI_V2F_STATIC_TEXTURE_POS_VAR_NAME
		input.BIGI_V2F_STATIC_TEXTURE_POS_VAR_NAME = ComputeScreenPos(input.pos);
		//TODO make this object space relative or something?
		// Update: Orels has a shader that I can checkout: https://shaders.orels.sh/docs/ui/layered-parallax
		#endif
		
		UNITY_TRANSFER_LIGHTING(input, v.uv1)
	}
}

#ifdef ENABLE_DISSOLVE
#include "./Epsilon.cginc"
#include <Packages/lygia/generative/snoise.hlsl>
namespace bigi_geom_processor
{
	float get_power(const in float3 pos, const in float offset)
	{
		float noise = snoise((pos.xyz * 16.0));
		noise -= 1.0;
		noise += (offset * 3.0);
		return max(0.0, noise);
	}
}
#endif


#if !defined(TRANSPARENT_FORWARD_BASE)
[instance(1)]
[maxvertexcount(3)]
#endif
void bigi_geom(triangle v2f input[3],
               //uint pid : SV_PrimitiveID
               inout TriangleStream<v2f> os
               //uint i : SV_GSInstanceID
)
{
	#if defined(BIGI_UDIM_DISCARD_DECLARED) && !defined(BIGI_DISABLE_TILE_DISCARD) && defined(BIGI_V2F_UV_VAR_NAME)
	if (!(b_tile_discard::ShouldDiscard(input[0].BIGI_V2F_UV_VAR_NAME) || b_tile_discard::ShouldDiscard(input[1].BIGI_V2F_UV_VAR_NAME) ||
		b_tile_discard::ShouldDiscard(input[2].BIGI_V2F_UV_VAR_NAME)))
	#endif
	{
		#ifdef ENABLE_DISSOLVE
		#if defined(BIGI_V2F_NORMAL_VAR_NAME)
		const float3 scale = 1.0 / float3(
			length(unity_ObjectToWorld._m00_m10_m20),
			length(unity_ObjectToWorld._m01_m11_m21),
			length(unity_ObjectToWorld._m02_m12_m22)
		);
		
		const float3 totalNormal = input[0].BIGI_V2F_NORMAL_VAR_NAME.xyz + input[1].BIGI_V2F_NORMAL_VAR_NAME.xyz + input[2].BIGI_V2F_NORMAL_VAR_NAME.xyz;
		const float3 normal = ((normalize(totalNormal) / 3.0) * scale);
		
		const float power = bigi_geom_processor::get_power(totalNormal, _DissolveStrength);
		input[0].pos.xyz += normal * power;
		input[1].pos.xyz += normal * power;
		input[2].pos.xyz += normal * power;

		#else
		#error "Missing normal-ish define for dissolve feature!
		#endif
		#else
		const float power = 0.0f;
		#endif
		
		#ifdef BIGI_V2F_DISTANCE_VAR_NAME
		#ifdef BIGI_UNIFORMS_DMXAL
		if (_AL_Mode == b_sound::AudioLinkMode::ALM_WireFrame)
		#endif
		{
			input[0].BIGI_V2F_DISTANCE_VAR_NAME.xyz = float3(1, 0, 0);
			input[1].BIGI_V2F_DISTANCE_VAR_NAME.xyz = float3(0, 1, 0);
			input[2].BIGI_V2F_DISTANCE_VAR_NAME.xyz = float3(0, 0, 1);
		}
		#if defined(BIGI_VERT_ONLY_OBJECTSPACE)
		input[0].BIGI_V2F_DISTANCE_VAR_NAME.w = GET_DISTANCE(input[0].pos);
		input[1].BIGI_V2F_DISTANCE_VAR_NAME.w = GET_DISTANCE(input[1].pos);
		input[2].BIGI_V2F_DISTANCE_VAR_NAME.w = GET_DISTANCE(input[2].pos);
		#endif
		#endif

		
		bigi_geom_processor::bigi_process_vertex(input[0]);
		bigi_geom_processor::bigi_process_vertex(input[1]);
		bigi_geom_processor::bigi_process_vertex(input[2]);
		if (power < 1.0f)
		{
			os.Append(input[0]);
			os.Append(input[1]);
			os.Append(input[2]);
			os.RestartStrip();
		}
	}
}


#endif
