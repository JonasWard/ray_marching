void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    uv -= .5;
    float d = length(uv);
    float r = .3;

    float step = .002;
    float c = smoothstep(r - step, r + step, d);

    // if (d < .3) c = 1.0; else c = 0.;

    fragColor = vec4(vec3(c),1.);
}