#ifndef CUSTOM_SHADOW_CASTER_PASS
#define CUSTOM_SHADOW_CASTER_PASS

// common variable and function
#include "../ShaderLibrary/Common.hlsl"


TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
//没有在drawmeshinstanced 的block参数配置覆盖的属性，会使用材质面板的数据
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)


struct Attributes
{
    float3 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv:VAR_TEXCOORD;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings ShadowCasterPassVertex(Attributes input){
    Varyings output;

    //Extracts the index from the input and stores it in a global static variable that other instancing macro rely on 
    UNITY_SETUP_INSTANCE_ID(input);    
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    float4 positionCS = TransformWorldToHClip(positionWS);
    
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z,positionCS.w*UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z,positionCS.w*UNITY_NEAR_CLIP_VALUE);
    #endif
    
    
    
    output.positionCS = positionCS;
    
    float4 uvST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMap_ST);
    float2 uv = input.uv*uvST.xy + uvST.zw; 
    
    output.uv = uv;
    
    return output;
}



void ShadowCasterPassFragment(Varyings input){
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
    
    
    float4 baseColor =  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
    
    float4 base = baseMap*baseColor;
    
    
    #if defined(_SHADOWS_CLIP)
    clip(base.a-UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff));
    #elif defined(_SHADOWS_DITHER)
    float dither = InterleavedGradientNoise(input.positionCS.xy,0);
    clip(base.a - dither);
    
    
    #endif
    
    
    
    
}





#endif
