#define MAX_STEPS 10000
#define MAX_DIST 20.
#define SURF_DIST .000001

# define PI 3.1415
# define TAU 6.283185
# define SCALE .2
# define THICKNESS 1.0
# define TIMESCALE .2
# define SESCALE 2.
# define TERCALE .512542
// # define SPHERERAD 10.0
# define BOXSIZE .5

const vec4 b_pln = vec4(.0, 0., 1., 10.);
const vec4 b_pln_ref = vec4(.0, 0., 1., 9.0);

const float bandHeight = .05;
const float doubleBH = 2. * bandHeight;
const float squareBH = bandHeight * bandHeight;

const float voxScale = .25;
const float voxScaleMult = 1. / voxScale;

float sdPlane(vec3 p, vec4 pln){
    return dot(p,pln.xyz) + SCALE * pln.w;
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

float sdBands(vec3 p) {
    float val = mod(p.z, doubleBH);
    val -= bandHeight;
    val = sqrt(squareBH - val * val);
    return -val;
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

vec3 voxelizer(vec3 p) {
    float vScale = (sdGyroid(p, SCALE) + 2.) * voxScale;
    // return voxScale * round(p * voxScaleMult);
    return vScale * round(p / vScale);
    // return vec3(round(p.x), round(p.y), round(p.z));
}



float GetDist(vec3 p) {
    float d = sdPlane(p, b_pln_ref);
    float d_0 = sdPlane(p, b_pln);

    if (d > 0.) {
        return d_0;
    } else {
        float d_g_p = sdGyroid(p, TERCALE) * .01;

        p = voxelizer(p);
        float d_g = sdGyroid(p, sdGyroid(p, SESCALE) );

        float d = max(d_g, d_0);

        return d - d_g_p;
    }

    // float d_g = sdGyroid(p, SCALE * sdGyroid(p, SESCALE) );
    // return min(d, 100.);

    // return d_g + d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p) * 1.;
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