// Gyroid Marching

#define MAX_STEPS 500
#define MAX_DIST 10000.
#define SURF_DIST .01

# define GLOBALSCALE 20.

# define PI 3.1415
# define TAU 6.283185
# define SCALE 5.0
# define THICKNESS 1.0
# define TIMESCALE .2
# define SESCALE 25.
# define TERCALE 2.
// # define SPHERERAD 10.0
# define BOXSIZE .5
# define BANDHEIGHT .02
# define DOUBLEBH .04
# define SQUAREBH .0004

# define SPHERESPACING 6.283185

const float d2mid = 3.;
const float recSpacing = 5.;
const vec3 circle = vec3(0., d2mid + .5*recSpacing, sqrt( d2mid * d2mid + recSpacing * recSpacing * .25));
// const vec3 circle = vec3(0., d2mid - .5 * recSpacing, sqrt( d2mid * d2mid));

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float sdPlane(vec3 p){
    vec4 n = vec4(0, 0, 1, -.1);
    return dot(p,n.xyz) + n.w;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = clamp(.5  + .5 * (b - a) / k, .0, 1.);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdCircle(vec2 p) {
    return length(circle.xy - p) - circle.z;
}

float sdSphere(vec3 p) {
    vec3 center = vec3(0);
    float radius = BOXSIZE;
    return length( (p - center) ) - radius;
}

vec2 recMod(vec2 p) {
    return mod(p, recSpacing) - recSpacing * .5;
}

vec2 recModAlternating(vec2 p) {
    vec2 modVec = mod(p, recSpacing);
    vec2 cell = mod( (p - modVec) / recSpacing, 2.0) * 2.0 - 1.0;
    float multiplier = cell.x * cell.y; // * cell.y;
    vec2 temp = vec2(modVec.xy - recSpacing * .5);
    // return temp;
    return multiplier * temp; // - SPHERESPACING * .5;
}

vec3 boxMod(vec3 p){
    return mod(vec3(p), SPHERESPACING) - SPHERESPACING * .5;
}

vec3 boxModAlternating(vec3 p){
    vec3 modVec = mod(p, SPHERESPACING);
    vec3 cell = mod( (p - modVec) / SPHERESPACING, 2.0) * 2.0 - 1.0;
    float multiplier = cell.x * cell.y;
    vec3 temp = vec3(modVec.xy - SPHERESPACING * .5, modVec.z);
    // return temp;
    return vec3(multiplier * (temp.xy), temp.z); // - SPHERESPACING * .5;
}

float sdModSphere(vec3 p){
    return sdSphere(boxMod(p) );
}

float sdWave(vec3 inputP) {
    vec2 p = inputP.xy;
    vec2 modVec = mod(p, recSpacing);
    vec2 cell = mod( (p - modVec) / recSpacing, 2.0) * 2.0 - 1.0;
    float multiplier = cell.x; // * cell.y;
    vec2 temp = vec2(modVec.xy - recSpacing * .5);
    // return temp;
    temp *= multiplier; // - SPHERESPACING * .5;
    return multiplier * sdCircle(temp) * cell.x * cell.y;
}

float GetDist(vec3 p) {
    // float t = iTime;

    // float d_g = SCALE * sdGyroid(p, SESCALE * sdGyroid(p, sdGyroid(p, TERCALE)));
    // float d_s = sdModSphere(p);
    // float d_b = sdBands(p);
    float d_p = sdPlane(p);
    float d_rec = sdCircle(recModAlternating(p.xy));
    // float d_s = sdCylinder(p);
    // float d_s = sdSphere(p);
    // intersection
    // float d = max(d_p, d_g);
    // float d = max(d_s, d_g) + d_b;
    // bumping
    // float d = d_s + .4 * d_g + d_b;
    // float d = d_s + .4 * d_g;
    // float d = sdGyroid(p);
    // float d = max(d_rec, d_p);
    float d = sdWave(p);

    return d;
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
    vec2 uv = fragCoord.xy * GLOBALSCALE / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    vec3 p = vec3(uv, 0.);

    float ds = GetDist(p) * SCALE;
    vec3 n = GetNormal(p);

    // float ds = abs(dot(sin(p), cos(p.yzx) ) );

    fragColor = vec4(vec3(n),1.);
}