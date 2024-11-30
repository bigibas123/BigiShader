#ifndef BIGI_FORWARD_BASE_PRAGMA
#define BIGI_FORWARD_BASE_PRAGMA

#include_with_pragmas "./VRCLighting.cginc"

#pragma multi_compile_fwdbase
#pragma multi_compile_vertex _ VERTEXLIGHT_ON
#define FORWARD_BASE_PASS


#endif