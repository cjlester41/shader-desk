#version 300 es
precision mediump float;

in vec3 FragPos;
in vec3 Normal;
in float Phase;

uniform vec3 wireframe_color;
uniform bool is_wireframe_pass;
uniform bool is_point_pass; // Toggle this when drawing GL_POINTS

// Lighting Uniforms
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos;

out vec4 FragColor;

void main()
{
    if (is_point_pass) {
        // Create a circular mask
        vec2 uv = gl_PointCoord - vec2(0.5);
        float dist = dot(uv, uv);
        if (dist > 0.25) {
            discard; // Make the square point a circle
        }
        
        // Optional: simple anti-aliasing for the dot edges
        float alpha = 1.0 - smoothstep(0.20, 0.25, dist);
        FragColor = vec4(wireframe_color, alpha);
        
    } else if (is_wireframe_pass) {
        FragColor = vec4(wireframe_color, 1.0);
        
    } else {
        // Standard Surface Lighting
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos - FragPos);
        
        float ambientStrength = 0.3;
        vec3 ambient = ambientStrength * lightColor;
        
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = diff * lightColor;
        
        float specularStrength = 0.5;
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);  
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
        vec3 specular = specularStrength * spec * lightColor;
            
        vec3 result = (ambient + diffuse + specular);
        FragColor = vec4(result, 1.0);
    }
}