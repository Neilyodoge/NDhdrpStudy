Shader "n/RoleOutline"
{
    Properties
    {
        // _MainTex("Base Texture", 2D) = "white" {}
        // _BaseColor("Base Color", Color) = (1,1,1,1)
        // _Alpha("Alpha", Range(0,1)) = 1

        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Float) = 0.02
    }
    
    SubShader
    {
        Tags { "IgnoreProjector"="True" "RenderType"="Transparent" "Queue"="Transparent" }
        Lighting Off
        ZTest Always
        ZWrite off
        Cull front
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            float _OutlineWidth;
            float4 _OutlineColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            sampler2D _SelectionMaskRT;

            v2f vert(appdata v)
            {
                v2f o;
                float3 norm = normalize(v.normal);
                v.vertex.xyz += norm * _OutlineWidth;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uvss = i.screenPos.xy / i.screenPos.w;
                float mask = tex2D(_SelectionMaskRT, uvss).r;
                float4 c = _OutlineColor;
                c.a *= step(mask.rrr,0.5);
                return c;
            }

            ENDCG
        }
    }
}
