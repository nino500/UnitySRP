#ifndef CUSTOM_LITPASS
#define CUSTOM_LITPASS

// common variable and function
#include "../ShaderLibrary/Common.hlsl"


// custom surface struct
#include "../ShaderLibrary/Surface.hlsl"


// custom shadow matrix array
#include "../ShaderLibrary/Shadows.hlsl"

// custom light struct and global light properties
#include "../ShaderLibrary/Light.hlsl"




// custom lighting results getter 
#include "../ShaderLibrary/Lighting.hlsl"



TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

//没有在drawmeshinstanced 的block参数配置覆盖的属性，会使用材质面板的数据
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)

    UNITY_DEFINE_INSTANCED_PROP(float,_Metallic)
    UNITY_DEFINE_INSTANCED_PROP(float,_Smoothness)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)


struct Attributes
{
    float3 positionOS: POSITION;
    
    float2 uv: TEXCOORD0;
    float3 normalOS:NORMAL;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS:VAR_POSITION;
    float2 uv:VAR_TEXCOORD;
    float3 normalWS:VAR_NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings LitPassVertex(Attributes input){
    Varyings output;

    //Extracts the index from the input and stores it in a global static variable that other instancing macro rely on 
    UNITY_SETUP_INSTANCE_ID(input);    
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    float4 positionCS = TransformWorldToHClip(positionWS);
    
    output.positionWS = positionWS;
    output.positionCS = positionCS;
    
    float4 uvST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMap_ST);
    float2 uv = input.uv*uvST.xy + uvST.zw; 
    
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = uv;
    
    return output;
}

half4 LitPassFragment(Varyings input):SV_TARGET{
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
    
    
    float4 baseColor =  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
    
    float4 base = baseMap*baseColor;
    
    Surface surface;
    
    surface.normal = normalize(input.normalWS);
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.positionWS = input.positionWS;
    
    //get the positive Z value in View Space for comparing to the maxDistance 
    surface.depth = -TransformWorldToView(input.positionWS).z;
    
    
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Metallic);
    surface.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Smoothness);
    
    surface.dither = InterleavedGradientNoise(input.positionCS.xy,0);
    
    #if defined(_PREMULTPLY_ALPHA)
    BRDF brdf = GetBRDF(surface,true);
    #else
        BRDF brdf = GetBRDF(surface,false);
    #endif
    
    //intput :surface and light input
    //output : final color
    float3 color = GetLighting(surface,brdf);
    
    
    #ifdef _CLIPPING
    clip(surface.alpha-UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff));
    #endif
    
    return float4(color,surface.alpha);

}





#endif
