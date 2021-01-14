const float pi = 3.1415926536;
const float pi_invert = 1. / pi;
const float scale = 100. * pi;
const float doubleScale = scale * 2.0;
const float sqrat1over2 = sqrt(.5);

const vec2 cellVec = vec2(doubleScale);
const vec2 cellCenter = vec2(scale);

const float infinity = 1.;

float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    // float d = abs(dot(sin(p), cos(p.yzx) ) + THICKNESS) ;
    // float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
    // d += 3.0;
    d *= .3333;
	return d;
}

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

    vec2 pA = vec2 (-infinity, 0.);
    vec2 pB = vec2 (0, -infinity);
    vec2 pC = vec2 (infinity, 0);
    vec2 pD = vec2 (0, infinity);

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

float cornerSmoothedMagnitude(vec2 p) {
    p /= scale;
    const vec2 topRight = vec2(1.);
    const vec2 bottomRight = vec2(1., -1.);
    const vec2 bottomLeft = vec2(-1.);
    const vec2 topLeft = vec2(-1., 1.);

    float magnitude = 1.0;
    float tRD = distance(topRight, p);
    float bRD = distance(bottomRight, p);
    float bLD = distance(bottomLeft, p);
    float tLD = distance(topLeft, p);
    if (tRD < 1.) {
        magnitude = (1. - tRD);
    }

    if (bRD < 1.) {
        magnitude = (1. - bRD);
    }

    if (bLD < 1.) {
        magnitude = (1. - bLD);
    }

    if (tLD < 1.) {
        magnitude = (1. - tLD);
    }

    return magnitude;
}

float squareToCircleDistanceSimple(vec2 p) {
    p /= scale;
    p = abs(p);
    float tangens = min(p.y / p.x, p.x / p.y);
    return length(p) / length( vec2(1.0, tangens) );
}

float fgSquircularMapping(vec2 p) {
    p /= scale;
    float x = p.x;
    float y = p.y;
    float x2 = x * x;
    float y2 = y * y;
    float x2y2 = x2 * y2;
    float x2_y2 = x2 + y2;
    float bam = sqrt(x2_y2 - x2y2) / sqrt(x2_y2);
    float u = x * bam;
    float v = y * bam;
    return length(vec2(u, v));
}

float ellipticalGridMapping(vec2 p) {
    p /= scale;
    float x = p.x;
    float y = p.y;
    float x2 = x * x;
    float y2 = y * y;
    float u = x * sqrt(1. - y2 * .5);
    float v = y * sqrt(1. - x2 * .5);
    return length(vec2(u, v));
}

vec2 fluxToPolar(vec2 p, float direction) {
    vec2 td = fluxFunction(p);
    float angle = invertAngle(atan(td.y, td.x), direction);
    // float magnitude = distance(p, vec2(0.)) / scale;
    float magnitude = ellipticalGridMapping(p);
    // magnitude *= magnitude;
    // float magnitude = length(td) * sqrat1over2;

    // if (magnitude < 1.0) {
    //     if (magnitude > 0.0) {
    //         magnitude = magnitude;
    //     } else {
    //         magnitude = 0.0;
    //     }
    // } else {
    //     magnitude = 1.0;
    // }

    return vec2(angle, magnitude);
}

vec2 uvMod(vec2 p, out float direction){
    vec2 modVec = mod(p, cellVec) - cellCenter;

    vec2 cellIdx = mod( (p - cellCenter - modVec) / doubleScale, 2.0) * 2.0 - 1.0;
    direction = cellIdx.x*cellIdx.y;

    return modVec;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord + vec2(5.);

    float direction = 1.0;
    vec2 p = uvMod(uv, direction);
    vec2 fluxVec = fluxToPolar(p, direction);

    // fragColor = vec4(hsv2rgb_smooth( vec3(fluxVec.y, 1., fluxVec.y ) ), 1.);
    fragColor = vec4(hsv2rgb_smooth( vec3(sdGyroid(vec3(fluxVec.xy, iTime * .2 ), 20.) *.5 + .5, 1., 1.0 - fluxVec.y * .71) ), 1.);

}