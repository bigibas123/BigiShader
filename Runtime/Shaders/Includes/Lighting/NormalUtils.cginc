#ifndef NORMAL_UTILS_H
#define NORMAL_UTILS_H

#include <UnityCG.cginc>

namespace b_normalutils
{
    float3 mixNormals(float3 n1, float3 n2)
    {
        return normalize(float3(n1.xy + n2.xy, n1.z)); // https://blog.selfshadow.com/publications/blending-in-detail/#udn-blending
    }
    
    float3 recalculate_normals(const in float3 standard_normal, const in float4 normal_map, const in float3 tangent, const in float3 bi_tangent)
    {
        float3x3 TBN = float3x3(normalize(tangent), normalize(bi_tangent), normalize(standard_normal));
        TBN = transpose(TBN);
        float3 world_normal = mul(TBN, UnpackNormal(normal_map));
        return world_normal;
    }
    
    float3 recalculate_normals_double(const in float3 standard_normal, const in float4 normal_map, const in float4 normal_2nd_map, const in float3 tangent, const in float3 bi_tangent)
    {
        float3x3 TBN = float3x3(normalize(tangent), normalize(bi_tangent), normalize(standard_normal));
        TBN = transpose(TBN);
        float3 world_normal_1 = mul(TBN, UnpackNormal(normal_map));
        float3 world_normal_2 = mul(TBN, UnpackNormal(normal_2nd_map));
        return mixNormals(world_normal_1, world_normal_2);
    }
}


#endif