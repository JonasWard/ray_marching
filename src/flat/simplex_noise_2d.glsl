float rand(float n){
    return fract(sin(n) * 43758.5453123);
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(float p){
	float fl = floor(p);
    float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
	
float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

void main() {
    vec2 st = gl_FragCoord.xy/iResolution.xy * 100.;
    float d = noise(st);
    // float d = noise(vec3(st, 0.));
    vec3 color = vec3(d);
    // // Scale the space to see the grid
    // st *= 10.;

    // // Show the 2D grid
    // color.rg = fract(st);

    // // Skew the 2D grid
    // color.rg = fract(noise(st));

    // // Subdivide the grid into to equilateral triangles
    // color = simplexGrid(st);

    gl_FragColor = vec4(color,1.0);
}