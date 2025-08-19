using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System.Runtime.CompilerServices;
using System;
using System.Diagnostics;
using UnityEngine.UI;
using UnityEngine.Rendering.RendererUtils;

class CP_SeleOutline : CustomPass
{
    [SerializeField] public Material maskMaterial;
    [Tooltip("选择要渲染成 mask 的层")] public LayerMask layerMask = 1; // Layer mask Default enabled

    //RTHandle tempBuffer; 
    RTHandle maskRT;
    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        //// Setup code here
        //var hdrpAsset = (GraphicsSettings.renderPipelineAsset as HDRenderPipelineAsset);
        //var colorBufferFormat = hdrpAsset.currentPlatformRenderPipelineSettings.colorBufferFormat;
        //tempBuffer = RTHandles.Alloc(
        //            Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
        //            colorFormat: (GraphicsFormat)colorBufferFormat,
        //            useDynamicScale: true, name: "tempBuffer"
        //        );
        //targetColorBuffer = TargetBuffer.Camera;
        //targetDepthBuffer = TargetBuffer.None;
        //clearFlags = ClearFlag.None;

        maskRT = RTHandles.Alloc(
            Vector2.one,
            colorFormat: GraphicsFormat.R8G8B8A8_UNorm, // RGBA mask
            dimension: TextureDimension.Tex2D,
            name: "_SelectionMaskRT"
        );
    }


    protected override void Execute(CustomPassContext ctx)
    {

        //#if UNITY_EDITOR
        //        if (debug == 1)
        //        {
        //            ctx.cmd.ClearRenderTarget(false, true, Color.black);
        //            HDUtils.DrawFullScreen(ctx.cmd, SNN_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
        //        }
        //        else if (debug == 2)
        //        {
        //            ctx.cmd.ClearRenderTarget(false, true, Color.black);
        //            HDUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
        //        }
        //#endif
        //#if UNITY_EDITOR
        //        if (debug == 0)
        //        {
        //#endif
        //            ctx.cmd.Blit(ctx.cameraColorBuffer, tempBuffer, SNN_mat, 0);
        //            Sharpen_mat.SetTexture("_MainTex", tempBuffer.rt);
        //            ctx.cmd.Blit(tempBuffer, ctx.cameraColorBuffer, Sharpen_mat,0);
        //            CoreUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer);
        //#if UNITY_EDITOR
        //        }
        //#endif
        //////////////////////////////////////
        if (maskMaterial == null) return;

        // 1) 设定并清空 RT
        CoreUtils.SetRenderTarget(ctx.cmd, maskRT, ClearFlag.Color, Color.clear);

        // 2) 只渲染指定 Layer，并用 override 材质（pass 0）
        CustomPassUtils.DrawRenderers(
            ctx,
            layerMask: layerMask,
            RenderQueueType.All,
            overrideMaterial: maskMaterial,
            0
        );

        // 3) 设为全局纹理
        Shader.SetGlobalTexture("_SelectionMaskRT", maskRT);

    }

    protected override void Cleanup()
    {
        // Cleanup code
        maskRT.Release();
    }
}