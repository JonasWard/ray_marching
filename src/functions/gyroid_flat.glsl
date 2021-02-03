// Gyroid Marching

const float tau = 6.2831853072;

// marching
const int maxSteps = 2000;
const float minDistance = .001;
const float maxDistance = 100.;
const float understepping = .05;

// function parameters
const float scaleGyroidA = 2.;
const float scaleGyroidB = 10.;
const float gyroidDScale = .05;
const float planeHeight = 10.;

float sdPlane(vec3 p){
    vec4 n = vec4(0, 0, 1, planeHeight);
    return dot(p,n.xyz) + n.w;
}

float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    d *= .3333;
	return d;
}

float sdSchwarP(vec3 p, float scale) {
    p *= scale;
    p = cos(p);
    float d = p.x + p.y + p.z;
    d *= .3333;
    return d;
}

float sdSchwarD(vec3 p, float scale) {
    p *= scale;
    vec3 s = sin(p);
    vec3 c = cos(p);

    float d = (
        s.x * s.y * c.z + 
        s.x * c.y * c.z + 
        c.x * s.y * c.z + 
        c.x * c.y * s.z 
    );

    d *= .25;

    return d;
}

float GetDist(vec3 p) {
    float d_p = sdPlane(p);
    // serialise as much as you want
    float d_g = sdSchwarD(p, scaleGyroidB * (1. + sdSchwarD(p, scaleGyroidA) ) );
    float d = d_g * gyroidDScale + d_p;

    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < maxSteps; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p) * understepping;
        d0 += dS;

        if (d0 > maxDistance || dS < minDistance) break;
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
    float d = RayMarch(p + n * minDistance * 2., l);
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

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy/ iResolution.xy;

    // vec3 col = vec3(GetNormal(fragCoord) );

    vec3 ro = vec3(10., 0, 0.);
    ro.yz *= Rot(-m.y + .4);
    ro.xz *= Rot(5.3 + m.x * tau);

    vec3 rd = R(uv, ro, vec3(0), .58);

    float d = RayMarch(ro, rd);
    vec3 p = ro + d*rd;
    
    vec3 n = vec3(.5) - GetNormal(p) * .5;

    fragColor = vec4(n, 1.);
}