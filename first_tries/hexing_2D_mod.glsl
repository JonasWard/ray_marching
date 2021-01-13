float hex(in vec2 p){
    const float hexSize = .5;
    const vec2 s = vec2(1, 1.7320508);
    
    p = abs(p);
    return max(dot(p, s*.5), p.x) - hexSize;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    fragColor.r = smoothstep(.01, 0., hex(uv));
}