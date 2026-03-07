#version 300 es

// --- Vertex Input Attributes ---
layout (location = 0) in vec3 aPos;
layout (location = 1) in float aPhase;
layout (location = 2) in vec3 aNormal;

// --- Uniform Variables ---
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float time;

// --- Effect Parameters ---
uniform float oscill_amp;
uniform float oscill_freq;
uniform float wave_freq;
uniform float wave_amp;
uniform float twist_amp;
uniform float pulse_amp;
uniform float noise_amp;
uniform float sphere_scale;

// --- Audio Reactivity ---
uniform float audio_bass;
uniform float audio_mid;
uniform float audio_treble;

// --- Output Variables ---
out vec3 FragPos;
out vec3 Normal;
out float Phase;

// --- Procedural Noise Functions ---
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
                   mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

void main()
{
    vec3 scaledPos = aPos * sphere_scale;
    
    // Calculate deformations
    float pulse_effect = sin(time * 0.8) * (pulse_amp + audio_bass * 2.0);
    float wave_effect = sin(length(scaledPos) * wave_freq + time * 2.0) * (wave_amp + audio_mid * 0.5);
    float noise_effect = noise(scaledPos * 3.0 + time * 0.5) * (noise_amp + audio_treble * 0.8);
    float base_oscillation = sin(aPhase + time * oscill_freq) * oscill_amp;
    float twist = sin(scaledPos.y * 5.0 + time * 1.5) * twist_amp;
    
    float total_displacement = base_oscillation + wave_effect + twist + pulse_effect + noise_effect;
    vec3 displacedPos = scaledPos + aNormal * total_displacement;
    
    // --- Dot Size Logic ---
    // Sets the pixel size of the dots, reactive to treble
    gl_PointSize = 6.0 + (audio_treble * 12.0); 

    FragPos = vec3(model * vec4(displacedPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;
    Phase = aPhase;
    
    gl_Position = projection * view * model * vec4(displacedPos, 1.0);
}