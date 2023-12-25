using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/PP_SNN")]
public sealed class PP_SNN : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    //[Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter _LerpBase = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter _HalfWidth = new ClampedFloatParameter(5f, 0f, 10f);
    public ClampedFloatParameter _Intensity = new ClampedFloatParameter(1f, 0f, 1f);

    Material snn_Material;
    Material sharp_Material;

    RenderTargetIdentifier temp;

    public bool IsActive() => snn_Material != null;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > Graphics > HDRP Global Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.BeforePostProcess;

    const string snnShaderName = "Hidden/Shader/PP_SNN";
    const string sharpShaderName = "Hidden/Shader/PP_Sharpen";

    public override void Setup()
    {
        if (Shader.Find(snnShaderName) != null)
            snn_Material = new Material(Shader.Find(snnShaderName));
        else if(Shader.Find(sharpShaderName) != null)
            sharp_Material = new Material(Shader.Find(snnShaderName));
        else
            Debug.LogError($"Unable to find shader '{snnShaderName}' or '{sharpShaderName}'. Post Process Volume PP_SNN is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (snn_Material == null && sharp_Material == null)
            return;

        snn_Material.SetFloat("_LerpBase", _LerpBase.value);
        snn_Material.SetFloat("_HalfWidth", _HalfWidth.value);
        snn_Material.SetTexture("_MainTex", source);
        HDUtils.DrawFullScreen(cmd, snn_Material, destination, shaderPassId: 0);
        //sharp_Material.SetTexture("_MainTex", destination);
        //sharp_Material.SetFloat("_Intensity", _Intensity.value);
        //HDUtils.DrawFullScreen(cmd, sharp_Material, destination, shaderPassId: 0);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(snn_Material);
        CoreUtils.Destroy(sharp_Material);
    }
}
