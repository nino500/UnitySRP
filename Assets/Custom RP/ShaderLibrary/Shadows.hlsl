#ifndef CUSTOM_SHADOWS
#define CUSTOM_SHADOWS


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"


#if defined( _DIRECTIONAL_PCF3)
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP  SampleShadow_ComputeSamples_Tent_3x3

#elif defined( _DIRECTIONAL_PCF5)
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP  SampleShadow_ComputeSamples_Tent_5x5

#elif defined(_DIRECTIONAL_PCF7)
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif




#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);

#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
    int _CascadeCount;
    float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    float4 _CascadeData[MAX_CASCADE_COUNT];

    float4 _ShadowDistanceFade;

    float4 _ShadowAtlasSize;

    float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT
        *MAX_CASCADE_COUNT];
CBUFFER_END

//shadow data struct uesd in light computing 
// per light
struct DirectionalShadowData
{
    float shadowStrength;
    int tileIndex; //the index for selecting the exact zone for sampling
    float normalBias;
};

//cascade index
//per fragment
struct ShadowData
{
    int cascadeIndex;
    float cascadeBlend;
    float strength;
};

float DistanceSquared(float3 pA, float3 pB)
{
    return dot(pA-pB,pA-pB);
}




float FadeShadowStrength(float distance,float maxDistance,float fade)
{
    return saturate((1.0 - distance * maxDistance)*fade);
}


ShadowData GetShadowData(Surface surfaceWS)
{
    ShadowData data;
    
    data.cascadeBlend = 1.0;
    
    data.strength = FadeShadowStrength(surfaceWS.depth,
        _ShadowDistanceFade.x,_ShadowDistanceFade.y);
        
    int i ;
    for (i =0;i<_CascadeCount;i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        float distance = DistanceSquared(surfaceWS.positionWS,sphere.xyz);
        
        if (distance < sphere.w)
        {
            float fade = FadeShadowStrength(distance,_CascadeData[i].x,
                    _ShadowDistanceFade.z);
            
            if (i == _CascadeCount-1)
            {
                data.strength *= fade;
            }else
            {
                data.cascadeBlend = fade;
            }
            break;
        }
    }
    if (i == _CascadeCount)
    {
        data.strength = 0.0;
    }
    #if defined(_CASCADE_BLEND_DITHER)
    else if (data.cascadeBlend < surfaceWS.dither)
    {
        i+=1;
    }
    #endif
    
    
    #if !defined(_CASCADE_BLEND_SOFT)
        data.cascadeBlend = 1.0;
    #endif
    
    
    data.cascadeIndex = i;    //the offset to  the  shadowedlight index 
    return data;
}






//sample shadow atlas(tool function)
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas,SHADOW_SAMPLER,positionSTS);
}

float FilterDirectionalShadow(float3 positionSTS)
{
    #if defined(DIRECTIONAL_FILTER_SETUP)
    float weights[DIRECTIONAL_FILTER_SAMPLES];
    float2 positions[DIRECTIONAL_FILTER_SAMPLES];
    float4 size = _ShadowAtlasSize.yyxx;
    DIRECTIONAL_FILTER_SETUP(size, positionSTS.xy, weights, positions);
    float shadow = 0;
    for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++) {
        shadow += weights[i] * SampleDirectionalShadowAtlas(
            float3(positions[i].xy, positionSTS.z)
        );
    }
    return shadow;
    #else
    return SampleDirectionalShadowAtlas(positionSTS);
    #endif
}








//compute the shadow factor
float GetDirectionalShadowAttenuation(DirectionalShadowData directional,ShadowData global,Surface surfaceWS)
{
    
    #if !defined(_RECEIVE_SHADOWS)
    return 1.0;
    
    #endif
    
    
    if (directional.shadowStrength <= 0.0f)
    {
        return 1.0f;
    }
    
    
    float3 normalBias = surfaceWS.normal *( directional.normalBias* _CascadeData[global.cascadeIndex].y);
    float3 positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex],
        float4(surfaceWS.positionWS + normalBias ,1.0)).xyz;
    
    float shadow = FilterDirectionalShadow(positionSTS);
    
    if (global.cascadeBlend < 1.0)
    {
         normalBias = surfaceWS.normal *( directional.normalBias* _CascadeData[global.cascadeIndex+1].y);
         positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex+1],
            float4(surfaceWS.positionWS + normalBias ,1.0)).xyz; 
         shadow = lerp(FilterDirectionalShadow(positionSTS),shadow,global.cascadeBlend);
    }
    
    
    return lerp(1.0,shadow,directional.shadowStrength);
}



#endif