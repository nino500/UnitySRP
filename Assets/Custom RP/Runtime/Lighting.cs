using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{    
    //pipeline
    private CullingResults cullingResults;

    private const string bufferName = "Lighting";

    private CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };
    
    //light
    private const int maxDirLightCount = 4;
    
    static int dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors");
    static int dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections");
    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");

    private static Vector4[]
        dirLightDirections = new Vector4[maxDirLightCount],
        dirLightColors = new Vector4[maxDirLightCount];

    //shadow
    private Shadows shadows = new Shadows();

    static int dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");
    
    //storage shadow data per light
    Vector4[] dirShadowData = new Vector4[maxDirLightCount];

    
    
    public void Setup(ScriptableRenderContext context,CullingResults results,ShadowSetting shadowSetting)
    {
        this.cullingResults = results;
        
        buffer.BeginSample(bufferName);
        
        //initalize shadow class and valid shadowedLight Array
        shadows.Setup(context,cullingResults,shadowSetting);
        
        //upload lightdata to GPU buffer and Reserve the valid light index in valid shadowedLight Array
        SetupLights(cullingResults);
        
        //render shadow map for valid light 
        shadows.Render();
        
        
        buffer.EndSample(bufferName);
        
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
        
    }

    void SetupLights(CullingResults cullingResults)
    {
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;

        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];

            if (visibleLight.lightType == LightType.Directional)
            {
                SetupDirectionalLight(dirLightCount++,i,ref visibleLight);
                if (dirLightCount >= maxDirLightCount)
                {
                    break;
                }
            }
           
        }
        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirShadowData);
        
        
        
    }
    
    

     void SetupDirectionalLight(int index,int visibleLightIndex,ref VisibleLight visibleLight)
     {

         dirLightColors[index] = visibleLight.finalColor;
         dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
         
         dirShadowData[index] = shadows.ReserveDirectionalShadows
             (visibleLight.light,visibleLightIndex);
 
     }







     public void Cleanup()
     {
         shadows.Cleanup();
         
         
     }
     
     
}   
    
