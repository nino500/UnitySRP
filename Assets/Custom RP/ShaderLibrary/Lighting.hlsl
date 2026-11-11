#ifndef CUSTOM_LIGHTING
#define CUSTOM_LIGHTING



// custom BRDF Function
#include "../ShaderLibrary/BRDF.hlsl"




//the final energy received by surface
float3 GetIncomingLight(Surface surface,Light light)
{
    return saturate(dot(surface.normal,light.direction)*light.attenuation)*light.color;
}


float3 GetLighting(Surface surfaceWS,BRDF brdf,Light light)
{
    
    return GetIncomingLight(surfaceWS,light)*DirectBRDF(surfaceWS,brdf,light);
}



//the entry function for outside
float3 GetLighting(Surface surfaceWS,BRDF brdf,GI gi)
{
    ShadowData shadowData = GetShadowData(surfaceWS);
    shadowData.shadowMask = gi.shadowMask;
    
    
    float3 color = IndirectBRDF(surfaceWS,brdf,gi.diffuse,gi.specular);
    
    //per light source compute
    for (int i =0;i<GetDirectionalLightCount();i++)
    {
        color += GetLighting(surfaceWS,brdf,GetDirectionalLight(i,surfaceWS,shadowData));
    }
    
    
    return color;
}




#endif
