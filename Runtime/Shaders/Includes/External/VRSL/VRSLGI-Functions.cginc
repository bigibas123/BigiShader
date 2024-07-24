//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* MIT License

Copyright (c) 2023 z3y

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. */

#ifndef CBIRP_INCLUDED
#define CBIRP_INCLUDED

#ifdef CLUSTER_TEXTURE
    Texture2D _LightTexture;
#else
Texture2D<float4> _Udon_VRSL_GI_LightTexture;
Texture2D<uint4> _Udon_VRSL_GI_ClusterTexture;
Texture2D<float4> _Udon_VRSL_GI_GoboTexture;
float4 _Udon_VRSL_GI_GoboTexture_TexelSize;
#endif

uniform float4 _Udon_VRSL_GI_ClusterInitialization;
uniform uint _Udon_CBIRP_DummyZero;
uniform int _Udon_VRSL_GI_LightCount;


#ifdef UNITY_PBS_USE_BRDF2
    #define VRSLGI_LOW
#endif


//Constants
#define VRSLGI_VOLUME_POS _Udon_VRSL_GI_ClusterInitialization.xyz
#define VRSLGI_CULL_FAR _Udon_VRSL_GI_ClusterInitialization.w

#define VRSLGI_CULLING_SIZE uint(1024)
#define VRSLGI_VOXELS_COUNT VRSLGI_CULLING_SIZE
#define VRSLGI_VOXELS_SIZE VRSLGI_CULL_FAR / float(VRSLGI_CULLING_SIZE / 2.0)

#define VRSLGI_UNIFORMS_SIZE uint2(128, 4)
#define VRSLGI_UNIFORMS_PROBE_START 4

#define VRSLGI_MAX_LIGHTS (uint) _Udon_VRSL_GI_LightCount
//


#define VRSLGI_CLUSTER_START_LIGHT(cluster) \
    uint4 flags4x = _Udon_VRSL_GI_ClusterTexture[uint2(0, cluster.x)]; \
    uint4 flags4y = _Udon_VRSL_GI_ClusterTexture[uint2(1, cluster.y)]; \
    uint4 flags4z = _Udon_VRSL_GI_ClusterTexture[uint2(2, cluster.z)]; \
    uint4 flags4 = flags4x & flags4y & flags4z; \
    uint flags = flags4.x; \
    uint offset = 0; \
    [loop] while (offset != 128) { \
        [branch] if (flags == 0) { \
            offset += 32; \
            flags = offset == 32 ? flags4.y : (offset == 64 ? flags4.z : flags4.w); \
        } else { \
            uint index = firstbitlow(flags); \
            flags ^= 0x1 << index; \
            index += offset;
#define VRSLGI_CLUSTER_END_LIGHT \
    }}

namespace VRSLGI_CBIRP
{
	void UnpackFloatAndUint(float input, out float a, out uint b)
	{
		uint uintInput = asuint(input);
		a = f16tof32(uintInput >> 16);
		b = uintInput & 0xff;
	}

	void UnpackFloat(float input, out float a, out float b)
	{
		uint uintInput = asuint(input);
		a = f16tof32(uintInput >> 16);
		b = f16tof32(uintInput);
	}

	void UnpackFloat(float4 input, out float4 a, out float4 b)
	{
		uint4 uintInput = asuint(input);
		a = f16tof32(uintInput >> 16);
		b = f16tof32(uintInput);
	}

	void UnpackEightBit(in float c, inout float a, inout float b, inout uint bINT)
	{
		uint x = (uint)(c);
		uint aINT = ((x & 0x0000FF00) >> 8);
		bINT = (x & 0x000000FF);

		a = ((float)aINT) / 255.0;
		b = ((float)bINT) / 255.0;
		// b = frac(c); // removes the integer value, leaving B (0-1)
		// a = (c - b) / 255; // removes the fractional value (B) and scales back to 0-1
	}

	float LuminanceRangeReduction(float range, float3 color)
	{
		return lerp(range * 0.5, range, saturate((color.r + color.b + color.g) / 3));
	}

	float3 Heatmap(float v)
	{
		float3 r = v * 2.1 - float3(1.8, 1.14, 0.3);
		return 1.0 - r * r;
	}

	struct Light
	{
		half3 color;
		float3 positionWS;
		half3 direction;
		float range;
		half spotBlend;
		half outerSpotAngle;
		half innerSpotAngle;
		uint shadowMaskTarget;
		uint shadowMaskChannel;
		half3 rawColor;
		half spotThreshold;
		uint coneWidthGoboFlags;
		uint innerSpotAngleRaw;

		static Light DecodeLight(uint index)
		{
			Light l = (Light)0;
			#ifdef CLUSTER_TEXTURE
                float4 colorDirectionData = _LightTexture.Load(int3(index, 0, 0));
                float4 positionData = _LightTexture.Load(int3(index, 1, 0));
			#else
			float4 colorDirectionData = _Udon_VRSL_GI_LightTexture[uint2(index, 0)];
			float4 positionData = _Udon_VRSL_GI_LightTexture[uint2(index, 1)];
			#endif

			float4 colorData = float4(0, 0, 0, 0);
			float4 directionData = float4(0, 0, 0, 0);
			UnpackFloat(colorDirectionData, colorData, directionData);


			l.rawColor = colorData.xyz;
			l.color = l.rawColor * 0.01;
			l.positionWS = positionData.xyz;
			l.range = colorData.w * 150;
			float SpotBlend = 0.0;
			uint ShadowMaskPackedData = 0;
			UnpackFloatAndUint(positionData.w, SpotBlend, ShadowMaskPackedData);
			//float smpd = ShadowMaskPackedData * 0.1;
			uint smpd = (uint)ShadowMaskPackedData;
			l.spotBlend = SpotBlend;
			// l.shadowMaskTarget = (uint)trunc(smpd);
			// l.shadowMaskChannel = (uint)(frac(smpd) * 10);
			l.shadowMaskTarget = smpd >> 6;
			l.shadowMaskChannel = (smpd >> 4) & 3;
			l.coneWidthGoboFlags = smpd & 0x0F;
			l.spotThreshold = 0.05;


			l.direction = directionData.xyz;
			float osa = 0.0;
			float isa = 0.0;
			uint isa_raw = 0;
			if (l.coneWidthGoboFlags > 0)
			{
				l.outerSpotAngle = directionData.w;
				l.innerSpotAngle = isa;
			}
			else
			{
				UnpackEightBit(directionData.w, osa, isa, isa_raw);
				l.outerSpotAngle = osa * 180.0;
				l.innerSpotAngle = isa * 180.0;
			}
			l.innerSpotAngleRaw = isa_raw;

			return l;
		}
	};

	// Normalize that account for vectors with zero length
	float3 SafeNormalize(float3 inVec)
	{
		const float flt_min = 1.175494351e-38;
		float dp3 = max(flt_min, dot(inVec, inVec));
		return inVec * rsqrt(dp3);
	}

	uint3 GetCluster(float3 positionWS)
	{
		uint3 cluster = uint3(((positionWS - VRSLGI_VOLUME_POS) + VRSLGI_CULL_FAR) / float(VRSLGI_VOXELS_SIZE));
		return cluster;
	}
}

#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* MIT License

Copyright (c) 2024 AcChosen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. */


#ifndef CLUSTER_TEXTURE

SamplerState VRSL_BilinearClampSampler, VRSLGI_PointClampSampler, VRSL_BilinearRepeatSampler;


#ifndef VRSL_GI_PROJECTOR
sampler2D _VRSLMetallicGlossMap;
half _VRSLMetallicMapStrength;
half _VRSLGlossMapStrength;
half _VRSLSmoothnessChannel;
half _VRSLMetallicChannel;
half _VRSLInvertMetallicMap;
half _VRSLInvertSmoothnessMap;

Texture2D _VRSLShadowMask1;
Texture2D _VRSLShadowMask2;
Texture2D _VRSLShadowMask3;

float4 _VRSLShadowMask1_ST;
float4 _VRSLShadowMask2_ST;
float4 _VRSLShadowMask3_ST;

int _UseVRSLShadowMask1;
int _UseVRSLShadowMask2;
int _UseVRSLShadowMask3;

#else
    int         _VRSLGIVertexFalloff;
    float       _VRSLGIVertexAttenuation;
    float4      _VRSLProjectorColor;
    float       _VRSLProjectorGlobalStrength;
#endif

half _VRSLGISpecularClamp;
half _VRSLGIDiffuseClamp;

half _VRSLSpecularShine;
half _VRSLGlossiness;
half _VRSLSpecularStrength;
half _VRSLGIStrength;
half _VRSLDiffuseMix;
half _VRSLSpecularMultiplier;

half _UseVRSLShadowMask1RStrength;
half _UseVRSLShadowMask1GStrength;
half _UseVRSLShadowMask1BStrength;
half _UseVRSLShadowMask1AStrength;

half _UseVRSLShadowMask2RStrength;
half _UseVRSLShadowMask2GStrength;
half _UseVRSLShadowMask2BStrength;
half _UseVRSLShadowMask2AStrength;

half _UseVRSLShadowMask3RStrength;
half _UseVRSLShadowMask3GStrength;
half _UseVRSLShadowMask3BStrength;
half _UseVRSLShadowMask3AStrength;
half _RenderTextureMultiplier;

int _VRSLShadowMaskUVSet;
int _ClusterDebugFalloff;


half _VRSLProjectorStrength;
half _EnviormentLightingCompensation;
int _EnviormentLightingCompensationToggle;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////


float3 ChooseGobo(uint selection, float2 uv)
{
	half2 addition = half2(0.0, 0.0);
	uv *= half2(0.25, 0.5);

	switch (selection)
	{
	default:
		return float3(1, 1, 1);
	case 1:
		addition = half2(0.0, 0.5);
		break;
	case 2:
		addition = half2(0.25, 0.5);
		break;
	case 3:
		addition = half2(0.5, 0.5);
		break;
	case 4:
		addition = half2(0.75, 0.5);
		break;
	case 5:
		addition = half2(0.0, 0.0);
		break;
	case 6:
		addition = half2(0.25, 0.0);
		break;
	case 7:
		addition = half2(0.5, 0.0);
		break;
	case 8:
		addition = half2(0.75, 0.0);
		break;
	}

	uv.x += addition.x;
	uv.y += addition.y;

	return _Udon_VRSL_GI_GoboTexture.Sample(VRSL_BilinearRepeatSampler, uv).rgb;
}

float4x4 InitTranslationTransform(float x, float y, float z)
{
	return float4x4(1.0, 0.0, 0.0, x,
					0.0, 1.0, 0.0, y,
					0.0, 0.0, 1.0, z,
					0.0, 0.0, 0.0, 1.0);
}

// float4x4 InitRotationTransform(float3 target, float3 up)
// {
//     float3 N = (target);
//     float3 UpNorm = (up);
//     float3 U = (cross(UpNorm, N));
//     float3 V = (cross(N, U));

//     // float3 U = (cross(N, UpNorm));
//     // float3 V = cross(N, U);

//     // float3 forward = target;
//     // float3 right = cross(up, target);
//     // float3 upVec = cross(forward, right);


//     return float4x4(U.x, U.y, U.z, 0.0,
//                     V.x, V.y, V.z, 0.0,
//                     N.x, N.y, N.z, 0.0,
//                     0.0, 0.0, 0.0, 1.0);

//     // return float4x4(right.x, upVec.x, forward.x, 0.0,
//     //                 right.y, upVec.y, forward.y, 0.0,
//     //                 right.z, upVec.z, forward.z, 0.0,
//     //                 0.0, 0.0, 0.0, 1.0);

// }

float4x4 InitRotationTransform(float3 direction, float3 up)
{
	direction = (direction);
	up = (up);
	float3 xaxis = cross(up, direction);
	xaxis = (xaxis);

	float3 yaxis = cross(direction, xaxis);
	yaxis = (yaxis);

	return float4x4(xaxis.x, xaxis.y, xaxis.z, 0.0,
					yaxis.x, yaxis.y, yaxis.z, 0.0,
					direction.x, direction.y, direction.z, 0.0,
					0.0, 0.0, 0.0, 1.0);

	// column1.x = xaxis.x;
	// column1.y = yaxis.x;
	// column1.z = direction.x;

	// column2.x = xaxis.y;
	// column2.y = yaxis.y;
	// column2.z = direction.y;

	// column3.x = xaxis.z;
	// column3.y = yaxis.z;
	// column3.z = direction.z;
}

// float4x4 InitRotationTransform(float3 direction, float3 up)
// {
//     float x = radians(direction.x);
//     float y = radians(direction.y);
//     float z = radians(direction.z);

//     float4x4 xMat = float4x4(1.0, 0.0, 0.0, 0.0,
//                             0.0, cos(x), sin(x), 0.0,
//                             0.0, -sin(x), cos(x), 0.0,
//                             0.0, 0.0, 0.0, 1.0);

//     float4x4 yMat = float4x4(cos(y), 0.0, -sin(y), 0.0,
//                             0.0,     1.0,   0.0,    0.0,
//                             sin(y),  0.0,   cos(y), 0.0,
//                             0.0, 0.0, 0.0, 1.0);

//     float4x4 zMat = float4x4(cos(z),-sin(z), 0.0, 0.0,
//                             sin(z),cos(z), 0.0,0.0,
//                             0.0,  0.0,  1.0 , 0.0,
//                             0.0, 0.0, 0.0, 1.0);


//     return transpose(mul(mul(xMat, yMat), zMat));
// }


float4x4 InitLightTransform(float3 pos, float3 target, float3 up, out float4x4 lightRotationMatrix,
							out float4x4 lightTranslationMatrix)
{
	lightTranslationMatrix = InitTranslationTransform(pos.x, pos.y, pos.z);
	lightRotationMatrix = InitRotationTransform(target, up);
	return mul(lightTranslationMatrix, lightRotationMatrix);
}

float4x4 InitPersProjMatrix(float FOV, float zNear, float zFar, float textureWidth, float textureHeight)
{
	// float ar = textureHeight / textureWidth;
	// float zRange = zNear - zFar;
	// float tanHalfFOV = tan(radians(FOV / 2.0));
	// return float4x4(1/tanHalfFOV, 0.0, 0.0, 0.0,
	//                                 0.0, 1/(tanHalfFOV*ar), 0.0, 0.0,
	//                                 0.0, 0.0, (-zNear - zFar)/zRange,2.0 * zFar * zNear / zRange,
	//                                 0.0, 0.0, 1.0, 0.0);
	float aspectRatio = textureWidth / textureHeight;
	float h = 1 / tan(FOV * 0.5);
	float w = h / aspectRatio;
	float a = zFar / (zFar - zNear);
	float b = (-zNear * zFar) / (zFar - zNear);
	return float4x4(w, 0, 0, 0,
					0, h, 0, 0,
					0, 0, a, 1,
					0, 0, b, 0);
}

float4x4 inverse(float4x4 m)
{
	float n11 = m[0][0], n12 = m[1][0], n13 = m[2][0], n14 = m[3][0];
	float n21 = m[0][1], n22 = m[1][1], n23 = m[2][1], n24 = m[3][1];
	float n31 = m[0][2], n32 = m[1][2], n33 = m[2][2], n34 = m[3][2];
	float n41 = m[0][3], n42 = m[1][3], n43 = m[2][3], n44 = m[3][3];

	float t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 *
		n44;
	float t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 *
		n44;
	float t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 *
		n44;
	float t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 *
		n34;

	float det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
	float idet = 1.0f / det;

	float4x4 ret;

	ret[0][0] = t11 * idet;
	ret[0][1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 *
		n44) * idet;
	ret[0][2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 *
		n44) * idet;
	ret[0][3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 *
		n43) * idet;

	ret[1][0] = t12 * idet;
	ret[1][1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 *
		n44) * idet;
	ret[1][2] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 *
		n44) * idet;
	ret[1][3] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 *
		n43) * idet;

	ret[2][0] = t13 * idet;
	ret[2][1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 *
		n44) * idet;
	ret[2][2] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 *
		n44) * idet;
	ret[2][3] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 *
		n43) * idet;

	ret[3][0] = t14 * idet;
	ret[3][1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 *
		n34) * idet;
	ret[3][2] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 *
		n34) * idet;
	ret[3][3] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 *
		n33) * idet;

	return ret;
}

float4x4 axis_matrix(float3 right, float3 up, float3 forward)
{
	float3 xaxis = right;
	float3 yaxis = up;
	float3 zaxis = forward;
	return float4x4(
		xaxis.x, yaxis.x, zaxis.x, 0,
		xaxis.y, yaxis.y, zaxis.y, 0,
		xaxis.z, yaxis.z, zaxis.z, 0,
		0, 0, 0, 1
	);
}

// http://stackoverflow.com/questions/349050/calculating-a-lookat-matrix
float4x4 look_at_matrix(float3 forward, float3 up)
{
	float3 xaxis = (cross(forward, up));
	float3 yaxis = up;
	float3 zaxis = forward;
	return axis_matrix(xaxis, yaxis, zaxis);
}


#if _VRSL_GI_SPECULARHIGHLIGHTS
        //GGX Specular function found here http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
        float GGXSpec(float3 N, float3 V, float3 L, float roughness)
        {
            float alpha = roughness*roughness;

            float3 H = normalize(V+L);

            float dotNL = saturate(dot(N,L));
            //float dotNV = saturate(dot(N,V));
            float dotNH = saturate(dot(N,H));
            float dotLH = saturate(dot(L,H));

            float D, vis;

            // D
            float alphaSqr = alpha*alpha;
            float pi = 3.14159f;
            float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
            D = alphaSqr/(pi * denom * denom);


            // V
            float k = alpha/2.0f;
            float k2 = k*k;
            float invK2 = 1.0f-k2;
            vis = rcp(dotLH*dotLH*invK2 + k2);

            float specular = dotNL * D * vis;
            return specular;
        }

        float BeckmanSpec(float3 N, float3 V, float3 L, float roughness)
        {
            float3 H = normalize(V+L);
            float NdotH = saturate(dot(N,H));
            float roughnessSqr = roughness*roughness * (roughness * 0.5);
            float NdotHSqr = NdotH*NdotH;
            return max(0.000001,(1.0 / (3.1415926535*roughnessSqr*NdotHSqr*NdotHSqr))
            * exp((NdotHSqr-1)/(roughnessSqr*NdotHSqr)));
        }

        float PhongSpec(float3 N, float3 V, float3 L, float roughness)
        {
            //float r = lerp(roughness * 0.01, roughness * 2, roughness);
            float speculargloss = (1/(roughness * roughness)) * 20;
            float specularpower = lerp(15, 2, roughness);
            float3 H = normalize(V+L);
            float NdotH = saturate(dot(N,H));
            float Distribution = pow(NdotH,speculargloss) * specularpower;
            Distribution *= (2+specularpower) / (2*3.1415926535);
            return Distribution;
        }
        

#endif
#if !defined(VRSL_GI_PROJECTOR)
half4 VRSLShadowMask1(float2 uv)
{
	uv = uv.xy * _VRSLShadowMask1_ST.xy + _VRSLShadowMask1_ST.zw;
	return _VRSLShadowMask1.SampleLevel(VRSL_BilinearRepeatSampler, uv, 0);
}

half4 VRSLShadowMask2(float2 uv)
{
	uv = uv.xy * _VRSLShadowMask2_ST.xy + _VRSLShadowMask2_ST.zw;
	return _VRSLShadowMask2.SampleLevel(VRSL_BilinearRepeatSampler, uv, 0);
}

half4 VRSLShadowMask3(float2 uv)
{
	uv = uv.xy * _VRSLShadowMask3_ST.xy + _VRSLShadowMask3_ST.zw;
	return _VRSLShadowMask3.SampleLevel(VRSL_BilinearRepeatSampler, uv, 0);
}
#endif

float AngleBetweenVecotrs(float3 v1, float3 v2)
{
	return dot(v1, v2) / (length(v1) * length(v2));
}

void SetShadowMaskChannel(int maskChannel, out float s1, out float s1Strength, float4 mask, float4 strength)
{
	s1 = 1.0;
	s1Strength = 0.0;
	#if _VRSL_SHADOWMASK_RG
                [branch]
                switch(maskChannel)
                {
                    case 0:
                        s1 = mask.r;
                        s1Strength = strength.r;
                        break;
                    case 1:
                        s1 = mask.g;
                        s1Strength = strength.g;
                        break;
                    default:
                        break;
                }
	#elif _VRSL_SHADOWMASK_RGB
                [branch]
                switch(maskChannel)
                {
                    case 0:
                        s1 = mask.r;
                        s1Strength = strength.r;
                        break;
                    case 1:
                        s1 = mask.g;
                        s1Strength = strength.g;
                        break;
                    case 2:
                        s1 = mask.b;
                        s1Strength = strength.b;
                        break;
                    default:
                        break;
                }
	#elif _VRSL_SHADOWMASK_RGBA
                s1 = mask[maskChannel];
                s1Strength = strength[maskChannel];
	#else
	if (maskChannel == 0)
	{
		s1 = mask.r;
		s1Strength = strength.r;
	}
	#endif
}

float CalculateShadowMask(float4 mask1Strength,
						float4 mask2Strength,
						float4 mask3Strength,
						int maskChannel,
						int maskSelection,
						float4 shadowMask1,
						float4 shadowMask2,
						float4 shadowMask3)
{
	float s1 = 1.0f;
	float s1Strength = 0.0f;

	[branch]
	switch (maskSelection)
	{
	default:
		break;
		#if defined(_VRSL_SHADOWMASK1)
                case 1:
                    SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask1,mask1Strength);
                    break;
		#endif
		#if defined(_VRSL_SHADOWMASK2)
                case 2:
                    SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask2,mask2Strength);
                    break;
		#endif
		#if defined(_VRSL_SHADOWMASK3)
                case 3:
                    SetShadowMaskChannel(maskChannel,s1,s1Strength,shadowMask3,mask3Strength);
                    break;  
		#endif
	}

	return lerp(1, s1, s1Strength);
}

float GetSquareFalloffAttenuationCustom(float distanceSquare, float lightInvRadius2)
{
	float factor = distanceSquare * lightInvRadius2;
	float smoothFactor = saturate(1.0 - factor);
	return (smoothFactor * smoothFactor) / (distanceSquare + 1.0);
}

float3 VRSLGI_SIMPLE(float3 worldPos)
{
	float3 finalOut = 0.0;
	///////////////////////////////////////////////////////////////////////////////
	half debug = 0;
	uint3 cluster = VRSLGI_CBIRP::GetCluster(worldPos);
	half3 light = 0;
	VRSLGI_CLUSTER_START_LIGHT(cluster)
		debug += 1;
		VRSLGI_CBIRP::Light light = VRSLGI_CBIRP::Light::DecodeLight(index);

		float3 lightColor = light.color.rgb * (0.5 * light.range);
		float3 lightPos = light.positionWS;
		float SpotBlend = light.spotBlend;
		float range = light.range;
		int maskSelection = light.shadowMaskTarget;
		int maskChannel = light.shadowMaskChannel;

		float3 lightDirection = lightPos - worldPos;
		float distanceSquare = dot(lightDirection, lightDirection);
		//range*= 0.5;

		range = VRSLGI_CBIRP::LuminanceRangeReduction(light.range, light.color);
		UNITY_BRANCH
		if (distanceSquare < range && SpotBlend <= 0.0)
		{
			float shadowmask = 1.0;
			float specular = 1.0;
			range = 1.0 / range;

			float falloff = GetSquareFalloffAttenuationCustom(distanceSquare, range);

			//lightDirection = normalize(lightDirection);
			finalOut += falloff * lightColor;
		}
	VRSLGI_CLUSTER_END_LIGHT
	#ifdef _VRSLGI_CBIRP_DEBUG
                finalOut = debug / 32.;
	#endif
	return finalOut;
}


float4 euler_to_quaternion(float roll, float pitch, float yaw) // roll (x), pitch (y), yaw (z), angles are in radians
{
	// Abbreviations for the various angular functions

	float cr = cos(roll * 0.5);
	float sr = sin(roll * 0.5);
	float cp = cos(pitch * 0.5);
	float sp = sin(pitch * 0.5);
	float cy = cos(yaw * 0.5);
	float sy = sin(yaw * 0.5);

	float4 q = float4(0, 0, 0, 0);
	q.w = cr * cp * cy + sr * sp * sy;
	q.x = sr * cp * cy - cr * sp * sy;
	q.y = cr * sp * cy + sr * cp * sy;
	q.z = cr * cp * sy - sr * sp * cy;

	return q;
}

float4x4 quaternion_to_matrix(float4 quat)
{
	float4x4 m = float4x4(float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0));

	float x = quat.x, y = quat.y, z = quat.z, w = quat.w;
	float x2 = x + x, y2 = y + y, z2 = z + z;
	float xx = x * x2, xy = x * y2, xz = x * z2;
	float yy = y * y2, yz = y * z2, zz = z * z2;
	float wx = w * x2, wy = w * y2, wz = w * z2;

	m[0][0] = 1.0 - (yy + zz);
	m[0][1] = xy - wz;
	m[0][2] = xz + wy;

	m[1][0] = xy + wz;
	m[1][1] = 1.0 - (xx + zz);
	m[1][2] = yz - wx;

	m[2][0] = xz - wy;
	m[2][1] = yz + wx;
	m[2][2] = 1.0 - (xx + yy);

	m[3][3] = 1.0;

	return m;
}

float vrslgi_contrast(float colors, float contrast)
{
	return ((colors - 0.5) * max(contrast + 1.0, 0.0)) + 0.5;
}

float3 VRSLGI(float3 worldPos, float3 worldNormal, float roughness, float3 eyeVec, float3 diffuseColor, float2 mg,
			float2 uv, float occlusion)
{
	float3 finalOut = 0.0;
	float3 viewDirection = normalize(eyeVec.xyz);
	float4 shadowmask1 = float4(1, 1, 1, 1);
	float4 shadowmask2 = float4(1, 1, 1, 1);
	float4 shadowmask3 = float4(1, 1, 1, 1);

	diffuseColor = clamp(diffuseColor, float3(0.005, 0.005, 0.005), float3(1, 1, 1));
	#ifndef VRSL_GI_PROJECTOR
	#ifdef _VRSL_SHADOWMASK1
                    shadowmask1 = VRSLShadowMask1(uv);
	#endif
	#ifdef _VRSL_SHADOWMASK2
                    shadowmask2 = VRSLShadowMask2(uv);
	#endif
	#ifdef _VRSL_SHADOWMASK3
                    shadowmask3 = VRSLShadowMask3(uv);
	#endif
	#endif
	#ifndef VRLSGI_USE_BUILTIN_SPECULAR
	#if _VRSL_GI_SPECULARHIGHLIGHTS
                    float metallic = _VRSLSpecularStrength;
	#ifndef VRSL_GI_PROJECTOR
                        roughness = lerp(roughness,mg.y,_VRSLGlossMapStrength);
                        metallic =  lerp(metallic,mg.x,_VRSLMetallicMapStrength);

	#ifndef VRSL_GI_PROJECTOR
                            metallic = abs(_VRSLInvertMetallicMap - metallic);
                            roughness = abs(_VRSLInvertSmoothnessMap - roughness);
	#endif
	#endif
                    roughness = max(roughness, 0.002);
	#endif
	#else
                float metallic = mg.x;
                roughness = mg.y;
	#endif
	///////////////////////////////////////////////////////////////////////////////
	half debug = 0;
	uint3 cluster = VRSLGI_CBIRP::GetCluster(worldPos);
	half3 light = 0;
	VRSLGI_CLUSTER_START_LIGHT(cluster)
		debug += 1;
		VRSLGI_CBIRP::Light light = VRSLGI_CBIRP::Light::DecodeLight(index);

		float3 lightColor = light.color.rgb * (0.5 * light.range);
		float3 lightPos = light.positionWS;
		float SpotBlend = light.spotBlend;
		float range = light.range;
		int maskSelection = light.shadowMaskTarget;
		int maskChannel = light.shadowMaskChannel;

		float3 lightDirection = lightPos - worldPos;
		float distanceSquare = dot(lightDirection, lightDirection);
		//range*= 0.5;

		range = VRSLGI_CBIRP::LuminanceRangeReduction(light.range, light.color);
		UNITY_BRANCH
		if (distanceSquare < range)
		{
			float shadowmask = 1.0;
			float specular = 1.0;
			range = 1.0 / range;

			float falloff = GetSquareFalloffAttenuationCustom(distanceSquare, range);

			lightDirection = normalize(lightDirection);
			#if _VRSL_DIFFUSETOON
                            float atten = saturate(dot(lightDirection, worldNormal) );
                            atten = lerp(0.0025, 1.0, atten);
                            atten = smoothstep(0,0.01,atten);
			#elif _VRSL_DIFFUSETINT
                            float atten = 1.0f;
			#else
			float atten = saturate(dot(lightDirection, worldNormal));
			#endif

			atten = clamp(atten, _VRSLGIDiffuseClamp, 1.0);
			//End Diffuse Stuff

			//Begin Specular Stuff
			#if _VRSL_GI_SPECULARHIGHLIGHTS
			#ifdef _VRSL_SPECFUNC_GGX
                                specular = GGXSpec(worldNormal, viewDirection, lightDirection, roughness);
			#elif _VRSL_SPECFUNC_BECKMAN
                                specular = BeckmanSpec(worldNormal, viewDirection, lightDirection, roughness);
			#elif _VRSL_SPECFUNC_PHONG
                                specular = PhongSpec(worldNormal, viewDirection, lightDirection, roughness);
			#endif
                            specular = lerp(1.0, specular, clamp(metallic,0.01, 1.0));
                            specular = specular * specular;
            
                            specular *= (1/(light.range*0.005));
                            //specular *= abs(_VRSLSpecularMultiplier);
                            specular = vrslgi_contrast(specular, _VRSLSpecularMultiplier);
                        //specular *= (1/(range*0.5));
                            //specular *= CalcLuminance(rawLightColor.rgb);
			#endif
			//End SPecular Stuff

			//Begin ShadowMask Stuff
			#ifndef VRSL_GI_PROJECTOR
			#if defined(_VRSL_SHADOWMASK1) || defined(_VRSL_SHADOWMASK2) || defined(_VRSL_SHADOWMASK3)



                                shadowmask = saturate(CalculateShadowMask(float4(_UseVRSLShadowMask1RStrength,
                                _UseVRSLShadowMask1GStrength,_UseVRSLShadowMask1BStrength, _UseVRSLShadowMask1AStrength),
                                float4(_UseVRSLShadowMask2RStrength, _UseVRSLShadowMask2GStrength, _UseVRSLShadowMask2BStrength, _UseVRSLShadowMask2AStrength),
                                float4(_UseVRSLShadowMask3RStrength, _UseVRSLShadowMask3GStrength, _UseVRSLShadowMask3BStrength, _UseVRSLShadowMask3AStrength)
                                , maskChannel, maskSelection,
                                shadowmask1, shadowmask2, shadowmask3));
			#endif

			#endif
			//End Shadowmask Stuff

			//Combine
			lightColor = lerp(float3(0, 0, 0), lightColor * abs(_VRSLGIStrength), shadowmask);
			diffuseColor = lerp(float3(1, 1, 1), diffuseColor, _VRSLDiffuseMix);

			//#if _VRSL_GI_ANGLES

			if (SpotBlend > light.spotThreshold)
			{
				float outerSpotAngle = (cos(radians(light.outerSpotAngle)));
				float innerSpotAngle = (cos(radians(light.coneWidthGoboFlags > 0
														? light.outerSpotAngle - 5
														: light.innerSpotAngle)));
				float3 spotlightDir = light.direction.xyz;

				float theta = dot(lightDirection, normalize(-spotlightDir));
				float epsilon = abs(innerSpotAngle - outerSpotAngle);
				float spotlight = clamp((theta - outerSpotAngle) / epsilon, 0.0, 1.0);


				// float4x4 rotMatrix = quaternion_to_matrix(euler_to_quaternion(spotlightDir.x, spotlightDir.y, spotlightDir.z));


				// // float4x4 lightMatrix0 = inverse(float4x4(rotMatrix._m00,rotMatrix._m01,rotMatrix._m02,lightPos.x,
				// //                                 rotMatrix._m10,rotMatrix._m11,rotMatrix._m12,lightPos.y,
				// //                                 rotMatrix._m20,rotMatrix._m21,rotMatrix._m22,lightPos.z,
				// //                                 0,0,0,1));

				// float4x4 lightMatrix0 = float4x4(1,0,0,lightPos.x,
				//                                 0,1,0,lightPos.y,
				//                                 0,0,1,lightPos.z,
				//                                 0,0,0,1);
				// lightMatrix0 = mul(lightMatrix0, rotMatrix);


				// float4 positionInLightSpace =  mul(lightMatrix0, float4(worldPos,1));

				// float3 cookie = ChooseGobo(2,float2(0.1, 0.5) *((positionInLightSpace.xy / positionInLightSpace.w) +float2(5.0,-0.25)));

				// spotlight *= cookie;

				atten = lerp(atten, atten * spotlight, SpotBlend);
				specular = lerp(specular, specular * spotlight, SpotBlend);
			}
			debug += ((atten > 0) && (_ClusterDebugFalloff > 0));
			finalOut += falloff * lightColor * atten * diffuseColor * clamp(specular, 0.0, _VRSLGISpecularClamp);
		}
	VRSLGI_CLUSTER_END_LIGHT

	#ifdef _VRSLGI_CBIRP_DEBUG
                // diffuse = Heatmap((debug) / 16.);
                finalOut = debug / 32.;
	#endif


	return finalOut * occlusion;
}


#ifdef MOCHIE_BRDF
        float _VRSLGIIgnoreDirectionalLights;
        float3 VRSLGI_BRDF(float3 worldPos, float3 normal, float smoothness, 
            half oneMinusReflectivity, float3 viewDir, float3 diffuseColor, half3 specColor, 
            float2 uv, float occlusion, float ignoreSpotlights)
        {
            float3 finalOut = 0.0;
            float3 diffColor = clamp(diffuseColor, float3(0.005,0.005,0.005), float3(1,1,1));

            float4 shadowmask1 = float4(1,1,1,1);
            float4 shadowmask2 = float4(1,1,1,1);
            float4 shadowmask3 = float4(1,1,1,1);
#ifndef VRSL_GI_PROJECTOR
#ifdef _VRSL_SHADOWMASK1
                    shadowmask1 = VRSLShadowMask1(uv);
#endif
#ifdef _VRSL_SHADOWMASK2
                    shadowmask2 = VRSLShadowMask2(uv);
#endif
#ifdef _VRSL_SHADOWMASK3
                    shadowmask3 = VRSLShadowMask3(uv);
#endif
#endif
            ///////////////////////////////////////////////////////////////////////////////
                half debug = 0;
                uint3 cluster = VRSLGI_CBIRP::GetCluster(worldPos);
                half3 light = 0;


                half perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
                if (_GSAA == 1){
                    perceptualRoughness = GSAARoughness(normal, perceptualRoughness);
                }

                half roughness = PerceptualRoughnessToRoughness(perceptualRoughness) * _VRSLGIRoughnessMult;
                roughness = _VRSLGIRouhgnessInvert > 0 ? 1-roughness : roughness;

                VRSLGI_CLUSTER_START_LIGHT(cluster)
                    debug+=1;
                    VRSLGI_CBIRP::Light light = VRSLGI_CBIRP::Light::DecodeLight(index);
                    
                    float3 lightColor = (light.color.rgb * (0.5 * light.range)) * 0.25;
                    float3 lightPos = light.positionWS;
                    float SpotBlend = light.spotBlend;
                    float range = light.range;
                    int maskSelection = light.shadowMaskTarget;
                    int maskChannel =  light.shadowMaskChannel;
                    
                    float3 lightDirection = lightPos - worldPos;
                    float distanceSquare = dot(lightDirection, lightDirection);
                    //range*= 0.5;
                    
                    range = VRSLGI_CBIRP::LuminanceRangeReduction(light.range, light.color);
                    UNITY_BRANCH
                    if (distanceSquare < range)
                    {   
                        float shadowmask = 1.0;   
                        float specular = 1.0; 
                        range = 1.0 / range;
                        float falloff = GetSquareFalloffAttenuationCustom(distanceSquare, range);
                        lightDirection = normalize(lightDirection);




                        half3 halfDir = Unity_SafeNormalize (half3(lightDirection) + viewDir);
                        half nv = abs(dot(normal, viewDir));
                        half nl = saturate(dot(normal, lightDirection));
                        half nh = saturate(dot(normal, halfDir));
                        half lv = saturate(dot(lightDirection, viewDir));
                        half lh = saturate(dot(lightDirection, halfDir));

                        // Diffuse term
                        half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
                        float wrappedDiffuse = saturate((diffuseTerm + _WrappingFactor) /
                        (1.0f + _WrappingFactor)) * 2 / (2 * (1 + _WrappingFactor));


                        // Specular term

#if UNITY_BRDF_GGX
                            roughness = max(roughness, 0.002);
                            half V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
                            half D = GGXTerm(nh, roughness);
#else
                            half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
                            half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif
                            half specularTerm = 0.0;
#if defined(_SPECULARHIGHLIGHTS_OFF) || !defined(_VRSL_GI_SPECULARHIGHLIGHTS)
                            specularTerm = 0.0;
#else
                            specularTerm = V*D * UNITY_PI;
#ifdef UNITY_COLORSPACE_GAMMA
                                specularTerm = sqrt(max(1e-4h, specularTerm));
#endif
                            specularTerm = max(0, specularTerm * nl);
#endif
                        half surfaceReduction;
#ifdef UNITY_COLORSPACE_GAMMA
                            surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;
#else
                            surfaceReduction = 1.0 / (roughness*roughness + 1.0);
#endif


//End SPecular Stuff

//Begin ShadowMask Stuff
#ifndef VRSL_GI_PROJECTOR
#if defined(_VRSL_SHADOWMASK1) || defined(_VRSL_SHADOWMASK2) || defined(_VRSL_SHADOWMASK3)
                                shadowmask = saturate(CalculateShadowMask(float4(_UseVRSLShadowMask1RStrength,
                                _UseVRSLShadowMask1GStrength,_UseVRSLShadowMask1BStrength, _UseVRSLShadowMask1AStrength),
                                float4(_UseVRSLShadowMask2RStrength, _UseVRSLShadowMask2GStrength, _UseVRSLShadowMask2BStrength, _UseVRSLShadowMask2AStrength),
                                float4(_UseVRSLShadowMask3RStrength, _UseVRSLShadowMask3GStrength, _UseVRSLShadowMask3BStrength, _UseVRSLShadowMask3AStrength)
                                , maskChannel, maskSelection,
                                shadowmask1, shadowmask2, shadowmask3));
#endif
#endif
                        //End Shadowmask Stuff

                        //Combine

                        //lightColor = lerp(float3(0,0,0), lightColor * abs(_VRSLGIStrength), shadowmask);
                        diffColor = lerp(float3(1,1,1), diffColor, _VRSLDiffuseMix);

                        //diffuseTerm *= _VRSLGIStrength;
                        diffuseTerm = clamp(diffuseTerm, _VRSLGIDiffuseClamp, 1.0) * _VRSLGIStrength;
                        specularTerm *= _VRSLSpecularMultiplier;

                        half3 diffCol = diffColor * (0 + lightColor * diffuseTerm);
                        half3 specCol = specularTerm * lightColor * FresnelTerm (specColor, lh) * _SpecularStrength * 10;

                        float3 finalLightColor = diffCol + specCol;

                    

                    
                        
                        //#if _VRSL_GI_ANGLES
                            
                        if(SpotBlend > light.spotThreshold)
                        {
                                float outerSpotAngle = (cos(radians(light.outerSpotAngle)));
                                float innerSpotAngle = (cos(radians(light.coneWidthGoboFlags > 0 ? light.outerSpotAngle - 5 : light.innerSpotAngle)));
                                float3 spotlightDir = light.direction.xyz;

                                float theta     = dot(lightDirection, normalize(-spotlightDir));
                                float epsilon   = abs(innerSpotAngle - outerSpotAngle);
                                float spotlight = clamp((theta - outerSpotAngle) / epsilon, 0.0, 1.0); 

                               // spotlight *= CalculateGOBO(worldPos, spotlightDir, lightPos).g;

                                finalLightColor = lerp(finalLightColor, finalLightColor*spotlight, SpotBlend);
                                finalLightColor *= lerp(1,0,ignoreSpotlights);
                                //finalLightColor *= CalculateGOBO(outerSpotAngle, worldPos, lightPos, spotlightDir, range);
                        }
                        debug += ((diffuseTerm > 0) && (_ClusterDebugFalloff > 0));
                        finalOut += (falloff * finalLightColor * shadowmask);
                    }
                VRSLGI_CLUSTER_END_LIGHT
                
#ifdef _VRSLGI_CBIRP_DEBUG
                // diffuse = Heatmap((debug) / 16.);
                finalOut = debug / 32.;
#endif


            return finalOut * occlusion;
        }
#endif


#endif
