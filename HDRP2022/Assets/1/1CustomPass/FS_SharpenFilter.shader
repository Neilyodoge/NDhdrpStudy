Shader "FullScreen/FS_SharpenFilter"
{
    Properties
    {
        _MainTex("MainTex",2D) = "gray"
    }
    HLSLINCLUDE

    #pragma vertex Vert
 #pragma enable_d3d11_debug_symbols
    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassCommon.hlsl"

    // The PositionInputs struct allow you to retrieve a lot of useful information for your fullScreenShader:
    // struct PositionInputs
    // {
    //     float3 positionWS;  // World space position (could be camera-relative)
    //     float2 positionNDC; // Normalized screen coordinates within the viewport    : [0, 1) (with the half-pixel offset)
    //     uint2  positionSS;  // Screen space pixel coordinates                       : [0, NumPixels)
    //     uint2  tileCoord;   // Screen tile coordinates                              : [0, NumTiles)
    //     float  deviceDepth; // Depth from the depth buffer                          : [0, 1] (typically reversed)
    //     float  linearDepth; // View space Z coordinate                              : [Near, Far]
    // };

    // To sample custom buffers, you have access to these functions:
    // But be careful, on most platforms you can't sample to the bound color buffer. It means that you
    // can't use the SampleCustomColor when the pass color buffer is set to custom (and same for camera the buffer).
    // float4 CustomPassSampleCustomColor(float2 uv);
    // float4 CustomPassLoadCustomColor(uint2 pixelCoords);
    // float LoadCustomDepth(uint2 pixelCoords);
    // float SampleCustomDepth(float2 uv);

    // There are also a lot of utility function you can use inside Common.hlsl and Color.hlsl,
    // you can check them out in the source code of the core SRP package.
    TEXTURE2D(_MainTex);
    float3 sharpenFilter(float2 fragCoord)
    {
        float3 f =  SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,fragCoord + float2(0, -1)).rgb * -1. +
                    SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,fragCoord + float2(-1, 0)).rgb * -1. +
                    SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,fragCoord + float2(0, 0)).rgb  * 5.  +
                    SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,fragCoord + float2(1, 0)).rgb * -1.  +
                    SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,fragCoord + float2(0, 1)).rgb * -1.  ;

        return f;
    }

    float2 ClampUVs(float2 uv)
    {
        uv = clamp(uv, 0, _RTHandleScale.xy - _ScreenSize.zw * 2); // clamp UV to 1 pixel to avoid bleeding
        return uv;
    }

    float4 FullScreenPass(Varyings varyings) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
        float depth = LoadCameraDepth(varyings.positionCS.xy);
        PositionInputs posInput = GetPositionInput(varyings.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float3 viewDirection = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
        float4 color = float4(0.0, 0.0, 0.0, 0.0);

        float2 uv = ClampUVs(varyings.positionCS.xy * _ScreenSize.zw * _RTHandleScale.xy);
        // Load the camera color buffer at the mip 0 if we're not at the before rendering injection point
        if (_CustomPassInjectionPoint != CUSTOMPASSINJECTIONPOINT_BEFORE_RENDERING)
            color = float4(CustomPassLoadCameraColor(varyings.positionCS.xy, 0), 1);

        // Add your custom pass code here
        //varyings.positionCS.y *= -1;
        //color.rgb = sharpenFilter(varyings.positionCS.xy * _ScreenSize.zw * _RTHandleScale.xy);
        color.rgb = SAMPLE_TEXTURE2D(_MainTex,s_linear_repeat_sampler,uv).rgb;
        // Fade value allow you to increase the strength of the effect while the camera gets closer to the custom pass volume
        float f = 1 - abs(_FadeValue * 2 - 1);
        return float4(color.rgb + f, color.a);
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "Custom Pass 0"

            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
                #pragma fragment FullScreenPass
            ENDHLSL
        }
    }
    Fallback Off
}
