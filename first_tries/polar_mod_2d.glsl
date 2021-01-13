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

float sdSphere(vec3 p) {
    vec3 center = vec3(0);
    float radius = BOXSIZE;
    return length( (p - center) ) - radius;
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

float sdBands(vec3 p) {
    float val = mod(p.y, DOUBLEBH);
    val -= BANDHEIGHT;
    val = sqrt(SQUAREBH - val * val);
    return -val;
}

float sdCylinder(vec3 p) {
    vec3 a = vec3(.0,.0,-BOXSIZE);
    vec3 b = vec3(.0,.0,BOXSIZE);
    float r = BOXSIZE * .5;

    vec3 ab = b - a;
    vec3 ap = p - a;

    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, .0, 1.);

    vec3 c = a * t * ab;

    float x = length(p-c) * r;
    float y = (abs(t - .5) - .5) * length(ab);
    float e = length(max (vec2(x, y), .0 ) );
    float i = min(max(x, y), .0);

    return e + i;
}

float sdBox(vec3 p) {
    // vec3 trans = vec3(BOXSIZE);
    vec3 size = vec3(BOXSIZE);

    p = abs(p) - size;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.0);
    // Assuming p is inside the cube, how far is it from the surface?
    // Result will be negative or zero.
    
    // Assuming p is outside the cube, how far is it from the surface?
    // Result will be positive or zero.
    // float outsideDistance = length(max(d, 0.0));
    
    // return insideDistance + outsideDistance;
}

// float sdSphere(vec3 p) {
//     vec4 s = vec4(10.0);
    
//     float sphereDist = length(p-s.xyz)-s.w;
//     float planeDist = p.y;
    
//     float d = min(sphereDist, planeDist);
//     return d;
// }

float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    // float d = abs(dot(sin(p), cos(p.yzx) ) + THICKNESS) ;
    // float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
    // d += 3.0;
    d *= .3333;
	return d;
}

vec3 polar2Dremap(vec3 p) {
    return vec3(
        sqrt(p.x * p.x + p.y * p.y),
        atan(p.y, p.x),
        p.z
    );
}

float sdGyroidPolar(vec3 p) {
    return sdGyroid(polar2Dremap(boxModAlternating(p) ),10.);
}

float GetDist(vec3 p) {
    // float t = iTime;

    // float d_g = SCALE * sdGyroid(p, SESCALE * sdGyroid(p, sdGyroid(p, TERCALE)));
    // float d_s = sdModSphere(p);
    // float d_b = sdBands(p);
    float d_p = sdPlane(p);
    // float d_s = sdCylinder(p);
    // float d_s = sdSphere(p);
    // intersection
    // float d = max(d_p, d_g);
    // float d = max(d_s, d_g) + d_b;
    // bumping
    // float d = d_s + .4 * d_g + d_b;
    // float d = d_s + .4 * d_g;
    // float d = sdGyroid(p);
    float d = max(sdGyroidPolar(p), d_p);

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

    vec3 p = vec3(uv, iTime * TIMESCALE);

    float ds = GetDist(p) * SCALE;
    vec3 n = GetNormal(p);

    // float ds = abs(dot(sin(p), cos(p.yzx) ) );

    fragColor = vec4(vec3(n),1.);
}