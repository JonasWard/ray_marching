// designing with planes
   
   
   


// Gyroid Marching

const vec4[] plns_a = vec4[](
    vec4(0.986412008763,0.162539413486,0.0239225423552,-0.511545764967),
    vec4(-0.242400603769,-0.959063258391,0.146422722608,3.85777622777),
    vec4(-0.855258669494,0.30556784867,-0.418522279113,1.88872489501)
);
const vec4[] plns_b = vec4[](
    vec4(-0.852182201657,-0.438226582988,-0.285907252691,1.70633734462),
    vec4(-0.195070758087,0.975483949628,-0.101874743473,3.96796435905),
    vec4(0.949418579977,-0.257121046972,-0.180258501045,0.570284240345)
);
const vec4[] plns_c = vec4[](
    vec4(-0.369274976854,0.822945365631,-0.431737092056,1.52086271622),
    vec4(0.975625258361,-0.218861945911,0.0159625775046,2.63623059976),
    vec4(-0.594164674406,-0.80385751337,0.0279542105544,0.48671165116)
);
const vec4 b_pln = vec4(.0, 0., -1., .0);

#define MAX_STEPS 500
#define MAX_DIST 10000.
#define SURF_DIST .001

# define PI 3.1415
# define TAU 6.283185
# define SCALE .5
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
    float val = mod(p.y, DOUBLEBH);
    val -= BANDHEIGHT;
    val = sqrt(SQUAREBH - val * val);
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

float sdPlaneSet(vec3 p, vec4[3] plns) {
    float d = MAX_DIST;
    for(int i = 0; i < plns.length(); i++) {
        float loc_d = sdPlane(p, plns[i]);
        if (loc_d < d) {
            d = loc_d;
        }
    }

    return d;
}

float GetDist(vec3 p) {
    float d_g = sdGyroid(p, sdGyroid(p, SESCALE) );
    float d_a = sdPlaneSet(p, plns_a) + d_g * .04;
    float d_b = sdPlaneSet(p, plns_b) + d_g * .08;
    float d_c = sdPlaneSet(p, plns_c) + d_g * .1;
    float d_0 = sdPlane(p, b_pln);

    float d = max(d_a, d_b);
    d = max(d, d_c);
    d = max(-d, d_0);

    // float d_g = sdGyroid(p, SCALE * sdGyroid(p, SESCALE) );
    return min(d, 100.);

    // return d_g + d;
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