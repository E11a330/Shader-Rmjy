// 半兰伯特：映射 [-1,1] → [0,1]
float halfLambert = dot(normal, lightDir) * 0.5 + 0.5;

// 可选：平方增强对比度
float halfLambertSquared = pow(halfLambert, 2.0);

float3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * halfLambertSquared;