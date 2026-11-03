using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
   ShadowSetting shadowSetting;
   
   
   CullingResults cullingResults;
   
   const string bufferName = "Shadow";
   private CommandBuffer buffer = new CommandBuffer(){name = bufferName};
   
   ScriptableRenderContext context;
   
   
   //ShadowedDirectionalLight  Properties
   private const int maxShadowedDirectionalLightCount = 4, maxCascades = 4;   
   private struct ShadowedDirectionalLight
   {
      public int visibleLightIndex;
      public float slopScaleBias;
      public float nearPlaneOffset;

   }
    
   ShadowedDirectionalLight[] shadowedDirectionalLights = new  
      ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

   
   //Shadow Atlas Property Id for initializing  and using RT 
   private static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");
   
   //Cascade Property for sample shadow tiled map
   private static int cascadeCountId = Shader.PropertyToID("_CascadeCount");
   
   private static int cascadeCullingSpheresId =  Shader.PropertyToID("_CascadeCullingSpheres");
   private static Vector4[] cascadeCullingSpheres = new Vector4[maxCascades];
   
   private static int cascadeDataId = Shader.PropertyToID("_CascadeData");
   private static Vector4[] cascadeData = new Vector4[maxCascades]; 
   
   
   
   
   //shadow matrix for computing 
   static int dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices");
   Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowedDirectionalLightCount*maxCascades];
   
   
   //shadow max distance and its fraction  sent to GPU for culling properly and smooth fade
   static int shadowDistanceFadeId = Shader.PropertyToID("_ShadowDistanceFade");
  
   
   
   //CascadeBlendMode keywords

    static string[] cascadeBlendKeywords =
   {
      "_CASCADE_BLEND_SOFT",
      "_CASCADE_BLEND_DITHER"
   };
   
   
   //PCF setting
   static string[] directionalFilterKeywords = {
      "_DIRECTIONAL_PCF3",
      "_DIRECTIONAL_PCF5",
      "_DIRECTIONAL_PCF7",
   };
   
   //ShadowMap size data for PCF sampling
   private static int shadowAtlasSizeId = Shader.PropertyToID("_ShadowAtlasSize");

   
   
   
   int shadowedDirectionalLightCount;
   public void Setup(ScriptableRenderContext context, CullingResults cullingResults,ShadowSetting shadowSetting)
   {
      
      this.context = context;
      this.cullingResults = cullingResults;
      this.shadowSetting = shadowSetting;
      
      shadowedDirectionalLightCount = 0;

      
   }


   //compute and store the valid  index  in the buffer that will be uploaded to GPU later
   public Vector3 ReserveDirectionalShadows(Light light,int visibleLightIndex)
   {
      if (shadowedDirectionalLightCount < maxShadowedDirectionalLightCount
          && light.shadows != LightShadows.None 
          && light.shadowStrength > 0f
          && cullingResults.GetShadowCasterBounds(visibleLightIndex,out Bounds bounds))
      {
         shadowedDirectionalLights[shadowedDirectionalLightCount] = new 
            ShadowedDirectionalLight()
            {
               visibleLightIndex = visibleLightIndex,
               slopScaleBias = light.shadowBias,
               nearPlaneOffset = light.shadowNearPlane
            };

         return new Vector3(light.shadowStrength, shadowedDirectionalLightCount++*
                                                  shadowSetting.directional.cascadeCount,light.shadowNormalBias);

      }
      
      return  Vector3.zero;
   }
   
   public void Render()
   {
      if (shadowedDirectionalLightCount > 0)
      {
         RenderDirectionalShadows();
         
      }
      else
      {
         buffer.GetTemporaryRT(dirShadowAtlasId,1,1,32,
            FilterMode.Bilinear,RenderTextureFormat.Shadowmap);
      }
   }


   void RenderDirectionalShadows()
   {
      //get temporaryRT
      int atlasSize = (int)shadowSetting.directional.atlasSize;
      buffer.GetTemporaryRT(dirShadowAtlasId,atlasSize,atlasSize,32,
         FilterMode.Bilinear,RenderTextureFormat.Shadowmap);
      
      //set render target 
      buffer.SetRenderTarget(dirShadowAtlasId,RenderBufferLoadAction.DontCare,RenderBufferStoreAction.Store);
      buffer.ClearRenderTarget(true,false,Color.clear);
      
      
      
      
      buffer.BeginSample(bufferName);
      ExecuteBuffer();
      
      //split paramter
      int tiles = shadowedDirectionalLightCount * shadowSetting.directional.cascadeCount;
      int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 :4;
      int tileSize = atlasSize/split;
      
      for (int i = 0; i < shadowedDirectionalLightCount; i++)
      {
         
         RenderDirectionalShadows(i,split,tileSize);
      }
      
      
      //upload buffer to GPU
      
      buffer.SetGlobalInt(cascadeCountId,shadowSetting.directional.cascadeCount);


      float f = 1f - shadowSetting.directional.cascadeFade;
      buffer.SetGlobalVector(shadowDistanceFadeId, 
         new Vector4(1f/shadowSetting.maxDistance,1f/shadowSetting.distanceFade,
            1f/1f-f*f
         ));
      
      buffer.SetGlobalVectorArray(cascadeCullingSpheresId,cascadeCullingSpheres);
      buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);
      
      buffer.SetGlobalVectorArray(cascadeDataId,cascadeData);
      buffer.SetGlobalVector(shadowAtlasSizeId,new Vector4(atlasSize,1f / atlasSize));
     
      SetKeyWords(directionalFilterKeywords,(int)shadowSetting.directional.filter-1);
      SetKeyWords(cascadeBlendKeywords,(int)shadowSetting.directional.cascadeBlendMode-1);
     
      
      buffer.EndSample(bufferName);
      ExecuteBuffer();

   }

   
   
   void RenderDirectionalShadows(int index,int split, int tileSize)
   {
      ShadowedDirectionalLight light = shadowedDirectionalLights[index];
      var shadowDrawSettings = new ShadowDrawingSettings
         (cullingResults,light.visibleLightIndex,BatchCullingProjectionType.Orthographic);

      
      int cascadeCount = shadowSetting.directional.cascadeCount;
      int tileOffset = index * cascadeCount;
      Vector3 ratios = shadowSetting.directional.cascadeRatio;


      float cullingFactor = Mathf.Max(0f, 0.8f - shadowSetting.directional.cascadeFade);
      for (int i = 0; i < cascadeCount; i++)
      {
         
         cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
            light.visibleLightIndex, i, cascadeCount, ratios, tileSize, light.nearPlaneOffset,
            out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData
         );

         splitData.shadowCascadeBlendCullingFactor = cullingFactor;
         
         shadowDrawSettings.splitData = splitData;
         
         
         
         
         if (index == 0)
         {
            
            SetCascadeData(i,splitData.cullingSphere,tileSize);   
            
         }
         
         
         
         // tileOffset -> per light
         // i -> per cascade
         int tileIndex = tileOffset + i;
         //store the matrix that transform world space to atlas coordinates (after automated perspective-division)
         //change the viewport via SetViewport(,,) method
         dirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(projectionMatrix * viewMatrix,
            SetViewport(tileIndex,split,tileSize),split);
      
         //set current render setting, render a tiled shadow map by using a new VP
         buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
         
         buffer.SetGlobalDepthBias(0f,light.slopScaleBias);
         ExecuteBuffer();
      
         context.DrawShadows(ref shadowDrawSettings);
         
         buffer.SetGlobalDepthBias(0f,0f);
      }
      
      
   }


   Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
   {
      //Flip Z-axis to match the current platform's depth buffer
      if (SystemInfo.usesReversedZBuffer)
      {
         m.m20 = -m.m20;
         m.m21 = -m.m21;
         m.m22 = -m.m22;
         m.m23 = -m.m23;
      }
      
      //make sure that the range of texcoordinates is in tile range after perspective division
      float scale = 1f / split;
    
      m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
      m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
      m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
      m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
      m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
      m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
      m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
      m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
      m.m20 = 0.5f * (m.m20 + m.m30);
      m.m21 = 0.5f * (m.m21 + m.m31);
      m.m22 = 0.5f * (m.m22 + m.m32);
      m.m23 = 0.5f * (m.m23 + m.m33);

      return m;


   }
   
   
   
   
   Vector2 SetViewport(int index, int split, float tileSize)
   {
      Vector2 offset = new Vector2(index%split,index/split);
      buffer.SetViewport(new Rect(offset.x*tileSize,offset.y*tileSize,tileSize,tileSize));
      
      return offset;
   }

   void SetCascadeData(int cascadeIndex, Vector4 cullingSphere, int tileSize)
   {
      float texelSize = 2f*cullingSphere.w/tileSize;
      //for PCF 
      float filterSize = texelSize * (int)(shadowSetting.directional.filter + 1);
      
      
      cullingSphere.w -= filterSize;
      cullingSphere.w *= cullingSphere.w;
      cascadeCullingSpheres[cascadeIndex] = cullingSphere;
      
      
      cascadeData[cascadeIndex] = new Vector4(1f/cullingSphere.w,filterSize*1.4142136f);
      
      
   }

   void SetKeyWords(string[] keywords,int enabledIndex)
   {
      for (int i = 0; i < keywords.Length; i++)
      {
         if (i == enabledIndex)
         {
            buffer.EnableShaderKeyword(keywords[i]);
            
         }
         else
         {
            buffer.DisableShaderKeyword(keywords[i]);
         }
      }
   }
   
   
   


   //release RT and submit command
   public void Cleanup()
   {
      buffer.ReleaseTemporaryRT(dirShadowAtlasId);
      ExecuteBuffer();
      
   }
   
   
   
   
   public void ExecuteBuffer()
   {
      context.ExecuteCommandBuffer(buffer);
      buffer.Clear();
   }

}
