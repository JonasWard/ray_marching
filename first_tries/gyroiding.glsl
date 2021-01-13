// Gyroid Marching

#define MAX_STEPS 500
#define MAX_DIST 1000.
#define SURF_DIST .0001

# define PI 3.1415
# define TAU 6.283185
# define SCALE .2
# define THICKNESS 1.0
# define TIMESCALE .2
# define SESCALE 25.
# define TERCALE 2.
// # define SPHERERAD 10.0
# define BOXSIZE 2.0
# define BANDHEIGHT .02
# define DOUBLEBH .04
# define SQUAREBH .0004

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq){
	float unit = iResolution.x/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
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

float GetDist(vec3 p) {
    float t = iTime;

    float d_g = SCALE * sdGyroid(p, SESCALE * sdGyroid(p, sdGyroid(p, TERCALE)));
    // float d_s = sdBox(p);
    float d_b = sdBands(p);
    // float d_s = sdCylinder(p);
    float d_s = sdSphere(p);
    // intersection
    // float d = max(d_s, d_g);
    // float d = max(d_s, d_g) + d_b;
    // bumping
    float d = d_s + .4 * d_g + d_b;
    // float d = sdGyroid(p);

    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p) * .2;
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

    vec3 ro = vec3(0, 4, -5);
    ro.yz *= Rot(-m.y + .4);
    ro.xz *= Rot(5.3 - m.x * 6.2831);

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