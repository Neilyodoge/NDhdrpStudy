Shader "Custom/PlanarShadow"
{
    Properties
    {
        [Header(Shadow)]
        _GroundHeight("_GroundHeight", Float) = 0
        _ShadowColor("_ShadowColor", Color) = (0,0,0,1)
	    _ShadowFalloff("_ShadowFalloff", Range(0,1)) = 0.05
        _LightPos("LightPos",vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "IgnoreProjector"="True" "RenderType"="Transparent" "Queue"="Transparent" }
        // Planar Shadows平面阴影
        Pass
        {
            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与地面穿插
            Offset -1 , 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float3 normalWS : NORMAL;
            };

            float4 _LightDir;
            float4 _ShadowColor;
            float4 _LightPos;
            float _ShadowFalloff;
            float _GroundHeight;

            float3 ShadowProjectPos(float4 vertPos)
            {
                float3 shadowPos;
                //得到顶点的世界空间坐标
                float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;
                shadowPos = worldPos;
                //灯光方向
                float3 L = _LightPos.xyz;
                //阴影的世界空间坐标（低于地面的部分不做改变）
                shadowPos.y = min(worldPos.y , _GroundHeight);
                shadowPos.xz -= L.xz * max(0 , worldPos.y - _GroundHeight) / L.y; 
                return shadowPos;
            }

            v2f vert (appdata v)
            {
                v2f o;
                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(v.vertex);
                //转换到裁切空间
                o.vertex = UnityWorldToClipPos(shadowPos);
                //得到中心点世界坐标
                float3 center =float3( unity_ObjectToWorld[0].w , _GroundHeight , unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFalloff);
                //阴影颜色
                o.color = _ShadowColor; 
                o.color.a *= falloff;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
    // FallBack "Diffuse"
}