#ifndef NORMAL_UTILS_H
#define NORMAL_UTILS_H

#include <UnityCG.cginc>
#include <UnityShaderVariables.cginc>

#include "../Epsilon.cginc"

namespace b_normalutils
{
    float2 calculateMatCapUv(const in float3 worldSpaceNormalIn, const in float3 worldSpacePos)
    {
        float2 matcapUV = float2(0.5,0.5);
        if (GET_MATCAP_COLOR().a > Epsilon)
        {
            float3 worldSpaceNormal = normalize(worldSpaceNormalIn);
            float3 worldSpaceViewDir = normalize(worldSpacePos - _WorldSpaceCameraPos.xyz);

            float3 up = mul((float3x3)UNITY_MATRIX_I_V, float3(0, 1, 0));
            float3 right = normalize(cross(up, worldSpaceViewDir));
            up = cross(worldSpaceViewDir, right);
            matcapUV = mul(float3x3(right, up, worldSpaceViewDir), worldSpaceNormal).xy;
            matcapUV = matcapUV * 0.5 + 0.5;
        }
        return matcapUV;
    }

    float3 mixNormals(float3 n1, float3 n2)
    {
        return normalize((n1 + n2) / 2.0); 
        // If I ever want to do this properly https://blog.selfshadow.com/publications/blending-in-detail/#udn-blending
    }

    float3 recalculate_normals(const in float3 standard_normal, const in float4 normal_map, const in float3 tangent,
                               const in float3 bi_tangent, const in float normalStrength)
    {
        float3x3 TBN = float3x3(normalize(tangent), normalize(bi_tangent), normalize(standard_normal));
        TBN = transpose(TBN);
        float3 world_normal = mul(TBN, UnpackNormal(normal_map));

        return normalize(lerp(standard_normal, world_normal, normalStrength));
    }

    float3 recalculate_normals_double(const in float3 standard_normal, const in float4 normal_map,
                                      const in float4 normal_2nd_map, const in float3 tangent,
                                      const in float3 bi_tangent, const in float normalStrength1,
                                      const in float normalStrength2)
    {
        float3x3 TBN = float3x3(normalize(tangent), normalize(bi_tangent), normalize(standard_normal));
        TBN = transpose(TBN);
        float3 world_normal_1 = normalize(lerp(standard_normal, mul(TBN, UnpackNormal(normal_map)), normalStrength1));
        float3 world_normal_2 = normalize(lerp(standard_normal, mul(TBN, UnpackNormal(normal_2nd_map)), normalStrength2));

        return mixNormals(world_normal_1,world_normal_2);
    }
}


#endif
