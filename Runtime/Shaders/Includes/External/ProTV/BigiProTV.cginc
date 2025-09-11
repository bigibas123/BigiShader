#ifndef BIGI_PROTV_H
#define BIGI_PROTV_H

#include <UnityCG.cginc>

#if !defined(SHADER_API_D3D11)
uniform sampler2D _Udon_VideoTex;
float4 _Udon_VideoTex_TexelSize;
float4 _Udon_VideoTex_ST;
namespace b_protv_util
{
    bool IsProtvPresent()
    {
        return (_Udon_VideoTex_TexelSize.z > 16);
    }
}
#else
UNITY_DECLARE_TEX2D(_Udon_VideoTex);
float4 _Udon_VideoTex_ST;
namespace b_protv_util
{
	bool IsProtvPresent()
	{
		int videoWidth;
		int videoHeight;
		_Udon_VideoTex.GetDimensions(videoWidth, videoHeight);
		return (videoWidth > 16);
	}
	
}
#endif


namespace b_protv_util
{
	float4 GetProTV(const in float2 uv )
	{
		#if defined(BIGI_VERTEX_STAGE) || defined(BIGI_FRAGMENT_STAGE)
		return UNITY_SAMPLE_TEX2D(_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex));
		#elif defined(BIGI_GEOMETRY_STAGE)
		return UNITY_SAMPLE_TEX2D_LOD(_Udon_VideoTex, TRANSFORM_TEX(uv, _Udon_VideoTex),0.0);
		#else
		#error "Not supported shader stage"
		return float4(0,0,0,1);
		#endif
	}
}


#include "../../Core/BigiTextureCreation.cginc"
#include "../../Core/BigiShaderParams.cginc"

#define GET_PROTV(uv) (b_protv_util::GetProTV(uv))
#define PROTV_PRESENT() (b_protv_util::IsProtvPresent())

namespace b_protv_util
{
	float4 getTexColor(float2 uv)
	{
		return GET_PROTV(uv);
	}
}
#endif
