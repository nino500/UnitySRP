using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;



public class CustomRP : RenderPipeline
{
    private bool useDynamicBatching;
    private bool useGPUInstancing;

    private ShadowSetting shadowSetting;
    
    
    
    public CustomRP(bool useSRPBatcher,bool useDynamicBatching, bool useGPUInstancing,ShadowSetting shadows)
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        
        
        //save the shadow setting
        this.shadowSetting = shadows;
        
        
        
        //turn on the Linear Intensity  which will be performed on visibleLight.finalColor
        GraphicsSettings.lightsUseLinearIntensity = true;

    }
    
    
    
    
    //create renderer for execute specific rendering codes, just for convenience
    CameraRenderer renderer   = new CameraRenderer();
    
    //unity call this method for every frame in the game loop
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        
    }

    protected override void Render(ScriptableRenderContext context, List<Camera> cameras)
    {
        
        
        //execute renderer's code for every camera 
        for (int i = 0; i < cameras.Count; i++)
        {
            renderer.Render(context, cameras[i],useDynamicBatching, useGPUInstancing,shadowSetting);
        }
        
    }
    
    
    
}
