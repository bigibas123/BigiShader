#if AVATAR_OPTIMIZER && UNITY_EDITOR

using Anatawa12.AvatarOptimizer.API;
using JetBrains.Annotations;
using UnityEditor;

namespace cc.dingemans.bigibas123.bigishader.Editor
{
    [InitializeOnLoad]
    internal class BigiShaderAAOInformation : ShaderInformation
    {
        static BigiShaderAAOInformation()
        {
            // Register with shader GUID (recommended for shader assets)
            string shaderGuid = "8a99ff97b2650d7429bac9b889aac4e2";
            ShaderInformationRegistry.RegisterShaderInformationWithGUID(
                shaderGuid,
                new BigiShaderAAOInformation()
            );
        }

        public override ShaderInformationKind SupportedInformationKind =>
            ShaderInformationKind.TextureAndUVUsage;

        private void RegisterTextureUsage(MaterialInformationCallback matInfo, string textureName,
            [CanBeNull] string stName = null, UsingUVChannels uv = UsingUVChannels.UV0, Matrix2x3? matrixFallback = null)
        {
            // Get the UV transform (scale/offset)
            var textureST = matInfo.GetVector(stName != null ? stName : textureName + "_ST");
            Matrix2x3? uvMatrix = textureST is { } st
                ? Matrix2x3.NewScaleOffset(st)
                : matrixFallback;

            // Register the texture
            matInfo.RegisterTextureUVUsage(
                textureMaterialPropertyName: textureName,
                samplerState: textureName, // Uses sampler from _MainTex property
                uvChannels: uv,
                uvMatrix: uvMatrix
            );
        }

        private void RegisterDecalIfEnabled(MaterialInformationCallback matInfo, string decalName)
        {
            var decalEnabled = matInfo.GetFloat(decalName + "Enabled");
            if (decalEnabled is > 0)
            {
                var textureSt = matInfo.GetVector(decalName + "_ST");
                Matrix2x3? uvMatrix = textureSt is { } st
                    ? Matrix2x3.NewScaleOffset(st)
                    : null;

                var decalPosition = matInfo.GetVector(decalName + "_Position");
                if (decalPosition is { } decalPos)
                {
                    var translateMatrix = Matrix2x3.Translate(decalPos.x, decalPos.y);
                    var scaleMatrix = Matrix2x3.Scale(decalPos.z, decalPos.w);
                    var decalMatrix = translateMatrix * scaleMatrix;

                    if (uvMatrix is { } uvm)
                    {
                        uvMatrix = uvm * decalMatrix;
                    }
                    else
                    {
                        uvMatrix = decalMatrix;
                    }
                }

                // Register the texture
                matInfo.RegisterTextureUVUsage(
                    textureMaterialPropertyName: decalName,
                    samplerState: decalName, // Uses sampler from _MainTex property
                    uvChannels: UsingUVChannels.UV0,
                    uvMatrix: uvMatrix
                );
            }
        }

        private void RegisterTV(MaterialInformationCallback matInfo)
        {
            var decalEnabled = matInfo.GetFloat("_EnableProTVSquare");
            if (decalEnabled is > 0)
            {
                // The property _TV_Square_Position on my main shader uses UV0 coordinates to position the tv somewhere
                // Since we don't control the texture and I can't really add custom behavior for it in to AAO
                // I have to claim the entire uv channel for use if the checkbox is on
                matInfo.RegisterOtherUVUsage(UsingUVChannels.UV0);
            }
        }

        public override void GetMaterialInformation(MaterialInformationCallback matInfo)
        {
            RegisterTextureUsage(matInfo, "_MainTex");
            RegisterTextureUsage(matInfo, "_Mask");
            RegisterTextureUsage(matInfo, "_Spacey", null, UsingUVChannels.NonMesh, Matrix2x3.Identity);
            if (matInfo.IsShaderKeywordEnabled("NORMAL_MAPPING") != false)
            {
                RegisterTextureUsage(matInfo, "_BumpMap");
            }

            if (matInfo.IsShaderKeywordEnabled("NORMAL_2ND_MAPPING") != false)
            {
                RegisterTextureUsage(matInfo, "_Bump2ndMap");
            }
            
            RegisterDecalIfEnabled(matInfo, "_Decal1");
            RegisterDecalIfEnabled(matInfo, "_Decal2");
            RegisterDecalIfEnabled(matInfo, "_Decal3");
            RegisterTV(matInfo);
        }
    }
}

#endif