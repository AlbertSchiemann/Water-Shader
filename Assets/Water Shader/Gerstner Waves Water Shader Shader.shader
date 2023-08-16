Shader "Custom/Gerstner Waves Water Shader"
{
    // Properties block contains all the editable parameters exposed in the material editor
    Properties
    {
        // Basic properties
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        
        //Freshnel Effect
        _FresnelPower("Fresnel Power", Range(1,5)) = 2.0
        _FresnelIntensity("Fresnel Intensity", Range(0,1)) = 0.6

            // Gerstner Wave Properties for five waves
            _Amplitude1("Wave 1 Amplitude", Range(0, 2)) = 0.5
            _Frequency1("Wave 1 Frequency", Range(0, 5)) = 2.0
            _Phase1("Wave 1 Phase", Range(0, 6.28)) = 1.0
            _Speed1("Wave 1 Speed", Range(0, 2)) = 1.2

            _Amplitude2("Wave 2 Amplitude", Range(0, 2)) = 0.35
            _Frequency2("Wave 2 Frequency", Range(0, 5)) = 2.5
            _Phase2("Wave 2 Phase", Range(0, 6.28)) = 2.0
            _Speed2("Wave 2 Speed", Range(0, 2)) = 1.3

            _Amplitude3("Wave 3 Amplitude", Range(0, 2)) = 0.45
            _Frequency3("Wave 3 Frequency", Range(0, 5)) = 3.0
            _Phase3("Wave 3 Phase", Range(0, 6.28)) = 0.5
            _Speed3("Wave 3 Speed", Range(0, 2)) = 1.5

            _Amplitude4("Wave 4 Amplitude", Range(0, 2)) = 0.3
            _Frequency4("Wave 4 Frequency", Range(0, 5)) = 3.0
            _Phase4("Wave 4 Phase", Range(0, 6.28)) = 0.5
            _Speed4("Wave 4 Speed", Range(0, 2)) = 1.5

            _Amplitude5("Wave 5 Amplitude", Range(0, 2)) = 0.4
            _Frequency5("Wave 5 Frequency", Range(0, 5)) = 2.8
            _Phase5("Wave 5 Phase", Range(0, 6.28)) = 1.8
            _Speed5("Wave 5 Speed", Range(0, 2)) = 1.4
    }

        // A SubShader is a collection of passes. Unity uses the first SubShader that runs on the user's graphics card.
        SubShader
        {
            // These tags make the shader render as transparent, ensuring that objects behind it are rendered.
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
            // Level of Detail - If the camera is far from the object, a simpler version of the shader might be used for optimization.
            // A value of 200 suggests a moderately complex shader.
            LOD 200

            // Start of the shader program written in CG/HLSL language.
            CGPROGRAM
            // This tells Unity to use the "surf" function for surface shaders. 
            // "Standard" is the lighting model and "fullforwardshadows" enables shadows on transparent objects.
            #pragma surface surf Standard fullforwardshadows
            // The shader is intended to be run on hardware that supports Shader Model 3.0.
            #pragma target 3.0

            // Texture sampler for the main texture (_MainTex) that the material will use.
            sampler2D _MainTex;

            // Input struct defines the data that will be available in the surf function.
            struct Input
            {
                float2 uv_MainTex; // UV coordinates for the main texture.
                float3 worldPos;  // World position of the current pixel/vertex.
                float3 viewDir; // Direction from the camera to the current pixel/vertex.
            };

            //half is a 16 - bit floating point number
            half _Glossiness;
            half _Metallic;
            //fixed is a lower precision alternative to float
            fixed4 _Color;
            half _FresnelPower;
            half _FresnelIntensity;

            // Gerstner Wave Variables for five waves
            
            //The height or strength of the wave.
            half _Amplitude1, _Amplitude2, _Amplitude3, _Amplitude4, _Amplitude5;

            //The number of oscillations(cycles) of a wave that occur in a unit distance.
            half _Frequency1, _Frequency2, _Frequency3, _Frequency4, _Frequency5;

            //The horizontal offset or shift of a wave.It's used to adjust where a wave starts its cycle.
            half _Phase1, _Phase2, _Phase3, _Phase4, _Phase5;

            //The rate at which the wave pattern moves over time
            half _Speed1, _Speed2, _Speed3, _Speed4, _Speed5;

            fixed2 GerstnerWave(fixed2 position, fixed2 direction, half amplitude, half frequency, half phase, half speed)
            {
                // Initialize a 2D vector to store the wave displacement results
                fixed2 result;

                // Calculate the wave's current position based on time, speed, frequency, direction, and phase
                // _Time.y gets the current time, which makes the wave change over time.
                // The resulting 'wave' value determines the phase of the wave at the given position.
                float wave = _Time.y * speed + frequency * dot(direction, position) + phase;
                
                // Calculate the horizontal displacement of the wave (along the X-axis)
                // The sin function is used to get the oscillating behavior of the wave.
                result.x = direction.x * amplitude * sin(wave);
                
                // Calculate the vertical displacement of the wave (along the Y-axis)
                // The cos function is used to get the oscillating behavior, but it's 90 degrees out of phase with sin, 
                // creating the up and down movement of the wave crest and trough.
                result.y = amplitude * cos(wave);
                
                // Return the calculated wave displacements
                return result;
            }

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                // Combining multiple Gerstner Waves for a complex and realistic water surface
                // Starting with the current world position of the fragment/pixel being rendered
                fixed3 finalWavePosition = IN.worldPos;

                // Calculate the displacement for the first Gerstner wave and add it to the final wave position.
                // The direction and randomness of the wave are determined using the sin function and time.
                finalWavePosition.xy += GerstnerWave(IN.worldPos.xz, float2(1, 0.5) * sin(_Time.y * 0.2), _Amplitude1, _Frequency1, _Phase1, _Speed1);
                finalWavePosition.xy += GerstnerWave(IN.worldPos.xz, float2(0.7, 1.3) * sin(_Time.y * 0.3), _Amplitude2, _Frequency2, _Phase2, _Speed2);
                finalWavePosition.xy += GerstnerWave(IN.worldPos.xz, float2(-0.6, 0.8) * sin(_Time.y * 0.4), _Amplitude3, _Frequency3, _Phase3, _Speed3);
                finalWavePosition.xy += GerstnerWave(IN.worldPos.xz, float2(0.9, -0.5) * sin(_Time.y * 0.5), _Amplitude4, _Frequency4, _Phase4, _Speed4);
                finalWavePosition.xy += GerstnerWave(IN.worldPos.xz, float2(-0.8, -0.6) * sin(_Time.y * 0.6), _Amplitude5, _Frequency5, _Phase5, _Speed5);

                // Update the UV coordinates based on the wave displacements.
                // The additional 0.01 multiplier allows for fine control over the UV distortion, preventing excessive stretching or squeezing.
                fixed2 uv = IN.uv_MainTex + finalWavePosition.xy * 0.01;
                fixed4 c = tex2D(_MainTex, uv) * _Color;
                //UV coordinates, often just called UVs, are a two - dimensional coordinate system used primarily in computer graphics 
                //to map a 2D image(usually referred to as a texture) onto a 3D model.

                // Calculate the Fresnel effect, which gives the appearance of reflectivity based on the view angle.
                // It provides a blending factor that's higher when looking at shallow angles (like the horizon) and lower when looking directly down.
                half fresnel = pow(1.0 - dot(normalize(IN.viewDir), o.Normal), _FresnelPower);
                
                // Blend the sampled color with the Fresnel effect to give the final albedo (surface) color.
                o.Albedo = lerp(c.rgb, _Color.rgb * _FresnelIntensity, fresnel);
                // Set the metallic and smoothness properties for the shader
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                // Assign the alpha value from the sampled texture
                o.Alpha = c.a;
                // Set the normal direction for the shader. It's mostly pointing upwards, but the Y component can vary based on the wave height.
                o.Normal = normalize(float3(0, 1, finalWavePosition.y));
            }
            ENDCG
        }
            // If the shader fails, it will fall back to a basic diffuse shader
            FallBack "Diffuse"
}
