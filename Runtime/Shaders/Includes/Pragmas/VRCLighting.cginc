#ifndef BIGI_VRCLIGHTING_PRAGMA
#define BIGI_VRCLIGHTING_PRAGMA
#pragma target 5.0
//#pragma skip_optimizations d3d11
//#pragma enable_d3d11_debug_symbols
//#pragma use_dxc

#pragma warning (error : 3571) // pow(f,e) will not work for negative f
#pragma warning (error : 3206) // implicit truncation of vector type
#pragma warning (error : 3205) // conversion of larger type to smaller

#include_with_pragmas "./StageDefines.cginc"

#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_instancing
#include <UnityInstancing.cginc>
#pragma multi_compile_fog

#pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
#pragma skip_variants DECALS_OFF DECALS_3RT DECALS_4RT DECAL_SURFACE_GRADIENT _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
#pragma skip_variants _ADDITIONAL_LIGHT_SHADOWS
#pragma skip_variants PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma skip_variants _SCREEN_SPACE_OCCLUSION
#pragma skip_variants _REFLECTION_PROBE_BLENDING _REFLECTION_PROBE_BOX_PROJECTION

#endif