Shader "Custom/Lit"
{
    Properties
    {
        _BaseColor("Base Color",Color) = (0.5,0.5,0.5,1.0)
        _BaseMap("Texture",2D) = "white"{}
        
        [HideInInspector] _MainTex("Texture for Lightmap",2D) = "white"{}
        [HideInInspector] _Color("Color for Lightmap",Color) = (0.5,0.5,0.5,1.0)
        
        
        [NoScaleOffset] _EmissionMap("Emission Map",2D) = "white"{}
        [HDR] _EmissionColor("Emission Color",Color) = (0.0, 0.0, 0.0, 0.0)
        
        
        
        [Header(PBR Properties)]
        _Metallic("Metallic ",Range(0,1)) = 0
        _Smoothness("Smoothness",Range(0,1)) = 0.5
        
        [Space(20)]
        
        [Header(Blend Test)]
        _Cutoff("Alpha Cutoff",Float) = 0.3
        [Toggle(_CLIPPING)] _Clipping("Alpha Clipping",Float) = 0
        [Toggle(_PREMULTIPLY_ALPHA)] _PremultiplyAlpha("Premultiply Alpha",Float) = 0
        

        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend",Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend",Float) = 0
        
        [Enum(Off,0,On,1)] _ZWrite ("Z Write",Float) = 1
        
        
        [KeywordEnum(On,Clip,Dither,Off)] _Shadows("Shadows",Float) = 0
        
       [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1

    }

    SubShader
    {
        Tags
        {
            
        }
        
        
        HLSLINCLUDE
        
        // common UnityInput and function
        #include "../ShaderLibrary/Common.hlsl"
        
        //custom LitInput 
        #include "../Shaders/LitInput.hlsl"
        
        ENDHLSL
        
        
        Pass
        {
            Tags {"LightMode" = "CustomLit"}
            
            
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            
           HLSLPROGRAM
         
           #include "LitPass.hlsl"
           #pragma multi_compile _ LIGHTMAP_ON
           #pragma multi_compile_instancing
           #pragma shader_feature _CLIPPING
           #pragma shader_feature _RECEIVE_SHADOWS
           #pragma shader_feature _PREMULTIPLY_ALPHA
           
           #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
           #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
           
           #pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE 
           #pragma multi_compile _ LOD_FADE_CROSSFADE
           
           
           #pragma target 3.5
           #pragma vertex LitPassVertex
           #pragma fragment LitPassFragment
           
           
           
           
           ENDHLSL

            
        }

        Pass
        {
            Tags {"LightMode" = "ShadowCaster"}
            
            
            ColorMask 0
            HLSLPROGRAM
            
            #pragma target  3.5
            #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER 
            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #include "ShadowCasterPass.hlsl"
            #pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
            
            
            ENDHLSL
        }


        Pass
        {
            Tags {"LightMode" = "Meta"}
            
            Cull Off
            
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment
            #include "../Shaders/MetaPass.hlsl"
        
            ENDHLSL
        }


    }


    CustomEditor "CustomShaderGUI"
    
}