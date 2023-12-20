using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System.Runtime.CompilerServices;
using System;
using System.Diagnostics;

//#if UNITY_EDITOR

//using UnityEditor.Rendering.HighDefinition;
//using UnityEditor;

//[CustomPassDrawerAttribute(typeof(FS_SNNSharpen))]
//class FS_SNNSharpenEditor : CustomPassDrawer
//{
//    private class Styles
//    {
//        public static float defaultLineSpace = EditorGUIUtility.singleLineHeight + EditorGUIUtility.standardVerticalSpacing;

//        public static GUIContent mesh = new GUIContent("Mesh", "Mesh used for the scanner effect.");
//        public static GUIContent size = new GUIContent("Size", "Size of the effect.");
//        public static GUIContent rotationSpeed = new GUIContent("Speed", "Speed of rotation.");
//        public static GUIContent edgeThreshold = new GUIContent("Edge Threshold", "Edge detect effect threshold.");
//        public static GUIContent edgeRadius = new GUIContent("Edge Radius", "Radius of the edge detect effect.");
//        public static GUIContent glowColor = new GUIContent("Color", "Color of the effect");
//    }

//    SerializedProperty mesh;
//    SerializedProperty size;
//    SerializedProperty rotationSpeed;
//    SerializedProperty edgeDetectThreshold;
//    SerializedProperty edgeRadius;
//    SerializedProperty glowColor;

//    protected override void Initialize(SerializedProperty customPass)
//    {
//        mesh = customPass.FindPropertyRelative("mesh");
//        size = customPass.FindPropertyRelative("size");
//        rotationSpeed = customPass.FindPropertyRelative("rotationSpeed");
//        edgeDetectThreshold = customPass.FindPropertyRelative("edgeDetectThreshold");
//        edgeRadius = customPass.FindPropertyRelative("edgeRadius");
//        glowColor = customPass.FindPropertyRelative("glowColor");
//    }

//    // We only need the name to be displayed, the rest is controlled by the TIPS effect
//    protected override PassUIFlag commonPassUIFlags => PassUIFlag.Name;

//    protected override void DoPassGUI(SerializedProperty customPass, Rect rect)
//    {
//        //mesh.objectReferenceValue = EditorGUI.ObjectField(rect, Styles.mesh, mesh.objectReferenceValue, typeof(Mesh), false);
//        //rect.y += Styles.defaultLineSpace;

//        //size.floatValue = EditorGUI.Slider(rect, Styles.size, size.floatValue, 0.2f, TIPS.kMaxDistance);
//        //rect.y += Styles.defaultLineSpace;
//        //rotationSpeed.floatValue = EditorGUI.Slider(rect, Styles.rotationSpeed, rotationSpeed.floatValue, 0f, 30f);
//        //rect.y += Styles.defaultLineSpace;
//        //edgeDetectThreshold.floatValue = EditorGUI.Slider(rect, Styles.edgeThreshold, edgeDetectThreshold.floatValue, 0.1f, 5f);
//        //rect.y += Styles.defaultLineSpace;
//        //edgeRadius.intValue = EditorGUI.IntSlider(rect, Styles.edgeRadius, edgeRadius.intValue, 1, 6);
//        //rect.y += Styles.defaultLineSpace;
//        //glowColor.colorValue = EditorGUI.ColorField(rect, Styles.glowColor, glowColor.colorValue, true, false, true);
//    }

//    protected override float GetPassHeight(SerializedProperty customPass) => Styles.defaultLineSpace * 6;
//}

//#endif
class FS_SNNSharpen : CustomPass
{
    [SerializeField] public Material SNN_mat;
    [SerializeField] public Material Sharpen_mat;
    [SerializeField] [Range(0f, 1f)] public float _SNNIntensity = 1f;
    [SerializeField] [Range(1f, 20f)] public float _SNNHalfWidth = 5f;
    [SerializeField] [Range(0f, 1f)] public float _SharpIntensity = 1f;
    public static readonly int _MainTex = Shader.PropertyToID("_MainTex");
#if UNITY_EDITOR
    [SerializeField]
    public int debug;
    // 0,null   1,SNN   2,Sharp
#endif
    RTHandle tempBuffer; // additional render target for compositing the custom and camera color buffers

    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in an performance manner.
    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        // Setup code here
        var hdrpAsset = (GraphicsSettings.renderPipelineAsset as HDRenderPipelineAsset);
        var colorBufferFormat = hdrpAsset.currentPlatformRenderPipelineSettings.colorBufferFormat;
        tempBuffer = RTHandles.Alloc(
                    Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
                    colorFormat: (GraphicsFormat)colorBufferFormat,
                    useDynamicScale: true, name: "tempBuffer"
                );
        // tempBuffer = RTHandles.Alloc(Vector2.one, TextureXR.slices, dimension: TextureXR.dimension, colorFormat: GraphicsFormat.R16G16B16A16_SFloat, useDynamicScale: true, name: "Temp Buffer");
        UnityEngine.Debug.Log("rtwidth"+tempBuffer.rt.width);
        targetColorBuffer = TargetBuffer.Camera;
        targetDepthBuffer = TargetBuffer.Camera;
        clearFlags = ClearFlag.None;
    }

    protected override void Execute(CustomPassContext ctx)
    {
        // Executed every frame for all the camera inside the pass volume.
        // The context contains the command buffer to use to enqueue graphics commands.
        //CoreUtils.SetRenderTarget(ctx.cmd, ctx.cameraColorBuffer);
        //CoreUtils.DrawFullScreen(ctx.cmd, SNN_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);

        SNN_mat.SetFloat("_SNNIntensity", _SNNIntensity);
        SNN_mat.SetFloat("_SNNHalfWidth", _SNNHalfWidth);
        Sharpen_mat.SetFloat("_SharpIntensity", _SharpIntensity);
#if UNITY_EDITOR
        if (debug == 1)
        {
            ctx.cmd.ClearRenderTarget(false, true, Color.black);
            HDUtils.DrawFullScreen(ctx.cmd, SNN_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
        }
        else if (debug == 2)
        {
            //Sharpen_mat.SetTexture("_AfterSNNTex", ctx.cameraColorBuffer);
            //ctx.cmd.Blit(ctx.cameraColorBuffer, "c", Sharpen_mat, 0);
            ctx.cmd.ClearRenderTarget(false, true, Color.black);
            HDUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
            //HDUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
        }
#endif
#if UNITY_EDITOR
        if (debug == 0)
        {
#endif
            //ctx.cmd.SetRenderTarget(tempBuffer.rt);
            ctx.cmd.Blit(ctx.cameraColorBuffer, tempBuffer, SNN_mat, 0);
            Sharpen_mat.SetTexture("_MainTex", tempBuffer.rt);
            //ctx.cmd.ClearRenderTarget(false, true, Color.black);
            //ctx.cmd.SetRenderTarget(ctx.cameraColorBuffer);
            //ctx.cmd.CopyTexture(tempBuffer,ctx.cameraColorBuffer);
            //Shader.SetGlobalTexture("_AfterSNNTex", tempBuffer.rt);
            //CoreUtils.DrawFullScreen(ctx.cmd)
            ctx.cmd.Blit(tempBuffer, ctx.cameraColorBuffer, Sharpen_mat,0);
            CoreUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer);
            //Sharpen_mat.SetTexture("_AfterSNNTex", tempBuffer);
            ////CoreUtils.SetRenderTarget(ctx.cmd, ctx.cameraColorBuffer, ClearFlag.None);
            //CoreUtils.DrawFullScreen(ctx.cmd, Sharpen_mat, ctx.cameraColorBuffer, properties: ctx.propertyBlock);
#if UNITY_EDITOR
        }
#endif
    }

    protected override void Cleanup()
    {
        // Cleanup code
        tempBuffer.Release();
    }
}