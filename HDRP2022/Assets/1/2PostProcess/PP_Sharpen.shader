Shader "Hidden/Shader/PP_Sharpen"
{
    Properties
    {
        // This property is necessary to make the CommandBuffer.Blit bind the source texture to _MainTex
        _MainTex("Main Texture", 2DArray) = "grey" {}
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    // List of properties to control your post process effect
    float _Intensity;
    TEXTURE2D_X(_MainTex);

    // 类拉普拉斯卷积核,参考 https://zhuanlan.zhihu.com/p/511643260
    float3 sharpenFilter(float2 fragCoord)
    {
        float3 f =  SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler,fragCoord + float2(0, -1) * _PostProcessScreenSize.zw).rgb * -1. +
                    SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler,fragCoord + float2(-1, 0) * _PostProcessScreenSize.zw).rgb * -1. +
                    SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler,fragCoord + float2(0, 0) * _PostProcessScreenSize.zw).rgb  * 5.  +
                    SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler,fragCoord + float2(1, 0) * _PostProcessScreenSize.zw).rgb * -1.  +
                    SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler,fragCoord + float2(0, 1) * _PostProcessScreenSize.zw).rgb * -1.  ;

        return f;
    }

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        // Note that if HDUtils.DrawFullScreen is not used to render the post process, you don't need to call ClampAndScaleUVForBilinearPostProcessTexture.
        float3 color = 1;

        float3 sourceColor = SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord.xy)).xyz;

        float3 SharpenFilterResult = lerp(sharpenFilter(ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord.xy)),color.rgb,_Intensity);

        // Apply greyscale effect
        color = sourceColor;//lerp(sourceColor, SharpenFilterResult, _Intensity);

        return float4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "PP_Sharpen"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}
