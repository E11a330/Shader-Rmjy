Shader "Custom/BlinnPhongLighting"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(1, 512)) = 32
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ===== 材质属性 =====
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float4 _SpecularColor;
                float  _Shininess;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // ===== 结构体 =====
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float3 worldPos   : TEXCOORD2;
            };

            // ===== 顶点着色器 =====
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = posInputs.positionCS;
                OUT.worldPos   = posInputs.positionWS;

                VertexNormalInputs normalInputs = GetNormalInputs(IN.normalOS, IN.tangentOS);
                OUT.normalWS = normalInputs.normalWS;

                OUT.uv = IN.uv * _MainTex_ST.xy + _MainTex_ST.zw;

                return OUT;
            }

            // ===== 片元着色器（Blinn-Phong） =====
            half4 frag(Varyings IN) : SV_Target
            {
                // ----- 获取主光源 -----
                Light mainLight = GetMainLight();

                // ----- 准备向量 -----
                float3 N = normalize(IN.normalWS);
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(_WorldSpaceCameraPos - IN.worldPos);

                // ★ Blinn-Phong 核心：半角向量
                float3 H = normalize(L + V);

                // ----- 纹理采样 -----
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float3 albedo = texColor.rgb * _Color.rgb;

                // ----- 1. 环境光 -----
                float3 ambient = SampleSH(N) * albedo;

                // ----- 2. 漫反射（Lambert） -----
                float NdotL = max(0.0, dot(N, L));
                float3 diffuse = albedo * mainLight.color * NdotL;

                // ----- 3. 镜面反射（Blinn-Phong） -----
                float NdotH = max(0.0, dot(N, H));
                float3 specular = _SpecularColor.rgb * mainLight.color * pow(NdotH, _Shininess);

                // ----- 合成最终颜色 -----
                float3 finalColor = ambient + diffuse + specular;

                return half4(finalColor, texColor.a * _Color.a);
            }
            ENDHLSL
        }
    }
}