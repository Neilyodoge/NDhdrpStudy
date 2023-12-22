using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Experimental.Rendering;

[System.Serializable, VolumeComponentMenu("Post-processing/Kino/Sharpen")]
public sealed class Sharpen : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0, 0, 1);

    Material _material;
    RTHandle temp;

    public bool IsActive() => _material != null && intensity.value > 0;

    public override CustomPostProcessInjectionPoint injectionPoint =>
        CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        _material = CoreUtils.CreateEngineMaterial("Hidden/Kino/PostProcess/Sharpen");

        temp = RTHandles.Alloc(
            Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
            colorFormat: GraphicsFormat.B10G11R11_UFloatPack32, // We don't need alpha in the blur
            useDynamicScale: true, name: "BlurBuffer");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle srcRT, RTHandle destRT)
    {
        if (_material == null) return;

        //RenderTextureDescriptor opaquedesc = renderingData.cameraData.cameraTargetDescriptor;   // 拿到相机数据
        //cmd.GetTemporaryRT(TempID1, opaquedesc); //申请一个临时图像

        _material.SetFloat("_Intensity", intensity.value);
        cmd.CopyTexture(srcRT,temp);
        _material.SetTexture("_InputTexture", temp);
        HDUtils.DrawFullScreen(cmd, _material, destRT);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(_material);
    }
}
