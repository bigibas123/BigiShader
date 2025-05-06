
// Are Light Volumes enabled on scene?
uniform float _UdonLightVolumeEnabled;

// All volumes count in scene
uniform float _UdonLightVolumeCount;

// Additive volumes max overdraw count
uniform float _UdonLightVolumeAdditiveMaxOverdraw;

// Additive volumes count
uniform float _UdonLightVolumeAdditiveCount;

// Should volumes be blended with lightprobes?
uniform float _UdonLightVolumeProbesBlend;

// Should volumes be with sharp edges when not blending with each other
uniform float _UdonLightVolumeSharpBounds;

// Main 3D Texture atlas
uniform sampler3D _UdonLightVolume;

// World to Local (-0.5, 0.5) UVW Matrix
uniform float4x4 _UdonLightVolumeInvWorldMatrix[256];

// L1 SH components rotation (relative to baked rotataion)
uniform float4 _UdonLightVolumeRotation[256];

// If we actually need to rotate L1 components at all
uniform float _UdonLightVolumeIsRotated[256];

// Value that is needed to smoothly blend volumes ( BoundsScale / edgeSmooth )
uniform float3 _UdonLightVolumeInvLocalEdgeSmooth[256];

// AABB Bounds of islands on the 3D Texture atlas
uniform float4 _UdonLightVolumeUvwMin[768];
uniform float4 _UdonLightVolumeUvwMax[768];

// Color multiplier
uniform float4 _UdonLightVolumeColor[256];

// Rotates vector by quaternion
float3 LV_MultiplyVectorByQuaternion(float3 v, float4 q) {
    float3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

// Checks if local UVW point is in bounds from -0.5 to +0.5
bool LV_PointLocalAABB(float3 localUVW){
    return all(abs(localUVW) <= 0.5);
}

// Calculates local UVW using volume ID
float3 LV_LocalFromVolume(int volumeID, float3 worldPos) {
    return mul(_UdonLightVolumeInvWorldMatrix[volumeID], float4(worldPos, 1.0)).xyz;
}

// Calculates Island UVW from local UVW
float3 LV_LocalToIsland(int volumeID, int texID, float3 localUVW){
    // UVW bounds
    int uvwID = volumeID * 3 + texID;
    float3 uvwMin = _UdonLightVolumeUvwMin[uvwID].xyz;
    float3 uvwMax = _UdonLightVolumeUvwMax[uvwID].xyz;
    // Ramapping world bounds to UVW bounds
    return clamp(lerp(uvwMin, uvwMax, localUVW + 0.5), uvwMin, uvwMax);
}

// Samples 3 SH textures and packing them into L1 channels
void LV_SampleLightVolumeTex(float3 uvw0, float3 uvw1, float3 uvw2, out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {
    // Sampling 3D Atlas
    float4 tex0 = tex3Dlod(_UdonLightVolume, float4(uvw0, 0));
    float4 tex1 = tex3Dlod(_UdonLightVolume, float4(uvw1, 0));
    float4 tex2 = tex3Dlod(_UdonLightVolume, float4(uvw2, 0));
    // Packing final data
    L0 = tex0.rgb;
    L1r = float3(tex1.r, tex2.r, tex0.a);
    L1g = float3(tex1.g, tex2.g, tex1.a);
    L1b = float3(tex1.b, tex2.b, tex2.a);
}

// Bounds mask for a volume rotated in world space, using local UVW
float LV_BoundsMask(float3 localUVW, float3 invLocalEdgeSmooth) {
    float3 distToMin = (localUVW + 0.5) * invLocalEdgeSmooth;
    float3 distToMax = (0.5 - localUVW) * invLocalEdgeSmooth;
    float3 fade = saturate(min(distToMin, distToMax));
    return fade.x * fade.y * fade.z;
}

// Default light probes SH components
void LV_SampleLightProbe(out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {
    L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    L1r = unity_SHAr.xyz;
    L1g = unity_SHAg.xyz;
    L1b = unity_SHAb.xyz;
}

// Linear single SH L1 channel evaluation
float LV_EvaluateSH(float L0, float3 L1, float3 n) {
    return L0 + dot(L1, n);
}

// Samples a Volume with ID and Local UVW
void LV_SampleVolume(int id, float3 localUVW, out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {
    
    // Additive UVW
    float3 uvw0 = LV_LocalToIsland(id, 0, localUVW);
    float3 uvw1 = LV_LocalToIsland(id, 1, localUVW);
    float3 uvw2 = LV_LocalToIsland(id, 2, localUVW);
                
    // Sample additive
    LV_SampleLightVolumeTex(uvw0, uvw1, uvw2, L0, L1r, L1g, L1b);
    
    // Color correction
    L0 = L0 * _UdonLightVolumeColor[id].rgb;
    L1r = L1r * _UdonLightVolumeColor[id].r;
    L1g = L1g * _UdonLightVolumeColor[id].g;
    L1b = L1b * _UdonLightVolumeColor[id].b;
    
    // Rotate if needed
    if (_UdonLightVolumeIsRotated[id] != 0) {
        L1r = LV_MultiplyVectorByQuaternion(L1r, _UdonLightVolumeRotation[id]);
        L1g = LV_MultiplyVectorByQuaternion(L1g, _UdonLightVolumeRotation[id]);
        L1b = LV_MultiplyVectorByQuaternion(L1b, _UdonLightVolumeRotation[id]);
    }
                
}

// Calculate Light Volume Color based on all SH components provided and the world normal
float3 LightVolumeEvaluate(float3 worldNormal, float3 L0, float3 L1r, float3 L1g, float3 L1b) {
    return float3(LV_EvaluateSH(L0.r, L1r, worldNormal), LV_EvaluateSH(L0.g, L1g, worldNormal), LV_EvaluateSH(L0.b, L1b, worldNormal));
}

// Calculates SH components based on the world position
void LightVolumeSH(float3 worldPos, out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {

    // Initializing output variables
    L0  = float3(0, 0, 0);
    L1r = float3(0, 0, 0);
    L1g = float3(0, 0, 0);
    L1b = float3(0, 0, 0);
    
    // Fallback to default light probes if Light Volume are not enabled
    if (!_UdonLightVolumeEnabled || _UdonLightVolumeCount == 0) {
        LV_SampleLightProbe(L0, L1r, L1g, L1b);
        return;
    }
    
    int volumeID_A = -1; // Main, dominant volume ID
    int volumeID_B = -1; // Secondary volume ID to blend main with

    float3 localUVW   = float3(0, 0, 0); // Last local UVW to use in disabled Light Probes mode
    float3 localUVW_A = float3(0, 0, 0); // Main local UVW for Y Axis and Free rotations
    float3 localUVW_B = float3(0, 0, 0); // Secondary local UVW
    
    // Are A and B volumes NOT found?
    bool isNoA = true;
    bool isNoB = true;
    
    // Additive volumes variables
    int addVolumesCount = 0;
    float3 L0_, L1r_, L1g_, L1b_;
    
    int id = 0; // Loop iterator
    
    // Iterating through all light volumes with simplified algorithm requiring Light Volumes to be sorted by weight in descending order
    [loop]
    for (; id < _UdonLightVolumeAdditiveCount && addVolumesCount < _UdonLightVolumeAdditiveMaxOverdraw; id++) {
        localUVW = LV_LocalFromVolume(id, worldPos);
        if (LV_PointLocalAABB(localUVW)) { // Intersection test
            LV_SampleVolume(id, localUVW, L0_, L1r_, L1g_, L1b_);
            L0 += L0_;
            L1r += L1r_;
            L1g += L1g_;
            L1b += L1b_;
            addVolumesCount++;
        }
    }
    
    [loop] // First, searching for volume A
    for (id = _UdonLightVolumeAdditiveCount; id < _UdonLightVolumeCount; id++) {
        localUVW = LV_LocalFromVolume(id, worldPos);
        if (LV_PointLocalAABB(localUVW)) { // Intersection test
            volumeID_A = id;
            localUVW_A = localUVW;
            isNoA = false;
            break;
        }
    }
    
    [loop] // Next, searching for volume B if A found
    for (id++; id < _UdonLightVolumeCount; id++) {
        localUVW = LV_LocalFromVolume(id, worldPos);
        if (LV_PointLocalAABB(localUVW)) { // Intersection test
            volumeID_B = id;
            localUVW_B = localUVW;
            isNoB = false;
            break;
        }
    }
    
    // Volume A SH components and mask to blend volume sides
    float3 L0_A  = float3(1, 1, 1);
    float3 L1r_A = float3(0, 0, 0);
    float3 L1g_A = float3(0, 0, 0);
    float3 L1b_A = float3(0, 0, 0);

    // If no volumes found, using Light Probes as fallback
    if (isNoA && _UdonLightVolumeProbesBlend) {
        LV_SampleLightProbe(L0_, L1r_, L1g_, L1b_);
        L0  += L0_;
        L1r += L1r_;
        L1g += L1g_;
        L1b += L1b_;
        return;
    }
        
    // Fallback to lowest weight light volume if oudside of every volume
    localUVW_A = isNoA ? localUVW : localUVW_A;
    volumeID_A = isNoA ? _UdonLightVolumeCount - 1 : volumeID_A;

    // Sampling Light Volume A
    LV_SampleVolume(volumeID_A, localUVW_A, L0_A, L1r_A, L1g_A, L1b_A);
    
    float mask = LV_BoundsMask(localUVW_A, _UdonLightVolumeInvLocalEdgeSmooth[volumeID_A]);
    if (mask == 1 || isNoA || (_UdonLightVolumeSharpBounds && isNoB)) { // Returning SH A result if it's the center of mask or out of bounds
        L0  += L0_A;
        L1r += L1r_A;
        L1g += L1g_A;
        L1b += L1b_A;
        return;
    }
    
    // Volume B SH components
    float3 L0_B  = float3(1, 1, 1);
    float3 L1r_B = float3(0, 0, 0);
    float3 L1g_B = float3(0, 0, 0);
    float3 L1b_B = float3(0, 0, 0);

    if (isNoB && _UdonLightVolumeProbesBlend) { // No Volume found and light volumes blending enabled

        // Sample Light Probes B
        LV_SampleLightProbe(L0_B, L1r_B, L1g_B, L1b_B);

    } else { // Blending Volume A and Volume B
            
        // If no volume b found, use last one found to fallback
        localUVW_B = isNoB ? localUVW : localUVW_B;
        volumeID_B = isNoB ? _UdonLightVolumeCount - 1 : volumeID_B;
            
        // Sampling Light Volume B
        LV_SampleVolume(volumeID_B, localUVW_B, L0_B, L1r_B, L1g_B, L1b_B);
        
    }
        
    // Lerping SH components
    L0  += lerp(L0_B,  L0_A,  mask);
    L1r += lerp(L1r_B, L1r_A, mask);
    L1g += lerp(L1g_B, L1g_A, mask);
    L1b += lerp(L1b_B, L1b_A, mask);

}

void LightVolumeAdditiveSH(float3 worldPos, out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {

    // Initializing output variables
    L0  = float3(0, 0, 0);
    L1r = float3(0, 0, 0);
    L1g = float3(0, 0, 0);
    L1b = float3(0, 0, 0);
    
    if (!_UdonLightVolumeEnabled || _UdonLightVolumeAdditiveCount == 0) return;
    
    // Additive volumes variables
    float3 localUVW = float3(0, 0, 0);
    int addVolumesCount = 0;
    float3 L0_, L1r_, L1g_, L1b_;
    
    // Iterating through all light volumes with simplified algorithm requiring Light Volumes to be sorted by weight in descending order
    [loop]
    for (int id = 0; id < _UdonLightVolumeAdditiveCount && addVolumesCount < _UdonLightVolumeAdditiveMaxOverdraw; id++) {
        localUVW = LV_LocalFromVolume(id, worldPos);
        //Intersection test
        if (LV_PointLocalAABB(localUVW)) {
            LV_SampleVolume(id, localUVW, L0_, L1r_, L1g_, L1b_);
            L0 += L0_;
            L1r += L1r_;
            L1g += L1g_;
            L1b += L1b_;
            addVolumesCount++;
        }
    }

}