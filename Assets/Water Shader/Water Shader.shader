Shader "Custom/Water Shader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0

        _WaveHeight("Wave Height", Range(0,1)) = 0.1
        _WaveSpeed("Wave Speed", Range(0,2)) = 1.0
        
        _FresnelPower("Fresnel Power", Range(1,5)) = 2.0
        _FresnelIntensity("Fresnel Intensity", Range(0,1)) = 0.6

        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimIntensity("Rim Intensity", Range(0,1)) = 0.5
        _RimPower("Rim Power", Range(1,6)) = 3.0

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
        SubShader
    {
        //
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
        //
        LOD 200

        //
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 viewDir;
        };

        //
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        half _WaveHeight;
        half _WaveSpeed;

        half _FresnelPower;
        half _FresnelIntensity;
        
        fixed4 _RimColor;
        half _RimIntensity;
        half _RimPower;


            // Gerstner Wave Variables for five waves
            half _Amplitude1, _Amplitude2, _Amplitude3, _Amplitude4, _Amplitude5;
            half _Frequency1, _Frequency2, _Frequency3, _Frequency4, _Frequency5;
            half _Phase1, _Phase2, _Phase3, _Phase4, _Phase5;
            half _Speed1, _Speed2, _Speed3, _Speed4, _Speed5;

            fixed2 GerstnerWave(fixed2 position, fixed2 direction, half amplitude, half frequency, half phase, half speed)
            {
                fixed2 result;
                float wave = 1.0 * speed + frequency * dot(direction, position) + phase;
                result.x = direction.x * amplitude * sin(wave);
                result.y = amplitude * cos(wave);
                return result;
            }
            //Calculates Rim Lighting, a shading technique to add glow on the edges of a surface when viewed at grazing angles.
            fixed3 RimLighting(float3 viewDir, float3 normal)
            {
                // Calculate the angle between the view direction and the surface normal.
                // 'dot' product returns 1 if the vectors are identical, and -1 if they are opposite. 
                half rim = 1.0 - saturate(dot(normalize(viewDir), normal));
                
                // Apply a power function to increase the contrast of the rim effect and scale it by the intensity.
                // 'pow' raises the 'rim' value to the power of '_RimPower', which sharpens or spreads the rim lighting.
                rim = _RimIntensity * pow(rim, _RimPower);
                
                // Multiply the calculated rim value with the defined rim color.
                // This gives the final color contribution of the rim lighting to the shader's output.
                return rim * _RimColor.rgb;
            }

            // Function to adjust a wave's amplitude based on the direction of another wave, 
            // then computes the GerstnerWave with the adjusted amplitude.
            fixed2 AdjustedWave(
                fixed2 position,        // The position to evaluate the wave.
                fixed2 direction1,      // The primary direction of the wave we're adjusting.
                fixed2 direction2,      // The direction of the second wave, which affects the amplitude of the primary wave.
                half amplitude1,        // The amplitude of the primary wave.
                half amplitude2,        // The amplitude of the second wave.
                half frequency1,        // The frequency of the primary wave.
                half phase1,            // The phase of the primary wave.
                half speed1             // The speed of the primary wave.
            )
            {
                // Calculate the dot product between normalized directions of the two waves.
                // This helps in understanding the angle between the two wave directions.
                half dotResult = dot(normalize(direction1), normalize(direction2));

                // If the dot product is positive, it means the angles between the directions are less than 90 degrees, 
                // indicating that the waves are somewhat aligned in the same general direction.
                if (dotResult > 0)
                {
                    // Increase the amplitude of the primary wave based on the second wave's amplitude 
                    // and the dot product result (how aligned they are).
                    amplitude1 += amplitude2 * dotResult;
                }
                else
                {
                    // If the dot product is negative, it means the waves are going in opposing directions. 
                    // Decrease the amplitude of the primary wave based on the second wave's amplitude 
                    // and the magnitude of the dot product result.
                    amplitude1 -= amplitude2 * dotResult;
                }

                // Call the GerstnerWave function to get the resulting wave displacement 
                // for the adjusted primary wave.
                return GerstnerWave(position, direction1, amplitude1, frequency1, phase1, speed1);
            }

            // Function to enhance the UV coordinates, making them vary based on waves and other distortions.
            fixed2 EnhancedUV(fixed2 uv, fixed3 worldPos)
            {
                // Initialize distortion as a zero vector.
                fixed2 distortion = float2(0, 0);

                // Adjust the UV distortion based on the first wave, taking the second wave's direction into account.
                // This uses the AdjustedWave function which modifies the amplitude of the primary wave based on the direction of a secondary wave.
                distortion += AdjustedWave(
                    worldPos.xz,                      // The world position on the xz plane.
                    float2(1, 0.5) * sin(0.25),       // Primary wave direction (adjusted by a sine function).
                    float2(0.7, 1.3) * sin(_Time.y * 0.35), // Secondary wave direction.
                    _Amplitude1, _Amplitude2, _Frequency1, _Phase1, _Speed1 // Properties of the primary wave.
                );

                // Adjust the UV distortion based on the second wave, this time taking the first wave's direction into account.
                distortion += AdjustedWave(
                    worldPos.xz,
                    float2(0.7, 1.3) * sin(0.35),
                    float2(1, 0.5) * sin(_Time.y * 0.25), // This time, the roles of the primary and secondary waves are swapped.
                    _Amplitude2, _Amplitude1, _Frequency2, _Phase2, _Speed2
                );

                // Add some periodic distortion based on world position and a wave speed. This provides some additional variation to the UV distortion.
                distortion.x += sin(worldPos.x + 1.0 * _WaveSpeed) * 0.02;
                distortion.y += cos(worldPos.z + 1.0 * _WaveSpeed) * 0.02;

                // Apply the distortion to the input UV, scaling the distortion to reduce its intensity.
                uv = uv + distortion * 0.005;

                // Ensure that the UV coordinates stay within a valid range [0, 1]. This prevents any out-of-bounds sampling.
                uv = clamp(uv, 0, 1);

                return uv; // Return the enhanced UV coordinates.
            }

            // Function to compute the normal direction based on wave offsets.
            // A normal direction indicates how light should reflect off the surface.
            fixed3 ComputeNormal(fixed3 worldPos)
            {
                // Calculate wave offset for the given world position using the GerstnerWave function.
                // Each of these offsets represents how much the wave pushes the surface in the XZ plane.
                fixed2 waveOffset1 = GerstnerWave(worldPos.xz, float2(1, 0.5) * sin(_Time.y * 0.2), _Amplitude1, _Frequency1, _Phase1, _Speed1);
                fixed2 waveOffset2 = GerstnerWave(worldPos.xz, float2(0.7, 1.3) * sin(_Time.y * 0.3), _Amplitude2, _Frequency2, _Phase2, _Speed2);
                fixed2 waveOffset3 = GerstnerWave(worldPos.xz, float2(-0.6, 0.8) * sin(_Time.y * 0.4), _Amplitude3, _Frequency3, _Phase3, _Speed3);
                fixed2 waveOffset4 = GerstnerWave(worldPos.xz, float2(0.9, -0.5) * sin(_Time.y * 0.5), _Amplitude4, _Frequency4, _Phase4, _Speed4);
                fixed2 waveOffset5 = GerstnerWave(worldPos.xz, float2(-0.8, -0.6) * sin(_Time.y * 0.6), _Amplitude5, _Frequency5, _Phase5, _Speed5);

                fixed3 normal;
                // For the normal's x-component, sum up the x-components of the first three wave offsets.
                // This creates a combined effect of the waves on the x direction.
                normal.x = waveOffset1.x + waveOffset2.x + waveOffset3.x;

                // Set the y-component of the normal to 1. This means that, by default, the normal direction points directly upwards.
                normal.y = 1;

                // For the normal's z-component, sum up the y-components of the first three wave offsets.
                // This combines the wave effects on the z direction.
                normal.z = waveOffset1.y + waveOffset2.y + waveOffset3.y;

                // Normalizing the normal vector. This ensures that the vector has a length of 1 and represents a direction.
                return normalize(normal);
            }

            // The surf function is responsible for computing the visual properties of a surface in Unity's standard shader model.
            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                // Adjust the UV coordinates based on the provided EnhancedUV function. This function might apply some wave-based distortion or other effects to the UV.
                fixed2 uv = EnhancedUV(IN.uv_MainTex, IN.worldPos);

                // Sample the main texture at the adjusted UV coordinates and multiply it by a color value.
                fixed4 c = tex2D(_MainTex, uv) * _Color;

                // Calculate the Fresnel effect. This effect describes how the surface appears shinier as the view angle becomes more oblique.
                // The Fresnel term increases when the view direction and the normal are perpendicular.
                half fresnel = pow(1.0 - dot(normalize(IN.viewDir), ComputeNormal(IN.worldPos)), _FresnelPower);

                // Compute the surface normal based on the world position. This may incorporate wave effects or other displacements.
                fixed3 normal = ComputeNormal(IN.worldPos);

                // Calculate the rim lighting effect. Rim lighting highlights the edges of an object, making them appear to glow.
                fixed3 rimEffect = RimLighting(IN.viewDir, normal);

                // Blend the texture color with the Fresnel effect and the rim lighting. 
                // The `lerp` function linearly interpolates between the texture color and the Fresnel-modified color based on the Fresnel term.
                o.Albedo = lerp(c.rgb, _Color.rgb * _FresnelIntensity + rimEffect, fresnel);
                // Assign metallic property to the surface. This controls how "metal-like" the surface appears.
                o.Metallic = _Metallic;
                // Assign smoothness (or glossiness) to the surface. This controls how sharp or blurry reflections appear on the surface.
                o.Smoothness = _Glossiness;
                // Assign the alpha value (transparency) from the sampled texture.
                o.Alpha = c.a;

                // Assign the computed normal to the surface. This affects how light interacts with the surface.
                o.Normal = normal;
            }
            ENDCG
    }
                FallBack "Diffuse"
}