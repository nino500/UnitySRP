using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    //editor panel
    [SerializeField]
    private Color baseColor = Color.white; private float metallic = 0; private float smoothness = 0;
    private float cutoff;
    
    //shared shader id for set up MaterialPropertyBlock
    private static int baseColorID = Shader.PropertyToID("_BaseColor"),
        cutoffID = Shader.PropertyToID("_Cutoff"),
        metallicId = Shader.PropertyToID("_Metallic"),
        smoothnessId = Shader.PropertyToID("_Smoothness");
    
    
    
    
    static MaterialPropertyBlock propertyBlock;

    void Awake()
    {
        OnValidate();
    }
    
    
    void OnValidate()
    {
        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();

        }
        
        //save the baseColorID
        propertyBlock.SetColor(baseColorID, baseColor);
        propertyBlock.SetFloat(cutoffID, cutoff);
        propertyBlock.SetFloat(metallicId,metallic);
        propertyBlock.SetFloat(smoothnessId,smoothness );
        
        //override the  material's parameter correspond to baseColorID
        GetComponent<Renderer>().SetPropertyBlock(propertyBlock);
        
    }
    
    
    
    
}
