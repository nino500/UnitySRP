#ifndef CUSTOM_UNLITPASS
#define CUSTOM_UNLITPASS




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
    
     
    float2 uv = TransformBaseUV(input.uv);
    
    output.uv = uv;
    
    return output;
}

half4 UnlitPassFragment(Varyings input):SV_TARGET{
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
    
    
    float4 base =  GetBaseColor(input.uv);

    
    #ifdef _CLIPPING
    clip(base.a-GetCutoff(input.uv));
    #endif
    return base;

}





#endif
