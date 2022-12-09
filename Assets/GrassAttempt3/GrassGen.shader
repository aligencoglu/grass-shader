

Shader "Unlit/GrassGen"
{
    Properties
    {
        _PlayerWorldPosition ("Player Position", Vector) = (0, 0, 0, 0)
        _GrassWidth ("Grass Width", Integer) = 1
        _GrassHeight ("GrassHeight", Range(0, 1)) = 0
        _GrassColor ("Grass Color", Color) = (0, 1, 0, 1)
        _WindIntensity ("Wind Intensity", Float) = 0
        _WindAngle ("Wind Angle", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling

            #include "UnityCG.cginc"
            #include "Assets/Noise.cginc"

            float _GrassWidth;
            float4 _GrassColor;
            float _GrassHeight;
            float _WindIntensity;
            float _WindAngle;
            float4 _PlayerWorldPosition;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float disturbance : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float invLerp(float a, float b, float x) {
                return ( x - a ) / ( b - a );
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                float4 oldVertex = v.vertex;

                // -- displace texture depending on wind or displacement texture --

                // 1. applying wind
                float4 worldPos = mul( UNITY_MATRIX_M, v.vertex ); // object to world
                float angle = _WindAngle * UNITY_PI; // wind angle to radians
                
                float4 windDirection = mul( unity_WorldToObject, 
                                            float4( cos( angle ), sin( angle ), 0, 0 ) 
                                            ); // wind direction vector from angle
                
                float noise = perlin1dTo1d( worldPos.x * 2 + _Time.y * _WindIntensity ) + 1; // create noise
                float4 disturbance = mul( unity_WorldToObject, 
                                          float4( sin( angle ), -cos( angle ), 0, 0 ) ) * 0.1 * noise * _WindIntensity;
                
                windDirection += disturbance;
                v.vertex = lerp( v.vertex, v.vertex + windDirection + float4(0, _GrassHeight - 1, 0, 0), v.uv.y );

                // 2. applying displacement texture (bent by players etc.)
                worldPos = mul( UNITY_MATRIX_M, v.vertex ); // update object to world
                // float2 distFromWorldPosToPlayer2D = worldPos.xy - _PlayerWorldPosition.xy; // disregard z axis
                float3 distFromWorldPosToPlayer = worldPos.xyz - _PlayerWorldPosition.xyz;
                float playerCircle = 1 - saturate(invLerp(1, 2, length(distFromWorldPosToPlayer))); // circle on player position
                v.vertex = lerp(v.vertex, float4(v.vertex.x, v.vertex.y - playerCircle * 0.7, v.vertex.z, 1), v.uv.y);
    
                
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.disturbance = abs(disturbance.y);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // draw pixel-wide grass
                float pixelWidth = fwidth( i.uv.x ) ; // uv change width in the x direction
                float recenteredUV = i.uv.x * 2 - 1; // recenter uv from [0,1] to [-1, 1]
                float grassWidth = pixelWidth * (1 - i.uv.y); // grass gets thinner above
                float thinLineMask = abs( recenteredUV ) < (grassWidth * _GrassWidth); // only select the desired width
                clip(thinLineMask - 0.5); // clip everything else
                
                float4 grass = float4(_GrassColor.xyz * (i.uv.y + 0.5), 1); // apply color
                float4 crushedGrass = lerp(grass, float4(0, 0, 0, 1), i.disturbance * 1.2); //apply darkness based on wind disturbance
                return crushedGrass;
            }
            ENDCG
        }
    }
}
