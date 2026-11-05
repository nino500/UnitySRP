#ifndef CUSTOM_UN_LIT_INPUT_INCLUDE
#define CUSTOM_UN_LIT_INPUT_INCLUDE


TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

//没有在drawmeshinstanced 的block参数配置覆盖的属性，会使用材质面板的数据
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)



UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV(float2 baseUV)
{
    float4 uvST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMap_ST);
    float2 uv = baseUV*uvST.xy + uvST.zw;
    return uv;
}

float4 GetBaseColor(float2 baseUV)
{
    float4 basemap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,baseUV);
    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
    return basemap*color;
    
}

float3 GetEmission(float2 baseUV)
{
    return GetBaseColor(baseUV).rgb;
}



float GetMetallic(float2 baseUV)
{
    return 0.0;
    
}

float GetSmoothness(float2 baseUV)
{
    return 0.0;
}

float GetCutoff(float2 baseUV)
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff);
}

#endif