#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float saturation;
    float invertColors;
    float hue;          // degrees; 0 = no rotation
    float brightness;   // 1.0 = normal
    float contrast;     // 1.0 = normal
} ubuf;

layout(binding = 1) uniform sampler2D source;

// W3C CSS hue-rotate matrix (column-major for GLSL * vec3).
// All ops are linear, so they're valid in premultiplied-alpha space:
//   M * (rgb * a)  ==  (M * rgb) * a
mat3 hueRotateMatrix(float angleDeg)
{
    float a = radians(angleDeg);
    float c = cos(a);
    float s = sin(a);
    // Luma weights used by the W3C spec: R=0.213 G=0.715 B=0.072
    return mat3(
        // column 0 (applied to R)
        0.213 + c * 0.787 - s * 0.213,
        0.213 - c * 0.213 + s * 0.143,
        0.213 - c * 0.213 - s * 0.787,
        // column 1 (applied to G)
        0.715 - c * 0.715 - s * 0.715,
        0.715 + c * 0.285 + s * 0.140,
        0.715 - c * 0.715 + s * 0.715,
        // column 2 (applied to B)
        0.072 - c * 0.072 + s * 0.928,
        0.072 - c * 0.072 - s * 0.283,
        0.072 + c * 0.928 + s * 0.072
    );
}

void main()
{
    vec4 c = texture(source, qt_TexCoord0);

    // Hue rotation — linear transform, safe in premultiplied space.
    c.rgb = clamp(hueRotateMatrix(ubuf.hue) * c.rgb, 0.0, c.a);

    // Saturation — luma-based mix in premultiplied space:
    //   mix(luma*a, rgb*a, sat) == (mix(luma, rgb, sat)) * a  ✓
    float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    c.rgb = mix(vec3(luma), c.rgb, ubuf.saturation);

    // Brightness — uniform scale, trivially valid in premultiplied space.
    c.rgb *= ubuf.brightness;

    // Contrast — scale around the 0.5 midpoint of actual (un-premultiplied) value.
    // Derived without division:
    //   premult_new = premult * contrast + alpha * 0.5 * (1 - contrast)
    c.rgb = c.rgb * ubuf.contrast + c.a * 0.5 * (1.0 - ubuf.contrast);

    c.rgb = clamp(c.rgb, 0.0, c.a);

    // Invert — applied last so the other adjustments feel natural.
    if (ubuf.invertColors > 0.5)
        c.rgb = vec3(c.a) - c.rgb;

    fragColor = c * ubuf.qt_Opacity;
}
