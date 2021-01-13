const float pi_invert = 0.3183098862;
const float scale = .31415926536 * 10.;
const float doubleScale = scale * 2.0;
const float fluxScale = scale;

const vec2 cellVec = vec2(doubleScale);
const vec2 cellCenter = vec2(scale);

const float pi = 3.1415926536;

vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

void forceDeuToCharge(vec2 p, vec2 charge, float magnitude, out vec2 addition) {
    vec2 pDelta = p - charge;
    addition += magnitude * pDelta / length(pDelta);
}

vec2 fluxFunction(vec2 p) {
    p /= scale * 2.;

    vec2 pA = vec2 (-1, 0.);
    vec2 pB = vec2 (0, -1);
    vec2 pC = vec2 (1, 0);
    vec2 pD = vec2 (0, 1);

    vec2 td = vec2(0.);
    forceDeuToCharge(p, pA, 1., td);
    forceDeuToCharge(p, pB, -1., td);
    forceDeuToCharge(p, pC, 1., td);
    forceDeuToCharge(p, pD, -1., td);

    return td;
}

float invertAngle(float angle, float direction) {
    return mod(pi + direction * angle, pi);
}

vec2 fluxToPolar(vec2 p, float direction) {
    vec2 td = fluxFunction(p);
    float angle = invertAngle(atan(td.y, td.x), direction);
    float magnitude = length(td) * .71;

    if (magnitude < 1.0) {
        if (magnitude > 0.0) {
            magnitude = magnitude;
        } else {
            magnitude = 0.0;
        }
    } else {
        magnitude = 1.0;
    }

    return vec2(angle, magnitude * fluxScale);
}

vec2 uvMod(vec2 p, out float direction){
    vec2 modVec = mod(p, cellVec) - cellCenter;

    vec2 cellIdx = mod( (p - cellCenter - modVec) / doubleScale, 2.0) * 2.0 - 1.0;
    direction = cellIdx.x*cellIdx.y;

    return modVec;
}

// Gyroid Marching

#define MAX_STEPS 500
#define MAX_DIST 10000.
#define SURF_DIST .0001

# define PI 3.1415926536
# define TAU 6.283185
# define SCALE .2
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

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdPlane(vec3 p){
    vec4 n = vec4(0, 0, 1, -.1);
    return dot(p,n.xyz) + n.w;
}

vec3 magFluxRemapping(vec3 p) {
    float direction = 1.0;
    vec2 polar = uvMod(p.xy, direction);
    vec2 fluxVec = fluxToPolar(polar, direction);
    return vec3(fluxVec, p.z);
}

float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    // float d = abs(dot(sin(p), cos(p.yzx) ) + THICKNESS) ;
    // float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
    // d += 3.0;
    d *= .3333;
	return d;
}

float sdGyroidPolar(vec3 p) {
    return sdGyroid(magFluxRemapping(p),10.);
}

float GetDist(vec3 p) {
    float d_p = sdPlane(p);
    float d = 0.0;
    // d = max(sdGyroidPolar(p), d_p);
    if (d_p < 0.001) {
        d = max(sdGyroidPolar(p), d_p);
    } else {
        d = d_p;
    }

    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p) * .1;
        d0 += dS;

        if (d0 > MAX_DIST || dS < SURF_DIST) break;
    }

    return d0;
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

vec3 R(vec2 uv, vec3 p, vec3 l, float z, vec3 up) {
    vec3 f = normalize(l-p),
        r = normalize(cross(up, f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0,0,0);
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot(n, l) * .5 + .5, .0, 1.);
    float d = RayMarch(p + n * SURF_DIST * 2., l);
    if (p.y < .01 && d < length(lightPos - p)) dif *= .5;

    return dif;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
        r = normalize(cross(vec3(0, 1, 0), f)),
        u = cross(f, r),
        c = p + f * z,
        i = c + uv.x * r + uv.y * u,
        d = normalize(i - p);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy/ iResolution.xy;

    // vec3 col = vec3(GetNormal(fragCoord) );

    vec3 ro = vec3(10., 0, 0.);
    ro.yz *= Rot(-m.y + .4);
    ro.xz *= Rot(5.3 + m.x * TAU);

    vec3 rd = R(uv, ro, vec3(0), .58);

    float d = RayMarch(ro, rd);
    vec3 p = ro + d*rd;
    
    vec3 n = vec3(.5) - GetNormal(p) * .5;
    // vec3 n2 = vec3( (abs(n.x) + abs(n.y) + abs(n.z) ) * .33333 );
    // vec3 n2 = n;
    // vec3 col = vec3( n2 );

    // if (d < MAX_DIST) {
    //     vec3 p = ro + rd * d;

    //     float dif = GetLight(p);
    //     col = vec3(dif);
    // }


    // col = pow(col, vec3(1.35));    // gamma correction

    fragColor = vec4(n, 1.);
}