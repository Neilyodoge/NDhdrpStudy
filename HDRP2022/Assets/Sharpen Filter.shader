Shader "Custom/Sharpen Filter"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" { }
        _HalfWidth ("Sampler Count", int) = 5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        
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
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            int _HalfWidth;
            float _SharpenStrength;
            CBUFFER_END
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
            
            //Copy from https://www.shadertoy.com/view/XlycDV
            float3 texSample(float x, float y, float2 uv)
            {
                float2 src_size = _ScaledScreenParams.xy;
                float2 inv_src_size = 1.0f / src_size;
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(x, y) * inv_src_size).rgb;
            }
            
            float3 sharpenFilter(in float2 fragCoord, float strength)
            {
                float3 f = texSample(-1, -1, fragCoord) * - 1. +
                texSample(0, -1, fragCoord) * - 1. +
                texSample(1, -1, fragCoord) * - 1. +
                texSample(-1, 0, fragCoord) * - 1. +
                texSample(0, 0, fragCoord) * 9. +
                texSample(1, 0, fragCoord) * - 1. +
                texSample(-1, 1, fragCoord) * - 1. +
                texSample(0, 1, fragCoord) * - 1. +
                texSample(1, 1, fragCoord) * - 1.
                ;
                return lerp(texSample(0, 0, fragCoord), f, strength);
            }
            
            half4 frag(v2f i): SV_Target
            {
                //half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                //return baseMap;
                //float3 result = CalcSNN(i.uv);
                float3 result = sharpenFilter(i.uv, _SharpenStrength);


                return float4(result, 1);
            }
            ENDHLSL
            
        }
    }
}