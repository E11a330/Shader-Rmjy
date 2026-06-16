#pragma region 基础数据类型

//##########################标量类型

// 浮点类型
float   // 32位浮点数（高精度）
half    // 16位浮点数（中等精度）
fixed   // 11位浮点数（低精度，主要用于旧版 Unity）

// 整数类型
int     // 32位整数
uint    // 32位无符号整数

// 布尔类型
bool    // true/false

//##########################精度选择

// 颜色和纹理（使用 half/fixed）
half3 albedo;
fixed4 color;

// 世界坐标和深度（使用 float）
float3 worldPos;
float depth;

// 法线和方向（使用 half）
half3 normal;
half3 lightDir;

// 循环计数器（使用 int）
int loopCount;

#pragma endregion





#pragma region 向量类型
// 不同维度的向量
float2  v2;  // 2D向量 (x, y)
float3  v3;  // 3D向量 (x, y, z)
float4  v4;  // 4D向量 (x, y, z, w)

// 同样适用于 half、fixed、int
half2  h2;
fixed4 f4;
int3   i3;

// 访问分量
float4 pos = float4(1, 2, 3, 4);
float x = pos.x;        // 1
float yz = pos.yz;      // (2, 3)
float rgb = pos.rgb;    // (1, 2, 3) - 用于颜色
float rgba = pos.rgba;  // 同上
#pragma endregion




#pragma region 矩阵类型
// 矩阵定义
float2x2 m2x2;  // 2x2矩阵
float3x3 m3x3;  // 3x3矩阵
float4x4 m4x4;  // 4x4矩阵（最常用）

// 矩阵访问
float4x4 mvp = UNITY_MATRIX_MVP;
float4 row0 = mvp[0];  // 第一行
float elem = mvp[0][0]; // 第一行第一列
#pragma endregion





#pragma region 纹理/采样器类型
// 2D纹理
sampler2D _MainTex;
sampler2D _NormalMap;

// 3D纹理
sampler3D _VolumeTex;

// Cube纹理（环境贴图）
samplerCUBE _EnvMap;

// 数组纹理（需要Unity 5.4+）
Texture2DArray _TexArray;
SamplerState sampler_TexArray;

// 在较新Unity版本中推荐使用
Texture2D _MainTex;
SamplerState sampler_MainTex;
#pragma endregion



#pragma region 结构体类型
// 顶点着色器输入
struct appdata
{
    float4 vertex : POSITION;  // 顶点位置
    float3 normal : NORMAL;    // 法线
    float4 tangent : TANGENT;  // 切线
    float2 uv : TEXCOORD0;     // UV坐标
    float2 uv1 : TEXCOORD1;    // 第二套UV
    float4 color : COLOR;      // 顶点颜色
};

// 片段着色器输入（顶点着色器输出）
struct v2f
{
    float4 pos : SV_POSITION;   // 裁剪空间位置
    float2 uv : TEXCOORD0;      // UV坐标
    float3 normal : TEXCOORD1;  // 世界法线
    float3 worldPos : TEXCOORD2; // 世界坐标
};
#pragma endregion








