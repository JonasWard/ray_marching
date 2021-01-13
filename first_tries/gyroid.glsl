
# define PI 3.1415
# define SCALE 2.
# define TIMESCALE 10.
# define SESCALE 10.0
# define TERCALE 15.

float sdGyroid(in vec3 p, in float scale) {
    p *= scale * PI;
    float d = dot(sin(p), cos(p.yzx) );
	d += 3.0;
    d *= .166666666;

    return d;
}

float scaleFunction3(in vec3 p) {
    float loc_scale = TERCALE;
    float ds = sdGyroid(p, loc_scale);

    return ds;
}

float scaleFunction(in vec3 p) {
    float loc_scale = scaleFunction3(p) * SESCALE;
    // float loc_scale = SESCALE;
    float ds = sdGyroid(p, loc_scale);

    return ds;
}

float GetDist(vec3 p) {
    return scaleFunction(p);
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        abs(GetDist(p-e.xyy)),
        abs(GetDist(p-e.yxy)),
        abs(GetDist(p-e.yyx))
    );
    
    return normalize(n);
    // return abs(normalize(n) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    vec3 p = vec3(uv, iTime * TIMESCALE);

    float ds = GetDist(p) * SCALE;
    vec3 n = GetNormal(p);

    // float ds = abs(dot(sin(p), cos(p.yzx) ) );

    fragColor = vec4(vec3(n),1.);
}