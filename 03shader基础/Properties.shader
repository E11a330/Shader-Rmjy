Shader "Custom/StandardHLSL"
{
    // ========== 属性面板 ==========
    Properties
    {
        [MainTexture] _MainTex ("Albedo", 2D) = "white" {}
        [MainColor]  _Color   ("Color", Color) = (1,1,1,1)

        [Normal] _BumpMap   ("Normal Map", 2D) = "bump" {}
        _BumpScale          ("Normal Scale", Range(0,2)) = 1.0

        _MetallicGlossMap ("Metallic (R) Smoothness (A)", 2D) = "white" {}
        _Glossiness       ("Smoothness", Range(0,1)) = 0.5
        _Metallic         ("Metallic", Range(0,1)) = 0.0

        _EmissionMap  ("Emission", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,1)

        _DetailAlbedoMap ("Detail Albedo", 2D) = "gray" {}
        _DetailNormalMap ("Detail Normal", 2D) = "bump" {}
        _DetailMask      ("Detail Mask", 2D) = "white" {}

        _ParallaxMap ("Height Map", 2D) = "black" {}
        _Parallax    ("Height Scale", Range(0.005, 0.08)) = 0.02

        _OcclusionMap ("Occlusion", 2D) = "white" {}
        _OcclusionStrength ("Occlusion Strength", Range(0,1)) = 1.0

        _CubeMap ("Reflection Probe", Cube) = "" {}

        [Toggle] _Invert ("Invert Normals", Float) = 0.0
        [Toggle(_ENABLE_DETAIL)] _EnableDetail ("Enable Detail Maps", Float) = 1.0
        [Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0.0

        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comp", Float) = 8.0

        [HideInInspector] _Dummy ("Hidden", Float) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        // ========== Pass 0 : 主渲染 ==========
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            // 渲染状态
            ZWrite   [_ZWrite]
            Cull     [_Cull]
            Blend    [_SrcBlend] [_DstBlend]
            Stencil {
                Ref  [_StencilRef]
                Comp [_StencilComp]
            }

            HLSLPROGRAM

            // 编译指令
            #pragma vertex   LitPassVertex
            #pragma fragment LitPassFragment

            // 多编译变体
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _EMISSION
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _OCCLUSIONMAP
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature_local _ENABLE_DETAIL

            // 引入核心库（URP）
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ========== CBUFFER 常量缓冲区 ==========
            CBUFFER_START(UnityPerMaterial)
                // 纹理需在 cbuffer 外声明，但 ST、颜色、数值放在这里
                float4 _MainTex_ST;
                float4 _DetailAlbedoMap_ST;
                float4 _BumpMap_ST;
                float4 _DetailNormalMap_ST;
                float4 _EmissionMap_ST;
                float4 _ParallaxMap_ST;
                float4 _OcclusionMap_ST;
                float4 _MetallicGlossMap_ST;

                half4  _Color;
                half4  _EmissionColor;
                half   _BumpScale;
                half   _Glossiness;
                half   _Metallic;
                half   _Parallax;
                half   _OcclusionStrength;
                half   _Invert;
                half   _EnableDetail;
            CBUFFER_END

            // 纹理声明（必须在 cbuffer 外部，Unity 宏管理采样器）
            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);
            TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
            TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
            TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
            TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
            TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
            TEXTURECUBE(_CubeMap);          SAMPLER(sampler_CubeMap);

            // 结构体定义
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                // 细节 UV 使用不同通道
                float2 detailUV     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 normalWS     : TEXCOORD3;
                float4 tangentWS    : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD5;
                float2 staticLightmapUV : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // ========== 顶点着色器 ==========
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // 世界空间位置
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;

                // 世界空间法线和切线
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS  = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS, input.tangentOS.w);
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);

                // UV 计算
                output.uv         = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.detailUV   = TRANSFORM_TEX(input.texcoord, _DetailAlbedoMap);
                output.staticLightmapUV = input.staticLightmapUV;

                return output;
            }

            // ========== 片元着色器 ==========
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                // 视差遮蔽映射
                float2 uv = input.uv;
                #if defined(_PARALLAXMAP)
                    half height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, uv).r;
                    float2 offset = ParallaxOffset1Step(height, _Parallax, input.viewDirWS);
                    uv += offset;
                    input.detailUV += offset;
                #endif

                // 采样主纹理
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _Color;

                // 细节纹理
                #if defined(_DETAIL_MULX2) && defined(_ENABLE_DETAIL)
                    half4 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, input.detailUV);
                    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, input.uv).r;
                    albedo.rgb = lerp(albedo.rgb, albedo.rgb * detailAlbedo.rgb * 2.0h, detailMask);
                #endif

                // 法线
                half3 normalTS = half3(0,0,1);
                #if defined(_NORMALMAP)
                    half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
                    normalTS = UnpackNormalScale(normalMap, _BumpScale);
                #endif
                #if defined(_DETAIL_MULX2) && defined(_ENABLE_DETAIL)
                    half4 detailNormal = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, input.detailUV);
                    half3 detailNormalTS = UnpackNormalScale(detailNormal, _BumpScale * detailMask);
                    normalTS = BlendNormalRNM(normalTS, detailNormalTS);
                #endif
                float sgn = input.tangentWS.w;
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                float3x3 TBN = float3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz);
                half3 normalWS = normalize(mul(normalTS, TBN));
                #if defined(_INVERT)
                    normalWS = -normalWS;
                #endif

                // 金属/光滑度
                half metallic = _Metallic;
                half smoothness = _Glossiness;
                #if defined(_METALLICGLOSSMAP)
                    half4 metallicGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
                    metallic  *= metallicGloss.r;
                    smoothness *= metallicGloss.a;
                #endif

                // 环境遮蔽
                half occlusion = 1.0;
                #if defined(_OCCLUSIONMAP)
                    half occTex = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
                    occlusion = lerp(1.0, occTex, _OcclusionStrength);
                #endif

                // 自发光
                half3 emission = 0;
                #if defined(_EMISSION)
                    emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).rgb * _EmissionColor.rgb;
                #endif

                // BRDF 输入
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.normalWS   = normalWS;
                inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo      = albedo.rgb;
                surfaceData.metallic    = metallic;
                surfaceData.smoothness  = smoothness;
                surfaceData.occlusion   = occlusion;
                surfaceData.emission    = emission;
                surfaceData.alpha       = albedo.a;

                // 光照计算（URP 主光源 + 环境光）
                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                return color;
            }
            ENDHLSL
        }

        // ========== 阴影投射 Pass ==========
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(input.normalOS);
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}