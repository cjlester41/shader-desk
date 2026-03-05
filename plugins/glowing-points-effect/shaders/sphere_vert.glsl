#version 300 es
layout (location = 0) in vec3 aPos;
layout (location = 1) in float aPhase;
layout (location = 2) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float time;

// @param sphere_scale | float | 1.0 | Global scale of the sphere [cite: 28]
uniform float sphere_scale;
// @param point_size | float | 10.0 | Base size of the glowing points
uniform float point_size;
// @param audio_bass | float | 0.0 | Bass reactivity for point pulsing [cite: 30]
uniform float audio_bass;

out float vPhase;

void main() {
    // Apply scaling and pass phase to fragment shader [cite: 42, 56]
    vec3 displacedPos = aPos * sphere_scale;
    vPhase = aPhase;

    // Calculate final screen position 
    gl_Position = projection * view * model * vec4(displacedPos, 1.0);

    // Set the diameter of the points, reactive to bass
    gl_PointSize = point_size + (audio_bass * 20.0);
}