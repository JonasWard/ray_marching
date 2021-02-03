// Gyroid Marching
const float pi = 3.1415;
const float tau = 6.283185;

const float globalScale = 5.;
const float scale = 1.;
const float boxSize = 1.;
const float sphereSpacing = 1.;

const float d2mid = 0.5;
const float recSpacing = 1.;
const vec3 circle = vec3(0., d2mid + .5*recSpacing, sqrt( d2mid * d2mid + recSpacing * recSpacing * .25));

const vec3 black = vec3(0.);
const vec3 white = vec3(1.);
const vec3 red = vec3(.9, 0.1, .1);

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
    float radius = boxSize;
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
    return multiplier * temp; // - sphereSpacing * .5;
}

vec3 boxMod(vec3 p){
    return mod(vec3(p), sphereSpacing) - sphereSpacing * .5;
}

vec3 boxModAlternating(vec3 p){
    vec3 modVec = mod(p, sphereSpacing);
    vec3 cell = mod( (p - modVec) / sphereSpacing, 2.0) * 2.0 - 1.0;
    float multiplier = cell.x * cell.y;
    vec3 temp = vec3(modVec.xy - sphereSpacing * .5, modVec.z);
    // return temp;
    return vec3(multiplier * (temp.xy), temp.z); // - sphereSpacing * .5;
}

float sdModSphere(vec3 p){
    return sdSphere(boxMod(p) );
}

float sdWave(vec3 inputP) {
    vec2 p = inputP.xy;
    vec2 modVec = mod(p, recSpacing);
    vec2 cell = mod( (p - modVec) / recSpacing, 2.0) * 2.0 - 1.0;
    float multiplier = cell.x;
    vec2 temp = vec2(modVec.xy - recSpacing * .5);
    temp *= multiplier;
    return multiplier * sdCircle(temp) * cell.x * cell.y;
}

float GetDist(vec3 p) {
    float d = sdWave(p);
    return d;
}

vec4 colorFromDistance(float d) {
    vec3 color = mix(black,white,d * .5 + .5);
    return vec4(color, 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy * globalScale / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    vec3 p = vec3(uv, 0.);
    float d = GetDist(p);
    
    fragColor = colorFromDistance(d);

    if (d < 0.005 && d > -0.005) {
        fragColor = vec4(red, 1.);
    }
}