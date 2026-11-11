#ifndef CUSTOM_SURFACE
#define CUSTOM_SURFACE
struct Surface
{
    float3 normal;
    float3 viewDirection;
    float3 positionWS;
    float depth;
    
    float3 color;
    float metallic;
    float smoothness;
    float fresnelStrength;
    float alpha;
    
    
    float dither;
};


#endif
