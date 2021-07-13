// Marching Parameters
const float staticZ=0.;
const float PI=3.141592;

// Superformula Parameters
const float n1=.5;
const float n2=.45;
const float n3=1.25;

const float m=2.0;

const float aScaleValue=m/4.0;
const float n1Inverse=-1./n1;

// function parameters
const vec2 center=vec2(10.0, 10.);
const float scale= 10.;
const float inverseScale=1./scale;

float superFormulaCos(float angleScaled){
    return pow(abs(cos(angleScaled)), n2);
}

float superFormulaSin(float angleScaled){
    return pow(abs(sin(angleScaled)), n3);
}

float superFormula(float angle){
    float as=angle*aScaleValue;
    return pow(superFormulaCos(as)+superFormulaSin(as), n1Inverse);
}

float atan2(in float y, in float x)
{
    bool s = (abs(x) > abs(y));
    return mix(PI/2.0 - atan(x,y), atan(y,x), s);
}

float sdSuperFormula(vec2 p, vec2 center) {
    p-=center;
    float angle=atan2(p.x, p.y);
    float radius=length(p);
    return (radius-superFormula(angle));
}

float GetDist(vec3 p) {
    float d=sdSuperFormula(p.xy*scale, vec2(0.,0.));
    return d*inverseScale;
}

float GetDist(vec2 p) {
    return GetDist(vec3(p, staticZ));
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

vec3 GetNormal(vec2 p) {
    return GetNormal(vec3(p, staticZ) );
}

vec3 GetNormal() {
    return GetNormal(iMouse.xy/ iResolution.xy);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{//''//
    vec2 uv = (fragCoord) / iResolution.y;
    vec2 m = iMouse.xy/ iResolution.y;

    // vec3 col = vec3(GetNormal(fragCoord) );
    
    float d = GetDist(uv-m);
    if (abs(d) <.002) {
        fragColor=vec4(1.,0.,0.,1.);
    } else {
        fragColor=vec4(vec3(.5) - vec3(d) * .5, 1.);
    }
}