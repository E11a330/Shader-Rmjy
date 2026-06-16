// 基础了兰伯特
// 顶点着色器输出结构
struct VertexOutput
{
    float4 pos : SV_POSITION;      // 裁剪空间位置
    float2 uv : TEXCOORD0;         // 纹理坐标
    float3 normalWS : TEXCOORD1;   // 世界空间法线
};

// 顶点着色器
VertexOutput vert(float4 posOS : POSITION, float3 normalOS : NORMAL, float2 uv : TEXCOORD0)
{
    VertexOutput output;
    
    // 转换到裁剪空间
    output.pos = mul(UNITY_MATRIX_MVP, posOS);
    
    // 转换法线到世界空间
    output.normalWS = mul((float3x3)unity_ObjectToWorld, normalOS);
    output.normalWS = normalize(output.normalWS);
    
    output.uv = uv;
    
    return output;
}

// 片元着色器
float4 frag(VertexOutput input) : SV_Target
{
    // 材质属性
    float3 albedo = tex2D(_MainTex, input.uv).rgb;
    float3 diffuseColor = albedo * _DiffuseIntensity;
    
    // 光源方向（假设单方向光）
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    
    // 兰伯特核心：max(0, dot(N, L))
    float NdotL = max(0.0, dot(input.normalWS, lightDir));
    
    // 漫反射光照
    float3 diffuse = _LightColor0.rgb * diffuseColor * NdotL;
    
    // 环境光
    float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
    
    // 最终颜色
    float3 finalColor = ambient + diffuse;
    
    return float4(finalColor, 1.0);
}










// 逐像素兰伯特
// 顶点着色器只传递法线，不计算光照
VertexOutput vert(float4 posOS : POSITION, float3 normalOS : NORMAL, float2 uv : TEXCOORD0)
{
    VertexOutput output;
    output.pos = mul(UNITY_MATRIX_MVP, posOS);
    output.normalWS = mul((float3x3)unity_ObjectToWorld, normalOS);
    output.uv = uv;
    return output;
}

// 片元着色器中逐像素计算
float4 frag(VertexOutput input) : SV_Target
{
    // 归一化法线（逐像素）
    float3 normal = normalize(input.normalWS);
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    
    // 兰伯特系数
    float NdotL = max(0.0, dot(normal, lightDir));
    
    // ... 其余部分相同
}
