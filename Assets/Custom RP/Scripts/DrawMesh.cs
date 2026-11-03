using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public class DrawMesh : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");
    static int cutoffID = Shader.PropertyToID("_Cutoff");
    static int metallicID = Shader.PropertyToID("_Metallic");
    static int smoothnessID = Shader.PropertyToID("_Smoothness");
    
    [SerializeField]private Mesh mesh;
    [SerializeField] private Material material;

    Matrix4x4[] matrices = new Matrix4x4[1023];
    Vector4[] colors = new Vector4[1023];
    float[] metallics = new float[1023];
    float[] smoothnesses = new float[1023];
    

    private MaterialPropertyBlock block;
    
    
    private void Awake()
    {
        for (int i = 0; i < matrices.Length; i++)
        {
            matrices[i] = Matrix4x4.TRS(UnityEngine.Random.insideUnitSphere*10f,Quaternion.identity,Vector3.one);
            
            colors[i] = new Vector4(UnityEngine.Random.value, UnityEngine.Random.value, UnityEngine.Random.value, UnityEngine.Random.value);
            
            metallics[i] = UnityEngine.Random.value<0.25f?1f:0f;
            smoothnesses[i] = UnityEngine.Random.Range(0.05f, 0.95f);
        }   
    }


    void Update()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
            block.SetVectorArray(baseColorID, colors);
            block.SetFloatArray(metallicID, metallics);
            block.SetFloatArray(smoothnessID, smoothnesses);
        }
        
        Graphics.DrawMeshInstanced(mesh, 0, material, matrices,1023,block);
        
    }
  
}
