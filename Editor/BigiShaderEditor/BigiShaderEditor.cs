using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using static cc.dingemans.bigibas123.bigishader.BigiProperty;

namespace cc.dingemans.bigibas123.bigishader
{
	public class BigiShaderEditor : ShaderGUI
	{
		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			List<MaterialProperty> materialProperties = properties.ToList();

			var actualTargets = materialEditor.targets
				.Select<object, Material>(m => m as Material)
				.Where(m => m != null);

			EditorGUI.BeginChangeCheck();
			foreach (var m in actualTargets)
			{
				CheckIfMaterialPropertiesExist(m);
				FixupMaterial(m);
			}

			EditorGUI.EndChangeCheck();
			var mats = actualTargets.Select(t => (Material)t);
			if (mats.All(m => !AOEnabled.GetBool(m)))
			{
				materialProperties.RemoveAll(p => p.name == "_" + nameof(AOEnabled));
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
		}

		private void CheckIfMaterialPropertiesExist(Material m)
		{
			foreach (BigiProperty prop in Enum.GetValues(typeof(BigiProperty)))
			{
				if (!prop.Present(m))
				{
					throw new PropertyMissingException(m, prop);
				}
			}

			foreach (MaterialPropertyType propType in Enum.GetValues(typeof(MaterialPropertyType)))
			{
				foreach (var propName in m.GetPropertyNames(propType))
				{
					if (!Enum.TryParse<BigiProperty>(propName.Substring(1), out BigiProperty bigiProp))
					{
						throw new PropertyMissingException(propName, m);
					}
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
				var usingAlpha = GraphicsFormatUtility.HasAlphaChannel(t.graphicsFormat);
				UsesAlpha.Set(m, usingAlpha);
				m.shader.keywordSpace.FindKeyword("DO_ALPHA_PLS").Set(m, usingAlpha);

				if (usingAlpha)
				{
					m.SetShaderPassEnabled("TransparentForwardBase",
						(CompareFunction)ZTestTFWB.GetInt(m) != CompareFunction.Never);
					if (Alpha_Threshold.GetFloat(m) < 0.0f)
					{
						Alpha_Threshold.Set(m, 0.0f);
					}
				}
				else
				{
					m.SetShaderPassEnabled("TransparentForwardBase", false);
					ZTestTFWB.Set(m, (int)CompareFunction.Never);
					ZWriteTFWB.Set(m, false);
					Alpha_Threshold.Set(m, -0.01f);
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

			{
				bool ltcgiIncluded;
				#if LTCGI_INCLUDED
				ltcgiIncluded = true;
				#else
				ltcgiIncluded = false;
				#endif
				// ReSharper disable ConditionIsAlwaysTrueOrFalse
				EnableLTCGI.Set(m, ltcgiIncluded);
				m.shader.keywordSpace.FindKeyword("LTCGI_ENABLED").Set(m, ltcgiIncluded);
				// ReSharper restore ConditionIsAlwaysTrueOrFalse
			}

			if (SpecSmoothMap.TexturePresent(m) && EnableSpecularSmooth.Present(m))
			{
				bool hasSpecMap = (SpecSmoothMap.GetTexture(m) is not null);
				LocalKeyword kw = m.shader.keywordSpace.FindKeyword("SPECSMOOTH_MAP_ENABLED");
				if (EnableSpecularSmooth.GetBool(m) != hasSpecMap)
				{
					EnableSpecularSmooth.Set(m, hasSpecMap);
				}

				if (kw.IsEnabled(m) != hasSpecMap)
				{
					kw.Set(m, hasSpecMap);
				}
			}

			if (AOEnabled.Present(m) && OcclusionMap.Present(m))
			{
				bool hasAOMap = (OcclusionMap.GetTexture(m) is not null);
				AOEnabled.Set(m, hasAOMap);
				m.shader.keywordSpace.FindKeyword("AMBIENT_OCCLUSION_ENABLED").Set(m, hasAOMap);
			}

			var proTVEnabled = EnableProTVSquare.GetBool(m);
			EnableProTVSquare.Set(m, proTVEnabled);
			m.shader.keywordSpace.FindKeyword("PROTV_SQUARE_ENABLED").Set(m, proTVEnabled);
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
			return prop.Present(material) && material.HasTexture(prop.GetPropertyId());
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
		SpecSmoothMap,
		SpecSmoothMap_ST,
		SpecSmoothMap_TexelSize,
		SpecSmoothMap_HDR,
		EnableSpecularSmooth,
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
		VRSLGIStrength,
		EnableLTCGI,
		LTCGIStrength,
		OcclusionMap,
		OcclusionMap_ST,
		OcclusionMap_TexelSize,
		OcclusionMap_HDR,
		AOEnabled,
		OcclusionStrength,
		AL_Theme_Weight,
		AL_TC_BassReactive,
		MonoChrome,
		Voronoi,
		OutlineWidth,
		RoundingDisabled,
		Rounding,
		EnableProTVSquare,
		SquareTVTest,
		TV_Square_Opacity,
		TV_Square_Position,
		MainTexArray,
		MainTexArray_ST,
		MainTexArray_TexelSize,
		MainTexArray_HDR,
		MultiTexture,
		OtherTextureId,
	}
}