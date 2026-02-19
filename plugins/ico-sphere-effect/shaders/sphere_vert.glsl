// Use GLSL ES version 300 (OpenGL for Embedded Systems), 
// which is used in WebGL 2 and mobile devices.
#version 300 es

// --- Vertex Input Attributes ---
// These data points are read for each vertex from buffers defined in C++.
// layout (location = ...) links the attribute to a specific index.

// (location = 0): Vertex position in local model coordinates.
layout (location = 0) in vec3 aPos;
// (location = 1): Unique phase value for each vertex, 
// used to create individual oscillation animations.
layout (location = 1) in float aPhase;
// (location = 2): Normal vector for the vertex. It points "outward" from the 
// surface and is used to determine the direction of displacement.
layout (location = 2) in vec3 aNormal;


// --- Uniform Variables ---
// Global variables passed from C++ code that remain constant for all vertices.

// Standard matrices for coordinate transformations.
uniform mat4 model;      // Local coordinates to world coordinates.
uniform mat4 view;       // World coordinates to camera coordinates.
uniform mat4 projection; // Camera coordinates to screen projection.

// Time variable for animation.
uniform float time;

// --- Effect Parameters from Configuration File ---
// @param oscill_amp | float | 0.0 | Base oscillation amplitude.
uniform float oscill_amp;
// @param oscill_freq | float | 1.0 | Base oscillation frequency.
uniform float oscill_freq;
// @param wave_amp | float | 0.0 | Wave effect amplitude.
uniform float wave_freq;
// @param wave_freq | float | 10.0 | Frequency (density) of waves on the surface.
uniform float wave_amp;
// @param twist_amp | float | 0.0 | Strength of the twisting effect.
uniform float twist_amp;
// @param pulse_amp | float | 0.0 | Base pulsation amplitude.
uniform float pulse_amp;
// @param noise_amp | float | 0.0 | Noise deformation amplitude.
uniform float noise_amp;
// @param sphere_scale | float | 1.0 | Global scale of the sphere.
uniform float sphere_scale;

// --- Uniform Variables for Audio Reactivity ---
// These values (from 0.0 to 1.0) are passed from the audio analyzer.
// @param audio_bass | float | 0.0 | Current bass level.
uniform float audio_bass;
// @param audio_mid | float | 0.0 | Current mid-frequency level.
uniform float audio_mid;
// @param audio_treble | float | 0.0 | Current treble level.
uniform float audio_treble;


// --- Output Variables (Passed to the Fragment Shader) ---
out vec3 FragPos; // Vertex position in world coordinates for lighting calculations.
out vec3 Normal;  // Transformed normal for lighting calculations.
out float Phase;   // Pass phase forward if needed for fragment processing.


// --- Procedural Noise Functions ---

// Simple hash function to generate pseudo-random numbers.
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// 3D Noise creating smooth, natural random patterns.
// It uses interpolation between hash function values.
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f); // Smoothing for interpolation
    float n = p.x + p.y * 157.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
                   mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}


// --- Main Shader Function, executed for every vertex ---
void main()
{
    // Apply the initial scale to the vertex position.
    vec3 scaledPos = aPos * sphere_scale;
    
    // --- Calculate each deformation effect ---
    // We combine the base amplitude from config with the influence of audio data.

    // 1. Pulsation Effect: creates overall expansion and contraction of the sphere.
    // Enhanced by bass to create "beats".
    float pulse_effect = sin(time * 0.8) * (pulse_amp + audio_bass * 2.0);

    // 2. Wave Effect: creates concentric waves on the surface.
    // Mid-frequencies add small ripples to the main waves.
    float wave_effect = sin(length(scaledPos) * wave_freq + time * 2.0) * (wave_amp + audio_mid * 0.5);

    // 3. Noise Effect: adds chaotic, organic deformation.
    // Treble frequencies create high-frequency "jitter" on the surface.
    float noise_effect = noise(scaledPos * 3.0 + time * 0.5) * (noise_amp + audio_treble * 0.8);
    
    // 4. Other effects independent of audio.
    // Base Oscillation: each vertex moves in a sine wave based on its own phase.
    float base_oscillation = sin(aPhase + time * oscill_freq) * oscill_amp;
    // Twisting: shifts vertices horizontally depending on their height (Y).
    float twist = sin(scaledPos.y * 5.0 + time * 1.5) * twist_amp;

    // --- Sum all displacements into a single value ---
    float total_displacement = base_oscillation + wave_effect + twist + pulse_effect + noise_effect;
    
    // --- Apply the final displacement ---
    // Offset the vertex position along its normal by the calculated amount.
    vec3 displacedPos = scaledPos + aNormal * total_displacement;
    
    // --- Final transformations and output ---
    
    // Transform the displaced position into world coordinates and pass to fragment shader.
    FragPos = vec3(model * vec4(displacedPos, 1.0));
    
    // Correctly transform the normal for lighting (important for non-uniform scaling).
    Normal = mat3(transpose(inverse(model))) * aNormal;
    
    // Simply pass the phase forward.
    Phase = aPhase;
    
    // Mandatory output: calculate final vertex position on the screen.
    gl_Position = projection * view * model * vec4(displacedPos, 1.0);
}