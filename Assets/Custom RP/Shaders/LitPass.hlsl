#ifndef CUSTOM_LIT_PASS
#define CUSTOM_LIT_PASS


// custom surface struct
#include "../ShaderLibrary/Surface.hlsl"


// custom shadow matrix array
#include "../ShaderLibrary/Shadows.hlsl"

// custom light struct and global light properties
#include "../ShaderLibrary/Light.hlsl"


//GI 
#include "../ShaderLibrary/GI.hlsl"

// custom lighting results getter 
#include "../ShaderLibrary/Lighting.hlsl"



//GI Macro

#if defined(LIGHTMAP_ON)
    #define GI_ATTRIBUTE_DATA  float2 lightMapUV : TEXCOORD1;
    #define GI_VARYINGS_DATA    float2 lightMapUV:VAR_LIGHT_MAP_UV;
    #define TRANSFER_GI_DATA(input, output) \    
            output.lightMapUV = input.lightMapUV * \
            unity_LightmapST.xy + unity_LightmapST.zw;
            




    #define GI_FRAGMENT_DATA(input)  input.lightMapUV

#else

    #define GI_ATTRIBUTE_DATA
    #define GI_VARYINGS_DATA
    #define TRANSFER_GI_DATA(input, output)
    #define GI_FRAGMENT_DATA(input) 0.0

#endif




struct Attributes
{
    float3 positionOS: POSITION;
    
    float2 uv: TEXCOORD0;
    float3 normalOS:NORMAL;
    
    GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS:VAR_POSITION;
    float2 uv:VAR_TEXCOORD;
    float3 normalWS:VAR_NORMAL;
    
    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings LitPassVertex(Attributes input){
    Varyings output;

    //Extracts the index from the input and stores it in a global static variable that other instancing macro rely on 
    UNITY_SETUP_INSTANCE_ID(input);    
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    
    TRANSFER_GI_DATA(input, output)
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    float4 positionCS = TransformWorldToHClip(positionWS);
    
    output.positionWS = positionWS;
    output.positionCS = positionCS;
    
    float2 uv = TransformBaseUV(input.uv);
    
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = uv;
    
    return output;
}



void ClipLOD(float fade,float2 positionCS)
{
    
    #if defined(LOD_FADE_CROSSFADE)
    float dither = InterleavedGradientNoise(positionCS.xy,0);
    clip(fade +(fade<0?dither:-dither));
    #endif
}





half4 LitPassFragment(Varyings input):SV_TARGET{
    //use the same macro as before to make the instanceID available
    UNITY_SETUP_INSTANCE_ID(input);
        
    ClipLOD(unity_LODFade.x,input.positionCS.xy);
    
    
    float4 base =  GetBaseColor(input.uv);
    
    Surface surface;
    
    surface.normal = normalize(input.normalWS);
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.positionWS = input.positionWS;
    
    //get the positive Z value in View Space for comparing to the maxDistance 
    surface.depth = -TransformWorldToView(input.positionWS).z;
    
    
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.metallic = GetMetallic(input.uv);
    surface.smoothness = GetSmoothness(input.uv);
    
    surface.dither = InterleavedGradientNoise(input.positionCS.xy,0);
    
    #if defined(_PREMULTIPLY_ALPHA)
    BRDF brdf = GetBRDF(surface,true);
    #else
        BRDF brdf = GetBRDF(surface,false);
    #endif
    
    //input :Surface ,LightModel input,GI param(lightmap)
    //output : final color
    GI gi = GetGI(GI_FRAGMENT_DATA(input),surface);
    float3 color = GetLighting(surface,brdf,gi);
    color += GetEmission(input.uv);
    
    #ifdef _CLIPPING
    clip(surface.alpha-GetCutoff(input.uv));
    #endif
    

    
    return float4(color,surface.alpha);

}





#endif
