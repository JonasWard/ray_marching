#define VIGNETTE 1.
#define EXPOSURE 1.3
#define DOF_SAMPLES 40

#define MAX_STEPS 100
#define MAX_DIST 7.
#define SURF_DIST .001

#define S(a, b, t) smoothstep(a, b, t)


mat2 Rot(float a) {
    float s=sin(a),c=cos(a);
    return mat2(c,-s,s,c);
}

// Dave Hoskins hash without sine
float Hash21(vec2 p) {
	p = fract(p*vec2(123.23,234.34));
    p += dot(p, p+87.);
    return fract(p.x*p.y);
}

float Hash31(vec3 p) {
	p = fract(p*vec3(123.23,234.34,345.54));
    p += dot(p, p+87.);
    return fract(p.x*p.y*p.z);
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// DOF function borrowed from XT95
const float GA =2.399; 
mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
vec3 dof(sampler2D tex,vec2 uv,float rad, vec2 iResolution)
{
	vec3 acc=vec3(0);
    vec2 pixel=vec2(.003*iResolution.y/iResolution.x,.003),angle=vec2(0,rad);;
    rad=1.;
	for (int j=0;j<DOF_SAMPLES;j++)
    {  
        rad += 1./rad;
	    angle*=rot;
        vec4 col=texture(tex,uv+pixel*(rad-1.)*angle);
		acc+=col.xyz;
	}
	return acc/float(DOF_SAMPLES);
}

float Gyroid(vec3 p, float scale, float bias, float thickness) {
    p *= scale;
    float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
	return d/scale;
}

vec4 GetGyroids(vec3 p) {    
    float t = iTime*.1;
       
    p.xy *= Rot(p.z*.3);
    p.z += t;
    
    float g1 = Gyroid(p, 5., .4, .1);
    float g2 = Gyroid(p, 17., .3, .1);
    float g3 = Gyroid(p, 39., .3, .1);
    float g4 = Gyroid(p, -7., .3, .1);
    
    return vec4(g1, g2, g3, g4);              
}

float GetDist(vec3 p) {
	float d = p.y;
    p.x+=.33;
    
    float t = iTime*.1;
    float scale = 20.;
       
    p.xy *= Rot(p.z*.3);
    p.z += t;
    
    float g1 = Gyroid(p, 5., 1.4, .1);
    float g2 = Gyroid(p, 17., .3, .1);
    float g3 = Gyroid(p, 39., .3, .1);
    float g4 = Gyroid(p, 89., .3, .1);
    float g5 = Gyroid(p, 189., .3, .1);
    float g6 = Gyroid(p, 289., .0, .1);
    
    d = g1*.7;
    d -= g2*.3;
    d += g3*.2;
    d += g4*.1;
    d += g5*g4*20.;
    d += g6*.1;
    
   	vec3 P = p;
    P.xz = fract(P.xz)-.5;
    vec2 id = floor(p.xz);
    float n = Hash21(id);
    //P = fract(P)-.5;
    
    return d;              
}

float sdSpark(vec3 p) {
    float t = iTime*.5;
    
    p.xz *= Rot(t*.1);
    
    vec3 id = floor(p);
    p.xz = fract(p.xz)-.5;
    
    float n = Hash21(id.xz);
    
	float z = fract(t+n)-.5;
   	z *= 10.;
    
    n *= 6.2832;
    float size = .3+.2*sin(t*.1);
    vec3 p1 = vec3(0, z-size*1., 0);
    vec3 p2 = vec3(0, z+size*1., 0);
    
    p.x += sin(p.y*3.)*.1;
    
    float d = sdCapsule(p, p1, p2, size*.1);
    
    d = min(d, length(p.xz)+size*2.);
    
    return d;
}

vec2 SparkMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    float dM=MAX_DIST;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = sdSpark(p);
        if(dS<dM) dM = dS;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return vec2(dO, dM);
}

vec3 GetSparkNormal(vec3 p) {
	float d = sdSpark(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        sdSpark(p-e.xyy),
        sdSpark(p-e.yxy),
        sdSpark(p-e.yyx));
    
    return normalize(n);
}


vec2 RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    float dM=MAX_DIST;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if(dS<dM) dM = dS;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return vec2(dO, dM);
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
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

vec3 GetPos(float t) {
    float y = .6+cos(t)*.2;
	return mix(vec3(-.3, y, t), vec3(2.2, y, t), (sin(t)*.5+.5)*1.);
}

vec3 Bg(vec3 rd) {
    float b = -rd.y*.5+.5;
	vec3 col = vec3(.9, .6, .5)*b*4.;
    
    float a = atan(rd.x, rd.z);
    
    //col += sin(a*10.+iTime)*(1.-rd.y);
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = (iMouse.xy-iResolution.xy*.5)/iResolution.xy;
	float t = iTime;
   
    // vec2 heat=sin(vec2(.123, .234)*t*30.+uv*40.+vec2(0,t*10.));
    //heat *= uv.y+.5;
    float c = (sin(t*.1)*.5+.5);
   
    #ifndef ABSTRACT
    c = .1;
    #endif
    
   //c=.9;
    // uv += heat*.02*(c*c*c*c+.1);
    
    
    vec3 ro = vec3(0, 0, .01);
    ro.yz *= Rot(m.y*3.14*.25+.25);
    ro.xz *= Rot(-m.x*6.2831+t*.1);
   
   // ro = GetPos(t*0.);
    vec3 up = vec3(0,1,0);
    //up.xy *= Rot(sin(t)*.4);
    vec3 lookat = vec3(0,0,0);
    
    float zoom = mix(.7, 1.7, sin(t*.15)*.5+.5);
    vec3 rd = R(uv, ro, lookat, zoom, up);

    float d = RayMarch(ro, rd).x;
    
    vec3 bg = Bg(rd);
    vec3 col = vec3(0.);
	
    if(d<MAX_DIST) {
        
        vec3 p = ro + d*rd;
        vec3 n = GetNormal(p);
       
        // float dif = n.y*.5+.5;
        
        vec4 g = GetGyroids(p);
        
        // col += dif;
        col *= min(1., g.y*20.);
        //col *= .1;
        
        // float lava = S(.01-min(0., p.y*.1), -.01, g.y);
        // lava *= sin(g.z*100.+t)*.5+.5;
        // float lava = 1.0;
       // lava += S(-.7, -1., n.y);
        
        
        // float flicker = Gyroid(p-vec3(0,t,0), 5., 0., .1);
        // flicker *= Gyroid(p-vec3(.2,.5,0)*t, 5., 0., .1);
        
        // col *= sin(t*.2)*.5+.5; 
        // col += flicker*10.*vec3(1., .4, .1);//*S(.01,.0, g.y);
        
        // col += lava*vec3(1., .5, .1);
        
    }
    col = mix(col, bg, S(0., 7., d));
    
    
    // float dSpark = SparkMarch(ro, rd).x;
    
    
    // if(dSpark<MAX_DIST && dSpark<d) {
    //     //col += 1.;
        
    //     vec3 p = ro+rd*dSpark;
    //     vec3 n = GetSparkNormal(p);
    //     n = normalize(n*vec3(1,0,1));
        
    //     float f = max(0., dot(rd, -n));
    //     float fade = 1.-pow(f, 5.);
    //     fade = .05/fade;
    //     fade *= S(.0, 1., f);
    //     col += fade;
    //     //col += 1.;
    // }
    
    
    
    fragColor = vec4(col,d);
}

// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {

//     vec2 uv = (fragCoord)/iResolution.xy;
// 	vec2 m = (iMouse.xy-iResolution.xy*.5)/iResolution.xy;
// 	float t = iTime;
   
//     float depth = texture(iChannel0,uv).w;
   	
//     depth = smoothstep(.0, .1, depth-.92)*(sin(t*.3)*.5+.5);
//     //depth = 0.;
    
//     vec3 col = dof(iChannel0,uv,depth*1.2, iResolution.xy);
//     col *= col*EXPOSURE;
//     uv -= .5;
//     col *= 1.-dot(uv, uv)*VIGNETTE;
    
//     fragColor = vec4(col,1.0);
// }