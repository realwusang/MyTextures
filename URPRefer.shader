Shader "Custom/URPRefer"
{
    Properties
    {
        [KeywordEnum(Body,Face,Hair)] _RENDER("Body Parts",float) = 0
        [Space(15)]
        _BaseMap("BaseMap", 2D) = "white" {}
        [NoScaleOffset]_LightMap("LightMap",2D) = "white" {}
        [Enum(Day,2,Night,1)]_TimeShift("Day&Night Switch",int) = 2
        
        [HideInInspector]
        _fDirWS("Face Front Direction",vector) = (0,0,1,0)
    }

        SubShader
        {
            LOD 100
            Tags
            {
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
                "IgnoreProjector" = "True"
                "RenderPipeline" = "UniversalPipeline"
            }
            HLSLINCLUDE
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _RENDER_BODY _RENDER_FACE _RENDER_HAIR
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            CBUFFER_END

                TEXTURE2D(_BaseMap);
                SAMPLER(sampler_BaseMap);
                TEXTURE2D_X_FLOAT(_CameraDepthTexture);
                SAMPLER(sampler_CameraDepthTexture);

                struct a2v
                {
                    float4 vertex            : POSITION;
                    float2 uv                : TEXCOORD0;
                    float3 normal            : NORMAL;
                    float4 tangent           : TANGENT;
                };

                struct v2f
                {
                    float4 vertex                : SV_POSITION;
                    float2 uv                    : TEXCOORD0;
                    float3 worldPos              : TEXCOORD1;
                    float4 worldNormal           : TEXCOORD2;
                    float4 screenPos             :TEXCOORD3;
                    float3 worldTangent          : TEXCOORD4;
                    float3 worldBitangent        : TEXCOORD5;
                };

                float4 TransformHClipToViewPortPos(float4 positionCS)
                {
                    float4 o = positionCS * 0.5f;
                    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
                    o.zw = positionCS.zw;
                    return o / o.w;
                }
                ENDHLSL

                UsePass "Universal Render Pipeline/Lit/ShadowCaster"
                Pass
                {
                    Tags{ "LightMode" = "UniversalForward" }
                    HLSLPROGRAM

                    v2f vert(a2v v)
                    {
                        v2f o;

                        o.vertex = TransformObjectToHClip(v.vertex);
                        o.uv = v.uv;
                        o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                        o.worldNormal.xyz = TransformObjectToWorldNormal(v.normal);
                        o.worldNormal.w = ComputeFogFactor(o.vertex.z);
                        o.screenPos = ComputeScreenPos(o.vertex);
                        o.worldTangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0)).xyz);
                        o.worldBitangent = normalize(cross(o.worldNormal.xyz, o.worldTangent) * v.tangent.w);
                        return o;
                    }

                half4 frag(v2f i) : SV_Target
                {
                    Light mainLight = GetMainLight();
                    float4 mainLightColor = float4(mainLight.color, 1);

                    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv * _BaseMap_ST.xy + _BaseMap_ST.zw);

                    float3 lDirWS = normalize(mainLight.direction);
    #if _RENDER_BODY
                    float3 vDirWS = normalize(GetCameraPositionWS() - i.worldPos);
                    float3 nDirVS = TransformWorldToView(i.worldNormal);

                    half4 color = 1;

    #elif _RENDER_FACE
                    half4 color = 0;
    #endif
                    color.xyz = MixFog(color.xyz, i.worldNormal.w);

                    return color;
                }
                ENDHLSL
            }
        }
}
