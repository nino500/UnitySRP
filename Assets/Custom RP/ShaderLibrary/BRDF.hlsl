#ifndef CUSTOM_BRDF
#define CUSTOM_BRDF

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
    float perceptualRoughness;
    
    float fresnel;
};


float Square(float v)
{
    return v*v;
}

//compute the fraction rate with the input metallic in the energy conservation principle
#define MIN_REFLECTIVITY 0.04
float OneMinusReflectivity(float metallic)
{
    float range = 1 - MIN_REFLECTIVITY;
    return range - metallic*range;
}


//output diffuse and specular color/input energy
BRDF GetBRDF(Surface surface,bool applyAlphaToDiffuse)
{
    BRDF brdf;
    
    //premultiply alpha so that alpha blend only affect diffuse 
    brdf.diffuse = surface.color*OneMinusReflectivity(surface.metallic);
    if (applyAlphaToDiffuse)
    {
        brdf.diffuse *= surface.alpha;
    }
    
    
    
    //metals affects the color of specular while nonmetals don't
    brdf.specular = lerp(MIN_REFLECTIVITY,surface.color,surface.metallic);
    
    
    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
    
    
    brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
    
    
    //grazingTerm
    brdf.fresnel = saturate(surface.smoothness + (1.0 - OneMinusReflectivity(surface.metallic)));
    
    return brdf;
}




float3 IndirectBRDF(Surface surface, BRDF brdf, float3 diffuse,float3 specular)
{
    
    float fresnelStrength = surface.fresnelStrength*Pow4(1 - dot(surface.normal,surface.viewDirection));
    
    float3 reflection = specular*lerp(brdf.specular,brdf.fresnel,fresnelStrength);
    reflection /= brdf.roughness*brdf.roughness + 1.0;
    
    
    return diffuse*brdf.diffuse + reflection;
    
}







//Specular Term to control the specular distribution
float SpecularStrength (Surface surface, BRDF brdf, Light light) {
    float3 h = SafeNormalize(light.direction + surface.viewDirection);
    float nh2 = Square(saturate(dot(surface.normal, h)));
    float lh2 = Square(saturate(dot(light.direction, h)));
    float r2 = Square(brdf.roughness);
    float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
    float normalization = brdf.roughness * 4.0 + 2.0;
    return r2 / (d2 * max(0.1, lh2) * normalization);
}

//output final color/reflective energy
float3 DirectBRDF(Surface surface,BRDF brdf, Light light)
{
    return SpecularStrength(surface, brdf, light)*brdf.specular + brdf.diffuse;
}



#endif 