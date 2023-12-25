using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Experimental.Rendering;
using static Unity.VisualScripting.Member;

[System.Serializable, VolumeComponentMenu("Post-processing/Kino/ColorGrade1")]
public sealed class ColorGrade : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    //public ClampedFloatParameter intensity = new ClampedFloatParameter(0, 0, 1);

    Material mat_ColorGrade1;
    Material mat_ColorGrade2;
    RTHandle temp1;
    RTHandle temp2;
    //public ColorParameter col;

    public bool IsActive() => mat_ColorGrade1 != null && mat_ColorGrade2 != null;

    public override CustomPostProcessInjectionPoint injectionPoint =>
        CustomPostProcessInjectionPoint.BeforeTAA;

    public override void Setup()
    {
        mat_ColorGrade1 = CoreUtils.CreateEngineMaterial("Hidden/Kino/PostProcess/ColorGrade1");
        mat_ColorGrade2 = CoreUtils.CreateEngineMaterial("Hidden/Kino/PostProcess/ColorGrade2");

        temp1 = RTHandles.Alloc(
            Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
            colorFormat: GraphicsFormat.B10G11R11_UFloatPack32, // We don't need alpha in the blur
            useDynamicScale: true, name: "BlurBuffer1");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle srcRT, RTHandle destRT)
    {
        if (mat_ColorGrade1 == null) return;

        int rtw = srcRT.rt.width;
        int rth = srcRT.rt.height;

        //RenderTexture buffer0 = RenderTexture.GetTemporary(rtw, rth, 0);   // 申请临时RT
        mat_ColorGrade1.SetTexture("_InputTexture", srcRT);
        cmd.Blit(srcRT, temp1, mat_ColorGrade1, 0);
        //cmd.Blit(buffer0, temp1);
        //HDUtils.BlitCameraTexture(cmd, temp, srcRT);
        mat_ColorGrade2.SetTexture("_InputTexture2", temp1);
        cmd.Blit(temp1, destRT, mat_ColorGrade2, 0);
        CoreUtils.DrawFullScreen(cmd, mat_ColorGrade2, destRT);
        //HDUtils.DrawFullScreen(cmd, mat_ColorGrade2, destRT);
        //RenderTexture.ReleaseTemporary(buffer0);


        ////mat_ColorGrade1.SetFloat("_Intensity", intensity.value);
        //cmd.CopyTexture(srcRT,temp);
        //mat_ColorGrade1.SetTexture("_InputTexture", temp);
        //cmd.Blit(srcRT, temp, mat_ColorGrade1);
        ////HDUtils.DrawFullScreen(cmd, mat_ColorGrade1, destRT);
        //mat_ColorGrade2.SetTexture("_InputTexture2", temp);
        //HDUtils.DrawFullScreen(cmd, mat_ColorGrade2, destRT);

    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(mat_ColorGrade1);
        CoreUtils.Destroy(mat_ColorGrade2);
        temp1.Release();
    }
}
