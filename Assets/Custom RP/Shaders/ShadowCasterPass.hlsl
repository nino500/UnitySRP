#ifndef CUSTOM_SHADOW_CASTER_PASS
#define CUSTOM_SHADOW_CASTER_PASS

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
    
    float2 uv = TransformBaseUV(input.uv);
    
    output.uv = uv;
    
    return output;
}



void ShadowCasterPassFragment(Varyings input){
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
    
    
    float4 base =  GetBaseColor(input.uv);
  
    
    
    #if defined(_SHADOWS_CLIP)
    clip(base.a-GetCutoff(input.uv));
    #elif defined(_SHADOWS_DITHER)
    float dither = InterleavedGradientNoise(input.positionCS.xy,0);
    clip(base.a - dither);
    
    
    #endif
    
    
    
    
}





#endif
