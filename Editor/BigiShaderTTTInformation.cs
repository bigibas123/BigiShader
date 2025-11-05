#if BIGI_TEX_TRANS_TOOL_PRESENT
using net.rs64.TexTransTool.TextureAtlas;
using net.rs64.TexTransTool.ShaderSupport;
using UnityEngine;

namespace cc.dingemans.bigibas123.bigishader.Editor
{
    public class BigiShaderTttInformation : ITTShaderTextureUsageInformation, IShaderSupport
    {
        public string ShaderName => "Bigi/Main";
        private static readonly (string PropertyName, string DisplayName)[] PropertyList = {
            (BigiProperty.MainTex.GetPropertyName(), nameof(BigiProperty.MainTex)),
            (BigiProperty.MainTexArray.GetPropertyName(), nameof(BigiProperty.MainTexArray)),
            (BigiProperty.BumpMap.GetPropertyName(), nameof(BigiProperty.BumpMap)),
            (BigiProperty.Bump2ndMap.GetPropertyName(), nameof(BigiProperty.Bump2ndMap)),
            (BigiProperty.SpecSmoothMap.GetPropertyName(), nameof(BigiProperty.SpecSmoothMap)),
            (BigiProperty.SpecGlossMap.GetPropertyName(), nameof(BigiProperty.SpecGlossMap)),
            (BigiProperty.Spacey.GetPropertyName(), nameof(BigiProperty.Spacey)),
            (BigiProperty.Mask.GetPropertyName(), nameof(BigiProperty.Mask)),
            (BigiProperty.OcclusionMap.GetPropertyName(), nameof(BigiProperty.OcclusionMap)),
            (BigiProperty.BumpMap.GetPropertyName(), nameof(BigiProperty.BumpMap)),
        };
        
        static BigiShaderTttInformation()
        {
            var information = new BigiShaderTttInformation();
            var bigiMain = Shader.Find(information.ShaderName);
            if (bigiMain == null)
            {
                Debug.LogError("Could not find Bigi/Main shader!");
                return;
            }
            else
            {
                Debug.Log("Found Bigi/Main shader!");
            }

            TTShaderTextureUsageInformationRegistry.RegisterTTShaderTextureUsageInformation(bigiMain, information);
        }

        public void GetMaterialTextureUVUsage(ITTTextureUVUsageWriter writer)
        {
            foreach (var tuple in PropertyList)
            {
                writer.WriteTextureUVUsage(tuple.PropertyName, UsageUVChannel.UV0);
            }
        }
        
        public (string PropertyName, string DisplayName)[] GetPropertyNames => PropertyList;

        
    }
}

#endif