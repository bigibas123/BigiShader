using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using VRC;
using static cc.dingemans.bigibas123.bigishader.Editor.BigiProperty;

namespace cc.dingemans.bigibas123.bigishader.Editor
{
	public class BigiShaderEditor : ShaderGUI
	{
		private bool m_ShowHiddenProps = false;
		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			List<MaterialProperty> materialProperties = properties.ToList();

			var actualTargets = materialEditor.targets
				.Select<object, Material>(m => m as Material)
				.Where(m => m != null).ToList();

			EditorGUI.BeginChangeCheck();
			foreach (var m in actualTargets)
			{
				CheckIfMaterialPropertiesExist(m);
				EditorGUI.BeginChangeCheck();
				FixupMaterial(m);
				if (EditorGUI.EndChangeCheck())
				{
					// Probably won't do anything but
					// makes a really hard to catch bug of the inspector not showing go away on my machine
					m.MarkDirty();
				}
			}

			EditorGUI.EndChangeCheck();
			var mats = actualTargets.Select(t => (Material)t);
			if (!m_ShowHiddenProps)
			{
				materialProperties.RemoveAll(p =>
				{
					return p.name.Substring(1, p.name.Length - 1) switch
					{
						nameof(UsesAlpha)
							or nameof(UsesNormalMap)
							or nameof(Uses2ndNormalMap)
							or nameof(Decal1Enabled)
							or nameof(Decal2Enabled)
							or nameof(Decal3Enabled)
							or nameof(MultiTexture)
							or nameof(SpecSmoothMap)
							=> true,
						_ => false
					};
				});
			}

			if (mats.All(m => !UsesAlpha.GetBool(m)))
			{
				materialProperties.RemoveAll(p => p.name == "_" + nameof(Alpha_Threshold));
			}

			if (mats.All(m => !Decal1Enabled.GetBool(m)) && !m_ShowHiddenProps)
			{
				materialProperties.RemoveAll(p =>
					p.name == "_" + nameof(Decal1Enabled) || p.name.StartsWith("_" + nameof(Decal1) + "_"));
			}

			if (mats.All(m => !Decal2Enabled.GetBool(m)) && !m_ShowHiddenProps)
			{
				materialProperties.RemoveAll(p =>
					p.name == "_" + nameof(Decal2Enabled) || p.name.StartsWith("_" + nameof(Decal2) + "_"));
				if (mats.All(m => !Decal1Enabled.GetBool(m)))
				{
					materialProperties.RemoveAll(p => p.name == "_" + nameof(Decal2));
				}
			}

			if (mats.All(m => !Decal3Enabled.GetBool(m)) && !m_ShowHiddenProps)
			{
				materialProperties.RemoveAll(p =>
					p.name == "_" + nameof(Decal3Enabled) || p.name.StartsWith("_" + nameof(Decal3) + "_"));
				if (mats.All(m => !Decal2Enabled.GetBool(m)))
				{
					materialProperties.RemoveAll(p => p.name == "_" + nameof(Decal3));
				}
			}

			if (mats.All(m => !(EnableProTVSquare.GetBool(m))) &&
			    !m_ShowHiddenProps)
			{
				materialProperties.RemoveAll(p =>
					p.name == "_" + nameof(SquareTVTest) || p.name.StartsWith("_TV_Square_"));
			}

			base.OnGUI(materialEditor, materialProperties.ToArray());
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
			if (materialEditor.HelpBoxWithButton(m_TextContent,
				    m_ShowHiddenProps ? m_HideButtonContent : m_ShowButtonContent))
			{
				m_ShowHiddenProps = !m_ShowHiddenProps;
			}
		}
		public static GUIContent m_TextContent = new()
		{
			text = "Show/Hide hidden properties",
		};

		public static GUIContent m_ShowButtonContent = new()
		{
			text = "Show",
		};

		public static GUIContent m_HideButtonContent = new()
		{
			text = "Hide",
		};


		private void CheckIfMaterialPropertiesExist(Material m)
		{
			LinkedList<PropertyMissingException> missingProperties = new LinkedList<PropertyMissingException>();
			foreach (BigiProperty prop in Enum.GetValues(typeof(BigiProperty)))
			{
				if (!prop.Present(m))
				{
					missingProperties.AddLast(new PropertyMissingException(m, prop));
				}
			}

			foreach (MaterialPropertyType propType in Enum.GetValues(typeof(MaterialPropertyType)))
			{
				foreach (var propName in m.GetPropertyNames(propType))
				{
					if (!Enum.TryParse<BigiProperty>(propName.Substring(1), out BigiProperty bigiProp))
					{
						missingProperties.AddLast(new PropertyMissingException(propName, m));
					}
				}
			}

			if (missingProperties.Any())
			{
				Debug.LogError("Not all properties implemented!");
				foreach (PropertyMissingException exception in missingProperties)
				{
					Debug.LogError(exception.Message);
				}
			}
		}

		private class PropertyMissingException : Exception
		{
			public PropertyMissingException(Material material, BigiProperty prop) : base(
				$"Property {prop.ToString()} missing on Material {material.name}.")
			{
			}

			public PropertyMissingException(string propName, Material material) : base(
				$"Editor hasn't implemented support for {propName} from Material {material.name}.")
			{
			}
		}

		private static void FixupMaterial(Material m)
		{
			bool hasNormalMap = (BumpMap.GetTexture(m) is not null);
			UsesNormalMap.Set(m, hasNormalMap);
			m.shader.keywordSpace.FindKeyword("NORMAL_MAPPING").Set(m, hasNormalMap);

			bool hasSecondNormalMap = (Bump2ndMap.GetTexture(m) is not null);
			Uses2ndNormalMap.Set(m, hasSecondNormalMap);
			m.shader.keywordSpace.FindKeyword("NORMAL_2ND_MAPPING").Set(m, hasSecondNormalMap);

			var usingArray = MainTexArray.GetTexture(m) is not null;
			MultiTexture.Set(m, usingArray);
			if (usingArray)
			{
				MainTex.Set(m, (Texture)null);
			}

			m.shader.keywordSpace.FindKeyword("MULTI_TEXTURE").Set(m, usingArray);

			var t = usingArray ? MainTexArray.GetTexture(m) : MainTex.GetTexture(m);

			if (t is not null)
			{
				var usingAlpha = GraphicsFormatUtility.HasAlphaChannel(t.graphicsFormat) ||
				                 (
					                 Alpha_Multiplier.GetFloat(m) < 1-float.Epsilon 
				                  || Alpha_Multiplier.GetFloat(m) > 1+float.Epsilon
				                  );
				UsesAlpha.Set(m, usingAlpha);
				m.shader.keywordSpace.FindKeyword("DO_ALPHA_PLS").Set(m, usingAlpha);

				if (usingAlpha)
				{
					m.SetShaderPassEnabled("TransparentForwardBase",
						(CompareFunction)ZTestTFWB.GetInt(m) != CompareFunction.Never);
					if (Alpha_Threshold.GetFloat(m) < 0.0f)
					{
						Alpha_Threshold.Set(m, 0.99f);
					}
				}
				else
				{
					m.SetShaderPassEnabled("TransparentForwardBase", false);
					ZTestTFWB.Set(m, (int)CompareFunction.Never);
					ZWriteTFWB.Set(m, false);
					Alpha_Threshold.Set(m, -0.01f);
					Alpha_Multiplier.Set(m, 1.0f);
				}
			}

			MakeZTestSafe(m, ZTestOFWB);
			MakeZTestSafe(m, ZTestTFWB);
			MakeZTestSafe(m, ZTestFWA);
			MakeZTestSafe(m, ZTestOL);

			m.SetShaderPassEnabled("OpaqueForwardBase",
				(CompareFunction)ZTestOFWB.GetInt(m) != CompareFunction.Never);
			m.SetShaderPassEnabled("TransparentForwardBase",
				(CompareFunction)ZTestTFWB.GetInt(m) != CompareFunction.Never);
			m.SetShaderPassEnabled("ForwardAdd",
				(CompareFunction)ZTestFWA.GetInt(m) != CompareFunction.Never);
			m.SetShaderPassEnabled("Outline",
				(CompareFunction)ZTestOL.GetInt(m) != CompareFunction.Never);

			if (!ZWriteOFWB.GetBool(m))
			{
				ZWriteTFWB.Set(m, false);
			}

			Decal1Enabled.Set(m, Decal1.TexturePresent(m) && Decal1.GetTexture(m) is not null);
			Decal2Enabled.Set(m, Decal2.TexturePresent(m) && Decal2.GetTexture(m) is not null);
			Decal3Enabled.Set(m, Decal3.TexturePresent(m) && Decal3.GetTexture(m) is not null);
			m.shader.keywordSpace.FindKeyword("DECAL_1_ENABLED").Set(m, Decal1Enabled.GetBool(m));
			m.shader.keywordSpace.FindKeyword("DECAL_2_ENABLED").Set(m, Decal2Enabled.GetBool(m));
			m.shader.keywordSpace.FindKeyword("DECAL_3_ENABLED").Set(m, Decal3Enabled.GetBool(m));

			if (SpecSmoothMap.TexturePresent(m) && !SpecGlossMap.TexturePresent(m))
			{
				var tex = SpecSmoothMap.GetTexture(m);
				SpecGlossMap.Set(m,tex);
			}
		}

		private static void MakeZTestSafe(Material material, BigiProperty property)
		{
			try
			{
				if (property.FloatPresent(material))
				{
					switch ((CompareFunction)property.GetInt(material))
					{
						case CompareFunction.Always:
						case CompareFunction.Disabled:
						case CompareFunction.Greater:
						case CompareFunction.GreaterEqual:
						case CompareFunction.NotEqual:
							property.Set(material, (float)CompareFunction.LessEqual);
							break;
						case CompareFunction.Less:
						case CompareFunction.LessEqual:
						case CompareFunction.Never:
						case CompareFunction.Equal:
							break;
						default:
							throw new ArgumentOutOfRangeException();
					}
				}
				else
				{
					property.Set(material, (float)CompareFunction.LessEqual);
				}
			}
			catch (Exception e)
			{
				Debug.LogError(
					$"Error re-setting ZTest property on {material.name}: \"{e.GetType().Name}: {e.Message}\"");
				Debug.LogException(e, material);
			}
		}
	}

	public static class BigiPropertyExtensions
	{
		public static int GetPropertyId(this BigiProperty prop)
		{
			return Shader.PropertyToID($"_{prop.ToString()}");
		}

		public static void Set(this BigiProperty prop, Material material, float value)
		{
			material.SetFloat(prop.GetPropertyId(), value);
		}

		public static float GetFloat(this BigiProperty prop, Material material)
		{
			return material.GetFloat(prop.GetPropertyId());
		}

		public static void Set(this BigiProperty prop, Material material, Texture value)
		{
			material.SetTexture(prop.GetPropertyId(), value);
		}

		public static Texture GetTexture(this BigiProperty prop, Material m)
		{
			return m.GetTexture(prop.GetPropertyId());
		}

		public static void Set(this BigiProperty prop, Material material, bool value)
		{
			int propId = prop.GetPropertyId();
			if (material.HasFloat(propId))
			{
				material.SetFloat(prop.GetPropertyId(), value ? 1 : 0);
			}
			else
			{
				material.SetInt(propId, value ? 1 : 0);
			}
		}

		public static bool GetBool(this BigiProperty prop, Material material)
		{
			int propId = prop.GetPropertyId();
			if (material.HasFloat(propId))
			{
				return material.GetFloat(prop.GetPropertyId()) > 0.01;
			}
			else
			{
				return material.GetInt(propId) > 0;
			}
		}

		public static void Set(this BigiProperty prop, Material material, int value)
		{
			var id = prop.GetPropertyId();
			if (material.HasFloat(id))
			{
				material.SetFloat(id, value);
			}
			else if (material.HasInt(id))
			{
				material.SetInteger(id, value);
			}
			else
			{
				throw new InvalidCastException(
					$"Can't set property {prop} to {value} because it is neither a float nor an int");
			}
		}

		public static int GetInt(this BigiProperty prop, Material material)
		{
			return material.GetInt(prop.GetPropertyId());
		}

		public static bool Present(this BigiProperty prop, Material material)
		{
			return material.HasProperty(prop.GetPropertyId());
		}

		public static bool FloatPresent(this BigiProperty prop, Material material)
		{
			return prop.Present(material) && material.HasFloat(prop.GetPropertyId());
		}

		public static bool IntPresent(this BigiProperty prop, Material material)
		{
			return prop.Present(material) && material.HasInteger(prop.GetPropertyId());
		}

		public static bool TexturePresent(this BigiProperty prop, Material material)
		{
			return prop.Present(material) && material.HasTexture(prop.GetPropertyId()) && (material.GetTexture(prop.GetPropertyId()) is not null);
		}
	}

	public static class LocalKeyWordExtensions
	{
		public static void Set(this LocalKeyword kw, Material m, bool value)
		{
			if (value)
			{
				m.EnableKeyword(kw);
			}
			else
			{
				m.DisableKeyword(kw);
			}
		}

		public static void Enable(this LocalKeyword kw, Material m)
		{
			Set(kw, m, true);
		}

		public static void Disable(this LocalKeyword kw, Material m)
		{
			Set(kw, m, false);
		}

		public static bool IsEnabled(this LocalKeyword kw, Material m)
		{
			return m.IsKeywordEnabled(kw);
		}
	}

	// ReSharper disable InconsistentNaming
	public enum BigiProperty
	{
		//\s_([A-Za-z_]+)
		MainTex,
		MainTex_ST,
		MainTex_TexelSize,
		MainTex_HDR,
		UsesAlpha,
		Cull,
		Alpha_Threshold,
		Alpha_Multiplier,
		ZWriteOFWB,
		ZTestOFWB,
		ZWriteTFWB,
		ZTestTFWB,
		ZTestFWA,
		ZTestOL,
		ZTestSP,
		BumpMap,
		BumpMap_ST,
		BumpMap_TexelSize,
		BumpMap_HDR,
		UsesNormalMap,
		BumpScale,
		
		Bump2ndMap,
		Bump2ndMap_ST,
		Bump2ndMap_TexelSize,
		Bump2ndMap_HDR,
		Uses2ndNormalMap,
		Bump2ndScale,
		
		SpecSmoothMap,
		SpecSmoothMap_ST,
		SpecSmoothMap_TexelSize,
		SpecSmoothMap_HDR,
		SpecGlossMap,
		SpecGlossMap_ST,
		SpecGlossMap_TexelSize,
		SpecGlossMap_HDR,
		Spacey,
		Spacey_ST,
		Spacey_TexelSize,
		Spacey_HDR,
		Mask,
		Mask_ST,
		Mask_TexelSize,
		Mask_HDR,
		EmissionStrength,
		LightSmoothness,
		LightSteps,
		MinAmbient,
		Transmissivity,
		FinalLightMultiply,
		LightVertexMultiplier,
		LightEnvironmentMultiplier,
		LightMainMultiplier,
		LightAddMultiplier,
		LTCGIStrength,
		VRCLVStrength,
		OcclusionMap,
		OcclusionMap_ST,
		OcclusionMap_TexelSize,
		OcclusionMap_HDR,
		OcclusionStrength,
		AL_Mode,
		AL_BlockWireFrame,
		AL_BandMapDistance,
		AL_Theme_Weight,
		AL_TC_BassReactive,
		AL_WireFrameWidth,
		MonoChrome,
		Voronoi,
		OutlineWidth,
		Rounding,
		DoMirrorThing,
		EnableProTVSquare,
		TV_Square_Opacity,
		SquareTVTest,
		TV_Square_Position,
		MainTexArray,
		MainTexArray_ST,
		MainTexArray_TexelSize,
		MainTexArray_HDR,
		MultiTexture,
		OtherTextureId,
		Decal1Enabled,
		Decal1,
		Decal1_BlendMode,
		Decal1_Opacity,
		Decal1_Position,
		Decal1_ST,
		Decal1_TexelSize,
		Decal1_HDR,
		Decal2Enabled,
		Decal2,
		Decal2_BlendMode,
		Decal2_Opacity,
		Decal2_Position,
		Decal2_ST,
		Decal2_TexelSize,
		Decal2_HDR,
		Decal3Enabled,
		Decal3,
		Decal3_BlendMode,
		Decal3_Opacity,
		Decal3_Position,
		Decal3_ST,
		Decal3_TexelSize,
		Decal3_HDR,
		StencilRef,
		StencilWMask,
		StencilRMask
	}
	// ReSharper restore InconsistentNaming
}