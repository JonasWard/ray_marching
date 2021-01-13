const float c     = 1000.;
const float pi_invert = 0.3183098862;

vec2 Scale(vec2 p){
    return (p*2.-iResolution.xy)/iResolution.y;
}

vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 scaledp = Scale(fragCoord);
    
    
    vec2 MinPole  = Scale(abs(iMouse.zw)) * float(iMouse.z != 0.0);
    vec2 PlusPole = Scale(iMouse.xy);
    
    //debug standard color
    vec3 col = vec3(abs(scaledp.x),abs(scaledp.y),1.);
    
    //Compass drawing
    	//Compass position and scaling etc..
        vec2 blocked = mod(scaledp*c+.5,1.)*2.-1.;//position of the pixel within the compass
        vec2 middle  = floor(scaledp*c+.5)/c;//middle of compass in the field

    	//forces
        vec2 delta1 = PlusPole-middle;
        vec2 force1 =  delta1/dot(delta1,delta1);
        vec2 delta2 = MinPole-middle;
        vec2 force2 = -delta2/dot(delta2,delta2);
        vec2 forcer = force1+force2;

    //magnet drawing
    	//calculating the distance from a point to the magnet
        vec2 delta = PlusPole-MinPole;
        float direction = atan(forcer.x, forcer.y);
        col = hsv2rgb_smooth(vec3(direction * pi_invert, sqrt(dot(forcer, forcer)), 1.0));
        // col = hsv2rgb_smooth(vec3(1, 1, 1) );
    	//colouring
        // if(dm<.02){//inside magnet
        //     if(distance(scaledp,PlusPole)>distance(scaledp,MinPole)){//on which side of the magnet
        //         col = vec3(.8,.3,.3);
        //     }else{
        //         col = vec3(.9);
        //     }
        // }else if(abs(dm-.02)<.02){
        //     col = vec3(0);
        // }
    
	fragColor = vec4(col,1.0);
}