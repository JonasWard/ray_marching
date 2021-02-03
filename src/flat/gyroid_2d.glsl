// Gyroid Marching
const float tau = 6.2831853072;
const float staticZ = 0.;

// function parameters
const float scaleGyroidA = .02;
const float scaleGyroidB = .5;


float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    d *= .3333;
	return d;
}

float GetDist(vec3 p) {
    // serialise as much as you want
    float d_g = sdGyroid(p, sdGyroid(p, scaleGyroidB * scaleGyroidA) );
    // float d_g = sdGyroid(p, scaleGyroidA);

    return d_g;
}

float GetDist(vec2 p) {
    return GetDist(vec3(p, staticZ));
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );
    
    return -normalize(n);
    // return abs(normalize(n) );
}

vec3 GetNormal(vec2 p) {
    return GetNormal(vec3(p, staticZ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy/ iResolution.xy;

    // vec3 col = vec3(GetNormal(fragCoord) );
    
    vec3 n = vec3(.5) - GetNormal(fragCoord) * .5;

    fragColor = vec4(n, 1.);
}