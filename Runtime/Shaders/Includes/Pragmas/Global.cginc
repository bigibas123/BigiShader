﻿#ifndef BIGI_GLOBAL_PRAGMA
#define BIGI_GLOBAL_PRAGMA
#pragma target 5.0


#pragma skip_optimizations d3d11
//#pragma warning(disable : 3568)
//#pragma enable_d3d11_debug_symbols

//#pragma instancing_options assumeuniformscaling
#pragma multi_compile_instancing
#pragma multi_compile_fog


#pragma shader_feature_local_fragment MULTI_TEXTURE
#pragma shader_feature_local_fragment LTCGI_ENABLED
#pragma shader_feature_local DO_ALPHA_PLS
#pragma shader_feature_local_fragment SPECSMOOTH_MAP_ENABLED
#pragma shader_feature_local_fragment AMBIENT_OCCLUSION_ENABLED
#pragma shader_feature_local_fragment PROTV_SQUARE_ENABLED
#pragma shader_feature_local ROUNDING_DISABLED

#pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
#pragma skip_variants DECALS_OFF DECALS_3RT DECALS_4RT DECAL_SURFACE_GRADIENT _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
#pragma skip_variants _ADDITIONAL_LIGHT_SHADOWS
#pragma skip_variants PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma skip_variants _SCREEN_SPACE_OCCLUSION

#endif