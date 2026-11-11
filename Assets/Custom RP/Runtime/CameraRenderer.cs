using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;



// be used for Rendering per camera
public partial class CameraRenderer
{
    //context and camera
    ScriptableRenderContext context;
    private Camera camera;
    
    //a command buffer for write commands into context and
    //sample datas for  profiler and frame debugger
    private const string bufferName = "custom command buffer";
        CommandBuffer buffer = new CommandBuffer(){name = bufferName};
        
    
    //store cull results assignment in cull(),used in context.DrawRenderer()
    CullingResults cullingResults;
        
    //shaderTagId used in context.DrawRenderer()
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    static ShaderTagId litShaderTagId = new  ShaderTagId("CustomLit");
    
        

    //Lighting tool class for setup lighting
    Lighting lighting = new Lighting();
        
    //the main method 
    public void Render(ScriptableRenderContext context, Camera camera,bool useDynamicBatching,bool useGPUInstancing,ShadowSetting shadowSetting)
    {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        //exam the results of culling 
        if (!Cull(shadowSetting.maxDistance))
        {
            return;
        }
        
        
        
        buffer.BeginSample(SampleName);
        ExecuteBuffer();
        //set light properties
        lighting.Setup(context,cullingResults,shadowSetting);
        buffer.EndSample(SampleName);
        
        //1.set camera properties for engine variable to compute and use like MVP Matrix
        //2.clear render target
        //3.set sample point
        
        Setup();
        //write commands to context
            DrawVisibleGeometry(useDynamicBatching,useGPUInstancing);
            DrawGizmos();
        
        //cleanup release resource
        lighting.Cleanup();

        
        //copy draw commands from command buffer into context if necessary and submit commands to SRP via context.submit() 
        Submit();
    }

    
    bool Cull(float maxShadowDistance)
    {
        //get culling parameter of camera
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            //set the culling parameters in terms of shadow distance
            p.shadowDistance = Mathf.Min(maxShadowDistance,camera.farClipPlane);
            
            //get cullingResults via context.Cull() with culling parameter work as input
            cullingResults = context.Cull(ref p);
            return true;
        }

        return false;
    }

    void Setup()
    {
        //pass the camera data for MVP matrix construction
        //set the screen buffer as render target
        context.SetupCameraProperties(camera);
        
        
        
        
        //set clear logic: different behavior in different render state
        CameraClearFlags flags = camera.clearFlags;
        buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth,flags<=CameraClearFlags.Color,flags==CameraClearFlags.Color?camera.backgroundColor.linear:Color.clear);
        
        //set sample point
        buffer.BeginSample(SampleName);
        
        ExecuteBuffer();
    }
    

    //draw commands collection
    void DrawVisibleGeometry(bool useDynamicBatching,bool useGPUInstancing)
    {
        //write draw commands into context via a dedicate method
        
            //set critera field to choose a specific draw order 
            
        //draw opaque queue
        SortingSettings sortingSettings = new SortingSettings(camera){criteria = SortingCriteria.CommonOpaque};
        
        
        DrawingSettings drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing,
            perObjectData = PerObjectData.ReflectionProbes|PerObjectData.Lightmaps|PerObjectData.LightProbe|
                            PerObjectData.LightProbeProxyVolume|
                            PerObjectData.ShadowMask|
                            PerObjectData.OcclusionProbe
        };
        
        //set the second shader pass in this DrawSetting
        drawingSettings.SetShaderPassName(1, litShaderTagId);
        
        FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        
        context.DrawRenderers(cullingResults,ref drawingSettings,ref filteringSettings);




        DrawUnSupportedShaders();
                
        

        
        
        //draw skybox
        //write draw commands into context via a dedicate method
        context.DrawSkybox(camera);
        
        
        //draw transparent queue
        sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;

            filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults,ref drawingSettings,ref filteringSettings);



    }


    

    void ExecuteBuffer()
    {
        //copy the commands from commandbuffer into context

        context.ExecuteCommandBuffer(buffer);
        
        //clear the commmands in buffer explicitly
        buffer.Clear();
    }

    //submit the draw commands collected by context
    void Submit()
    {       
        buffer.EndSample(SampleName);
        
        ExecuteBuffer();

        context.Submit();
    }


    
    
}
