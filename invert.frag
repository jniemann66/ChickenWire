#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

void main()
{
    vec4 c = texture(source, qt_TexCoord0);
    // Layer textures use premultiplied alpha, so RGB is already scaled by alpha.
    // Invert the colour while preserving alpha: (1 - actual) * a = a - (actual * a)
    fragColor = vec4(vec3(c.a) - c.rgb, c.a);
}
