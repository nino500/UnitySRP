using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Custom RP Asset")]
public class CustomRPAsset : RenderPipelineAsset
{
  [SerializeField]  bool useSRPBatcher = true;
  [SerializeField] bool useDynamicBatching;
  [SerializeField]  bool useGPUInstancing = true;

  [SerializeField]  ShadowSetting shadows = default;
  
  protected override RenderPipeline CreatePipeline()
  {
    return new CustomRP(useSRPBatcher, useDynamicBatching, useGPUInstancing,shadows);
  }
  
  
  
}
