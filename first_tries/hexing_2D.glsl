const vec2 s = vec2(1, 1.7320508); // 1.7320508 = sqrt(3)

vec3 hue( float c )
{
    return smoothstep(0.,1., abs(mod(c*6.+vec3(0,4,2), 6.)-3.)-1.);
}

float random(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// xy - offset from nearest hex center
// zw - unique ID of hexagon
vec4 calcHexInfo(vec2 uv)
{
    vec4 hexCenter = round(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? vec4(offset.xy, hexCenter.xy) : vec4(offset.zw, hexCenter.zw);
}

float calcHexDistance(vec2 uv) {
    vec4 hexCenter = round(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return sqrt(min(dot(offset.xy, offset.xy), dot(offset.zw, offset.zw)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    const float tileAmount = 3.;
    vec4 hexInfo = calcHexInfo(uv * tileAmount);
    fragColor.rgb = hue(random(hexInfo.zw));
}