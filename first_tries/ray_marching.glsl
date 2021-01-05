# define MAX_STEPS 100
# define MAX_DIST 100.
# define SURF_DIST .01

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b - a;
    vec3 ap = p - a;

    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);

    vec3 c = a * t * ab;

    return length(p-c) - r;
}

float GetDist(vec3 p) {
    vec4 s = vec4(0, 1, 6, 1);

    float sphereDist = length(p-s.xyz) - s.w;
    float planeDist = p.y;

    float d = min(sphereDist, planeDist);
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i=0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd*d0;
        float dS = GetDist(p);
        d0 += dS;

        if (d0 > MAX_DIST || dS < SURF_DIST) break;
    }

    return d0;
}