//The raycasting code is somewhat based around a 2D raycasting toutorial found here: 
//http://lodev.org/cgtutor/raycasting.html

const bool USE_BRANCHLESS_DDA = true;
const int MAX_RAY_STEPS = 128;
const float voxelizationScale = 20.;
const float voxScale = 1.;
const float voxScaleMult = 1. / voxScale;
const float scale = .02;
const vec4 b_pln = vec4(.0, 0., 1., 10.);
const vec4 sphere = vec4(0., 0., 0., 50.);

const vec3 half_ = vec3(.5);

float sdSphere(vec3 p) {
    return length(p - sphere.xyz) - sphere.w;
} 

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
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

float sdPlane(vec3 p){
    return dot(p,b_pln.xyz) + scale * b_pln.w;
}

vec3 voxelizer(vec3 p) {
    // float vScale = (sdGyroid(p, voxelizationScale) + 1.) * voxScale;
    return voxScale * round(p * voxScaleMult);
    // return vScale * round(p / vScale);
    return vec3(round(p.x), round(p.y), round(p.z));
}
	
bool getVoxel(vec3 c) {
	vec3 p = voxelizer( c + half_ );

    float d_0 = sdSphere(p);
    float d_g = sdGyroid(p, sdGyroid(p, .05) );

    float d = max(d_g, -d_0);

	// float d = min(max(-sdSphere(p, 7.5), sdBox(p, vec3(6.0))), -sdSphere(p, 25.0));
	return d < 0.0;
}

vec2 rotate2d(vec2 v, float a) {
	float sinA = sin(a);
	float cosA = cos(a);
	return vec2(v.x * cosA - v.y * sinA, v.y * cosA + v.x * sinA);	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 screenPos = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
	vec3 cameraDir = vec3(0.0, 0.0, 0.8);
	vec3 cameraPlaneU = vec3(1.0, 0.0, 0.0);
	vec3 cameraPlaneV = vec3(0.0, 1.0, 0.0) * iResolution.y / iResolution.x;
	vec3 rayDir = cameraDir + screenPos.x * cameraPlaneU + screenPos.y * cameraPlaneV;
	vec3 rayPos = vec3(0.0, 0.0, -12.0);
		
	rayPos.xz = rotate2d(rayPos.xz, .1 * iTime);
	rayDir.xz = rotate2d(rayDir.xz, .1 * iTime);
	
	vec3 mapPos = vec3(floor(rayPos + 0.));

	vec3 deltaDist = abs(vec3(length(rayDir)) / rayDir);
	
	vec3 rayStep = vec3(sign(rayDir));

	vec3 sideDist = (sign(rayDir) * (vec3(mapPos) - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
	
	bvec3 mask;
	
	for (int i = 0; i < MAX_RAY_STEPS; i++) {
		if (getVoxel(mapPos)) continue;

        //Thanks kzy for the suggestion!
        mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));
        /*bvec3 b1 = lessThan(sideDist.xyz, sideDist.yzx);
        bvec3 b2 = lessThanEqual(sideDist.xyz, sideDist.zxy);
        mask.x = b1.x && b2.x;
        mask.y = b1.y && b2.y;
        mask.z = b1.z && b2.z;*/
        //Would've done mask = b1 && b2 but the compiler is making me do it component wise.
        
        //All components of mask are false except for the corresponding largest component
        //of sideDist, which is the axis along which the ray should be incremented.			
        
        sideDist += vec3(mask) * deltaDist;
        mapPos += vec3(mask) * rayStep;
	}
	
	vec3 color;
	if (mask.x) {
		color = vec3(0.5);
	}
	if (mask.y) {
		color = vec3(1.0);
	}
	if (mask.z) {
		color = vec3(0.75);
	}
	fragColor.rgb = color;
	//fragColor.rgb = vec3(0.1 * noiseDeriv);
}