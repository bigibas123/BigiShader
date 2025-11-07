#ifndef BIGI_GEOMPROCESSOR_INCL
#define BIGI_GEOMPROCESSOR_INCL

#include "./Core/BigiShaderStructs.cginc"
#include "./Core/BigiShaderParams.cginc"
#include "./TileDiscardStuff.cginc"
// Wireframe effect
// Based on work from Garrett Johnson (gkjohnson) https://github.com/gkjohnson/unity-wireframe-shader/tree/master
// Which is based on the paper "Shader-Based Wireframe Drawing" authored by J. A. Bærentzen,S. L. Nielsen, M. Gjøl & B. D. Larsen: https://cgg-journal.com/2008-2/06/index.html archived here: https://web.archive.org/web/20130322011415/http://cgg-journal.com/2008-2/06/index.html 
// Which might have come from Nvidia:
// https://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf
// And Catlikecoding: https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/


#ifndef TRANSPARENT_FORWARD_BASE
[instance(1)]
[maxvertexcount(3)]
#endif
void bigi_geom(triangle v2f input[3],
               //uint pid : SV_PrimitiveID
               inout TriangleStream<v2f> os
               //uint i : SV_GSInstanceID
)
{
	#ifdef BIGI_UNIFORMS_DMXAL
    if (_AL_Mode == b_sound::AudioLinkMode::ALM_WireFrame)
    {

        input[0].distance.xyz = float3(1, 0, 0);
        input[1].distance.xyz = float3(0, 1, 0);
        input[2].distance.xyz = float3(0, 0, 1);
    }
	#endif
	
	#if defined(BIGI_UDIM_DISCARD_DECLARED) && !defined(BIGI_DISABLE_TILE_DISCARD)
	if (!(b_tile_discard::ShouldDiscard(input[0].uv) || b_tile_discard::ShouldDiscard(input[1].uv) || b_tile_discard::ShouldDiscard(input[2].uv)))
	#endif
	{
		os.Append(input[0]);
		os.Append(input[1]);
		os.Append(input[2]);
	}
}


#endif
