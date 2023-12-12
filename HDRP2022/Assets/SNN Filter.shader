Shader "Custom/SNN Filter"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" { }
        _HalfWidth ("Sampler Count", int) = 5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        int _HalfWidth;
        float _SharpenStrength;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Name "Example"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct a2v
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            v2f vert(a2v v)
            {
                v2f o;
                
                //VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                //o.positionCS = positionInputs.positionCS;
                // Or this :
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }
            
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
                float2 src_size = _ScaledScreenParams.xy;
                float2 inv_src_size = 1.0f / src_size;
                float2 uv = fragCoord;
                
                float3 c0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
                
                float4 sum = float4(0.0f, 0.0f, 0.0f, 0.0f);
                
                for (int i = 0; i <= _HalfWidth; ++ i)
                {
                    float3 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(+i, 0) * inv_src_size).rgb;
                    float3 c2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(-i, 0) * inv_src_size).rgb;
                    
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
                        float3 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(+i, +j) * inv_src_size).rgb;
                        float3 c2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(-i, -j) * inv_src_size).rgb;
                        
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
            

            
            half4 frag(v2f i): SV_Target
            {
                //half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                //return baseMap;
                float3 result = CalcSNN(i.uv);
                //result = sharpenFilter(i.uv, _SharpenStrength);


                return float4(result, 1);
            }
            ENDHLSL
            
        }
    }
}