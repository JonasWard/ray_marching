const float pi_invert = 0.3183098862;
const float scale = 100.;
const float doubleScale = scale * 2.0;

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
    addition += magnitude * pDelta / dot(pDelta, pDelta);
}

float fluxAngleFunction(vec2 p, float direction) {
    p /= scale * 2.;

    vec2 pA = vec2 (-1,0.);
    vec2 pB = vec2 (0,1);
    vec2 pC = vec2 (1,0);
    vec2 pD = vec2 (0,-1);

    vec2 td = vec2(.0);
    forceDeuToCharge(p, pA, 1., td);
    forceDeuToCharge(p, pB, -1., td);
    forceDeuToCharge(p, pC, 1., td);
    forceDeuToCharge(p, pD, -1., td);

    return mod(pi + direction * atan(td.y,td.x), pi);
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
    float angle = fluxAngleFunction(p, direction);
    float l = length(p) / scale * .71;
    l = 0.;

    fragColor = vec4(hsv2rgb_smooth( vec3(angle * pi_invert, 1.-l, 1.) ), 1.);

}