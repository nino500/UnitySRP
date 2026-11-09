//防止重复包含文件内容
#ifndef CUSTOM_COMMON
#define CUSTOM_COMMON

//提供精度名real,纹理采样宏，常量缓冲区宏，通用数学函数，深度处理函数等
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
//提供BRDF参数处理函数：感知粗糙度和光滑度转化
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

//声明一些Unity内置变量
#include "UnityInput.hlsl"



//定义宏替换到内置变量
#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject

#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_I_V unity_MatrixInvV

#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_PREV_MATRIX_M unity_prev_MatrixM
#define UNITY_PREV_MATRIX_I_M unity_prev_MatrixIM
#define UNITY_MATRIX_P glstate_matrix_projection



#if defined(_SHADOW_MASK_DISTANCE)||defined(_SHADOW_MASK_ALWAYS)
    #define SHADOWS_SHADOWMASK
#endif

//引入GPUInstancing,更改上述矩阵宏定义，切换宏对应的数据来源，让每个instance自己的矩阵定义上文矩阵宏
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//坐标变换库，这些函数内部使用了上文的宏名称，依赖于上文的宏定义，而不关心数据来源
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


#endif