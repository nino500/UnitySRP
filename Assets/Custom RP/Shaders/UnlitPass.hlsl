#ifndef CUSTOM_UNLITPASS
#define CUSTOM_UNLITPASS

#include "../ShaderLibrary/Common.hlsl"



TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

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
    float2 uv:TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings UnlitPassVertex(Attributes input){
    Varyings output;

    //Extracts the index from the input and stores it in a global static variable that other instancing macro rely on 
    UNITY_SETUP_INSTANCE_ID(input);    
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    float4 positionCS = TransformWorldToHClip(positionWS);
    
    output.positionCS = positionCS;
    
    float4 uvST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMap_ST);
    float2 uv = input.uv*uvST.xy + uvST.zw; 
    
    output.uv = uv;
    
    return output;
}

half4 UnlitPassFragment(Varyings input):SV_TARGET{
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
    
    
    float4 color =  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
    
    float4 base = baseMap*color;
    
    
    #ifdef _CLIPPING
    clip(base.a-UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff));
    #endif
    return base;

}





#endif
