//shader命名
Shader "NPR/Niluo/Body"
{
    //属性面板
    properties
{

}
//子着色器/定义渲染方案
//SubShader 是 ShaderLab 中负责实际渲染的核心容器，每个 Shader 可包含多个 SubShader。Unity 会根据当前硬件和渲染管线的支持情况，自动选择第一个可运行的 SubShader。
//SubShader 内部封装了渲染状态（如Blend、ZTest、Cull）、Tags和 LOD，并包含一个或多个 Pass。通过提供多个 SubShader，开发者可以为不同性能的设备或图形 API 准备适配方案，实现兼容性和性能的平衡。
//Fallback ：写在SubShader语义块后面，用于指定保底着色器。当所有 SubShader 当前硬件都不支持时，Unity 会自动使用 Fallback 里的着色器
    SubShader 
    {
//定义渲染标签 (/渲染类型/渲染管线/渲染队列
        Tags{"renderType" ="Opaque" "renderPopeline"="UniversalPipeline" "Queue"="Geometry"}

//定义常量缓冲区（Uniform Buffer Object）/传递数据给GPU
//这样做能让 CPU 将材质数据一次性推送到 GPU 缓存中，多个使用相同 Shader 的模型只需切换索引，不再重复 SetPass Call，提升性能
//CBUFFER 只能放固定大小的数值类型（float/int/half 及其向量/矩阵），纹理、采样器、缓冲区对象都不能放
//CBUFFER块必须放在Pass块内但是可以放在HLSLINCLUDE中，这个块的内容会被所有Pass块共享
        HLSLINCLUDE

            CBUFFER_START(UnityPerMaterial)

            CBUFFER_END
            
        ENDHLSL

//通道/具体的渲染逻辑
        pass
        {
//通道名称/渲染标签/剔除模式            
            Name "FORWARD"
            Tags{"LightMode"="UniversalForward"}
            Cull back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
//顶点属性结构体/顶点着色器输入            
            struct Attributes
            {

            };
//顶点着色器输出/片段着色器输入
            struct Varyings
            {

            };
//顶点着色器/处理顶点数据，进行变换等操作
            Varyings vert(Attributes v)
            {

            }
//片段着色器/处理像素数据，进行光照、纹理采样等操作
            half4 frag(Varyings i):SV_Target
            {
                
            }
            HLSLEND
        }
    }
  
}

