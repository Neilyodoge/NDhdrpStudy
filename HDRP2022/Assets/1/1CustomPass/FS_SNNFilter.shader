Shader "FullScreen/FS_SNNFilter"
{
    Properties
    {
        _LerpBase("LerpBase",range(0,1)) = 0
        _HalfWidth ("Sampler Count", range(-1,20)) = 5
    }
    HLSLINCLUDE

    #pragma vertex Vert

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
    float _HalfWidth;
    float _LerpBase;
    //Copy from https://www.shadertoy.com/view/MlyfWd
    // Calculate color distance
    float CalcDistance(float3 c0, float3 c1)
    {
        float3 sub = c0 - c1;
        return dot(sub, sub);
    }
    
    // Symmetric Nearest Neighbor
    float3 CalcSNN(float2 fragCoord)
    {
        float2 uv = fragCoord;
        
        float3 c0 = CustomPassLoadCameraColor(uv, 0);
        
        float4 sum = float4(0.0f, 0.0f, 0.0f, 0.0f);
        
        for (int i = 0; i <= _HalfWidth; ++ i)
        {
            float3 c1 = CustomPassLoadCameraColor(uv + float2(+i, 0) ,0).rgb;
            float3 c2 = CustomPassLoadCameraColor(uv + float2(-i, 0) ,0).rgb;
            
            float d1 = CalcDistance(c1, c0);
            float d2 = CalcDistance(c2, c0);
            if (d1 < d2)
            {
                sum.rgb += c1;
            }
            else
            {
                sum.rgb += c2;
            }
            sum.a += 1.0f;
        }
        for (int j = 1; j <= _HalfWidth; ++ j)
        {
            for (int i = -_HalfWidth; i <= _HalfWidth; ++ i)
            {
                // float3 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(+i, +j) * _ScreenSize.zw).rgb;
                float3 c1 = CustomPassLoadCameraColor(uv + float2(+i, +j) ,0).rgb;
                float3 c2 = CustomPassLoadCameraColor(uv + float2(-i, -j) ,0).rgb;
                
                float d1 = CalcDistance(c1, c0);
                float d2 = CalcDistance(c2, c0);
                if(d1 < d2)
                {
                    sum.rgb += c1;
                }
                else
                {
                    sum.rgb += c2;
                }
                sum.a += 1.0f;
            }
        }
        return sum.rgb / sum.a;
    }
    float4 FullScreenPass(Varyings varyings) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
        float depth = LoadCameraDepth(varyings.positionCS.xy);
        PositionInputs posInput = GetPositionInput(varyings.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float3 viewDirection = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
        float4 color = float4(0.0, 0.0, 0.0, 0.0);

        // Load the camera color buffer at the mip 0 if we're not at the before rendering injection point
        if (_CustomPassInjectionPoint != CUSTOMPASSINJECTIONPOINT_BEFORE_RENDERING)
            color = float4(CustomPassLoadCameraColor(varyings.positionCS.xy, 0), 1);

        // Add your custom pass code here
        float3 SNNFilterResult = CalcSNN(varyings.positionCS.xy);
        color.rgb = lerp(SNNFilterResult,color.rgb,_LerpBase);
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
