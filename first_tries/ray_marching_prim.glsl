// fully copied from BigWings primitive RayMarching example

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = clamp(.5  + .5 * (b - a) / k, .0, 1.);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b - a;
    vec3 ap = p - a;

    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, .0, 1.);

    vec3 c = a * t * ab;

    return length(p - c) * r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
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

float sdTorus(vec3 p, vec2 r) {
    float x = length(p.xz) - r.x;
    return length(vec2(x, p.y)) - r.y;
}

float dBox(vec3 p, vec3 s) {
    p = abs(p) - s;
    return length(max(p, .0)) + min(max(p.x, max(p.y, p.z) ), .0);
}

float GetDist(vec3 p) {
    float t = iTime;

    // ground plane
    float pd = p.y;

    // rotating box
    vec3 bp = p;
    bp -= vec3(0, .75, 3);  // translation
    bp.xz *= Rot(iTime);    // rotation
    float rotate = dBox(bp, vec3(.75));

    // jumpung torus
    float y = -fract(t) * (fract(t) - 1.);
    vec3 tp = p;                                        // repeating parabola
    tp -= vec3(-2, .8+3.*y, -4);                        // translate
    float squash = 1. + smoothstep(.15, .0, y) * .5;    // scale
    tp.y *= squash;
    tp = tp.xzy;                                        // flip torus on its side
    float scale = sdTorus(tp, vec2(1, .25)) / squash;

    float morph = mix(
        length(p - vec3(4, 1, 2)) - 1.,
        dBox(p - vec3(4, 1, 2), vec3(1, 1, 1)),
        sin(t) * .5 + .5
    );

    float subtract = max(
        -dBox(p - vec3(1. + sin(t) * .5, 1, 0), vec3(1, .5, 2)),
        length(p - vec3(0, 1, 0)) - 1.
    );

    float intersect = max(
        dBox(p - vec3 (sin(iTime) * .5 - 3., 1, 0), vec3(1, .5, 2)),
        length(p - vec3(-4, 1, 0)) - 1.
    );

    float blend = smin(
        length(p - vec3(3, 1, -3)) - .75,
        length(p - vec3(3. + sin(t), 1.5, -3)) - .5,
        .2
    );

    float d = min(morph, pd);
    d = min(d, subtract);
    d = min(d, intersect);
    d = min(d, rotate);
    d = min(d, scale);
    d = min(d, blend);

    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = abs( GetDist(p) );
        d0 += dS;

        if (d0 > MAX_DIST || dS < SURF_DIST) break;
    }

    return d0;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);

    vec3 n = d - vec3(
        GetDist(p - e.xyy),
        GetDist(p - e.yxy),
        GetDist(p - e.yyx)
    );

    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(3, 4, 5);
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

    vec3 col = vec3(0);

    vec3 ro = vec3(0, 4, -5);
    ro.yz *= Rot(-m.y + .4);
    ro.xz *= Rot(iTime * .2 - m.x * 6.2831);

    vec3 rd = R(uv, ro, vec3(0,0,0), .7);

    float d = RayMarch(ro, rd);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        float dif = GetLight(p);
        col = vec3(dif);
    }

    col = pow(col, vec3(1.));    // gamma correction

    fragColor = vec4(col, 1.);
}