using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace cc.dingemans.bigibas123.bigishader
{
	public class BigiShaderEditor : ShaderGUI
	{
		private static readonly int BumpMapID = Shader.PropertyToID("_BumpMap");
		private static readonly int NormalMapEnabledID = Shader.PropertyToID("_UsesNormalMap");
		private static readonly int AlphaEnabledID = Shader.PropertyToID("_UsesAlpha");
		private static readonly int MainTextureID = Shader.PropertyToID("_MainTex");
		private static readonly int MainTextureArrayID = Shader.PropertyToID("_MainTexArray");
		private static readonly int TextureArrayEnabledID = Shader.PropertyToID("_MultiTexture");
		private static readonly int LtcgiEnabledID = Shader.PropertyToID("_EnableLTCGI");

		private static readonly int SpecSmoothMapID = Shader.PropertyToID("_SpecSmoothMap");
		private static readonly int SpecSmoothMapEnabledID = Shader.PropertyToID("_EnableSpecularSmooth");

		private static readonly int AOMapID = Shader.PropertyToID("_OcclusionMap");
		private static readonly int AOMapEnabledID = Shader.PropertyToID("_AOEnabled");

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			// Custom code that controls the appearance of the Inspector goes here
			EditorGUI.BeginChangeCheck();
			foreach (Material m in materialEditor.targets)
			{
				if (m.HasProperty(BumpMapID) && m.HasProperty(NormalMapEnabledID))
				{
					bool hasNormalMap = (m.GetTexture(BumpMapID) is not null);
					m.SetFloat(NormalMapEnabledID, hasNormalMap ? 1 : 0);
					if (hasNormalMap)
					{
						m.SetFloat(NormalMapEnabledID, 1);
						m.EnableKeyword("NORMAL_MAPPING");
					}
					else
					{
						m.SetFloat(NormalMapEnabledID, 0);
						m.DisableKeyword("NORMAL_MAPPING");
					}
				}

				if (m.HasProperty(AlphaEnabledID))
				{
					bool usingArray = m.HasProperty(TextureArrayEnabledID) && m.GetFloat(TextureArrayEnabledID) > 0.1;
					var t = m.GetTexture(usingArray ? MainTextureArrayID : MainTextureID);
					if (t is not null)
					{
						var usingAlpha = GraphicsFormatUtility.HasAlphaChannel(t.graphicsFormat);
						var alphaKw = m.shader.keywordSpace.FindKeyword("DO_ALPHA_PLS");
						if (usingAlpha)
						{
							m.SetFloat(AlphaEnabledID, 1);
							m.EnableKeyword(alphaKw);
							m.SetShaderPassEnabled("TransparentForwardBase", true);
						}
						else
						{
							m.SetFloat(AlphaEnabledID, 0);
							m.DisableKeyword(alphaKw);
							m.SetShaderPassEnabled("TransparentForwardBase", false);
						}
					}
				}

				if (m.HasProperty(LtcgiEnabledID))
				{
					var ltcgiKw = m.shader.keywordSpace.FindKeyword("LTCGI_ENABLED");

#if LTCGI_INCLUDED
					m.SetKeyword(ltcgiKw, true);
					m.EnableKeyword(ltcgiKw);
					m.SetFloat(LtcgiEnabledID, 1);
#else
					m.SetKeyword(ltcgiKw, false);
					m.DisableKeyword(ltcgiKw);
					m.SetFloat(LTCGI_EnabledID, 0);
#endif
				}

				if (m.HasProperty(SpecSmoothMapID) && m.HasProperty(SpecSmoothMapEnabledID))
				{
					bool hasSpecMap = (m.GetTexture(SpecSmoothMapID) is not null);
					m.SetFloat(SpecSmoothMapEnabledID, hasSpecMap ? 1 : 0);
					if (hasSpecMap)
					{
						m.SetFloat(SpecSmoothMapEnabledID, 1);
						m.EnableKeyword("SPECSMOOTH_MAP_ENABLED");
					}
					else
					{
						m.SetFloat(SpecSmoothMapEnabledID, 0);
						m.DisableKeyword("SPECSMOOTH_MAP_ENABLED");
					}
				}

				if (m.HasProperty(AOMapID) && m.HasProperty(AOMapEnabledID))
				{
					bool hasAOMap = (m.GetTexture(AOMapID) is not null);
					m.SetFloat(AOMapEnabledID, hasAOMap ? 1 : 0);
					if (hasAOMap)
					{
						m.SetFloat(AOMapEnabledID, 1);
						m.EnableKeyword("AMBIENT_OCCLUSION_ENABLED");
					}
					else
					{
						m.SetFloat(AOMapEnabledID, 0);
						m.DisableKeyword("AMBIENT_OCCLUSION_ENABLED");
					}
				}
				
			}

			EditorGUI.EndChangeCheck();
			base.OnGUI(materialEditor, properties);
			EditorGUI.indentLevel++;
			EditorGUI.BeginChangeCheck();

			bool emissionEnabled = materialEditor.EmissionEnabledProperty();
			materialEditor.LightmapEmissionProperty(0);
			materialEditor.LightmapEmissionFlagsProperty(0, emissionEnabled, true);
			if (EditorGUI.EndChangeCheck())
			{
				foreach (Material m in materialEditor.targets)
				{
					m.globalIlluminationFlags &=
						~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
					m.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.RealtimeEmissive;
				}
			}

			EditorGUI.indentLevel--;
		}
	}
}