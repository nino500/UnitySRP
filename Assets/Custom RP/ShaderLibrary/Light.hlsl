#ifndef CUSTOM_LIGHT 
#define CUSTOM_LIGHT



//global custom buffer instead of per material  
#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
    int _DirectionalLightCount;
    float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END




struct Light
{
    float3 color;
    float3 direction;
    float attenuation;
};


//getter
int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

//
DirectionalShadowData GetDirectionalShadowData(int index,ShadowData shadowData)
{
    DirectionalShadowData data;
    data.shadowStrength = _DirectionalLightShadowData[index].x*shadowData.strength;
    data.tileIndex = _DirectionalLightShadowData[index].y + shadowData.cascadeIndex;
    data.normalBias = _DirectionalLightShadowData[index].z;
    return data;

}



Light GetDirectionalLight(int index,Surface surfaceWS,ShadowData shadowData)
{
    Light light;
    light.color = _DirectionalLightColors[index].rgb;
    light.direction = _DirectionalLightDirections[index].xyz;
    
    
    
    DirectionalShadowData dirShadowData = GetDirectionalShadowData(index,shadowData);
    light.attenuation = GetDirectionalShadowAttenuation(dirShadowData,shadowData,surfaceWS);
    return light;
}




#endif
