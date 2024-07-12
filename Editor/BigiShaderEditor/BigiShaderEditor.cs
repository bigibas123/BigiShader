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
							m.SetShaderPassEnabled("TransparentForwardBase",true);
						}
						else
						{
							m.SetFloat(AlphaEnabledID, 0);
							m.DisableKeyword(alphaKw);
							m.SetShaderPassEnabled("TransparentForwardBase",false);
						}
					}
				}
				
				var ltcgiKw = m.shader.keywordSpace.FindKeyword("LTCGI_ENABLED");
				
#if LTCGI_INCLUDED
				m.SetKeyword(ltcgiKw, true);
				m.EnableKeyword(ltcgiKw);
				m.SetFloat(LtcgiEnabledID,1);
#else
				m.SetKeyword(ltcgiKw, false);
				m.DisableKeyword(ltcgiKw);
				m.SetFloat(LTCGI_EnabledID,0);
#endif
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