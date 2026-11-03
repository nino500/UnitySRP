using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Profiling;
using UnityEngine.Profiling;


// be used for Rendering per camera
 partial class CameraRenderer
 {
     partial void DrawUnSupportedShaders();

     partial void DrawGizmos();

     partial void PrepareForSceneWindow();

     

     partial void PrepareBuffer();

     
#if UNITY_EDITOR
        
    //shaders which is not been supported in this pipeline(human decision)
    static ShaderTagId[] legacyShaderTagIds = {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };

    //error material
     static Material errorMaterial;
     
    partial void DrawUnSupportedShaders()
    {
        if (errorMaterial == null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        DrawingSettings drawingSettings = new DrawingSettings(legacyShaderTagIds[0], new SortingSettings(camera))
        {
            overrideMaterial = errorMaterial
        };
        FilteringSettings filteringSettings = FilteringSettings.defaultValue;
        

        for (int i = 1; i < legacyShaderTagIds.Length; i++)
        {
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }
        
        context.DrawRenderers(cullingResults,ref drawingSettings,ref filteringSettings);

    }







    partial void DrawGizmos()
    {
        if (UnityEditor.Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera,GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera,GizmoSubset.PostImageEffects);
        }
    }



    
    

    //let UI be rendered in scene window
    partial void PrepareForSceneWindow()
    {
        if (camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
    }
    
    
    
    
    //change the bufferName and sampleName per camera
    string SampleName { get; set; }
    
    //change the buffer name by camera's name in order to get different name in framedebugger
    partial void PrepareBuffer()
    {
        Profiler.BeginSample("Editor Only");
        buffer.name = SampleName = camera.name;
        Profiler.EndSample();
    }
    
    
    
#else
    const string SampleName = bufferName;
    
#endif
    
}
