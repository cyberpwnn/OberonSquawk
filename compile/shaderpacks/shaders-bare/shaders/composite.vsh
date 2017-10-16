#version 120

/*



			███████ ███████ ███████ ███████ █
			█          █    █     █ █     █ █
			███████    █    █     █ ███████ █
			      █    █    █     █ █
			███████    █    ███████ █       █

	Before you change anything here, please keep in mind that
	you are allowed to modify my shaderpack ONLY for yourself!

	Please read my agreement for more informations!
		- http://dedelner.net/agreement/



*/

//#define dynamicWeather
  #define weatherRatioSpeed	1.0 // [0.1 0.5 1.0 2.0 5.0 10.0] Won't take any effect when 'useMoonPhases' is enabled!
  //#define useMoonPhases

//#define useFixedWeatherRatio
  #define cloudCover 0.5 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

varying vec3 lightVector;
varying vec2 texcoord;
varying float weatherRatio;

varying vec3 ambientColor;
varying vec3 sunlightColor;
varying vec3 underwaterColor;
varying vec3 torchColor;
varying vec3 waterColor;
varying vec3 lowlightColor;

varying float TimeBeforeSunrise;
varying float TimeSunrise;
varying float TimeSunrise2;
varying float TimeNoon;
varying float TimeSunset;
varying float TimeSunset2;
varying float TimeAfterSunset;
varying float TimeMidnight;
varying float TimeMidnight2;
varying float TimeDay;
varying float DayToNightFading;

uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float rainStrength;
uniform float frameTimeCounter;

uniform int worldTime;
uniform int moonPhase;


float getWeatherRatio() {

  float value = rainStrength;

  #ifdef dynamicWeather

    #ifdef useMoonPhases

      value = float(moonPhase) / 7.0;

    #else

  	 value = pow(texture2D(noisetex, vec2(1.0) + vec2(frameTimeCounter * 0.005) * 0.01 * weatherRatioSpeed).x, 2.0);

    #endif

  #endif

  #ifdef useFixedWeatherRatio

    value = cloudCover;

  #endif

  // Raining.
  value = mix(value, 1.0, rainStrength);

	return pow(value, mix(2.0, 1.0, rainStrength));

}


void main() {

  texcoord = gl_MultiTexCoord0.st;

	gl_Position = ftransform();

  float time = worldTime;
  TimeSunrise		= ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
  TimeNoon			= ((clamp(time, 0.0, 3000.0)) / 3000.0) - ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0);
  TimeSunset		= ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0);
  TimeMidnight	= ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0) - ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0);

  TimeDay			  = TimeSunrise + TimeNoon + TimeSunset;


  TimeBeforeSunrise	= ((clamp(time, 23250.0, 23255.0) - 23250.0) / 5.0) - ((clamp(time, 23255.0, 24000.0) - 23255.0) / 745.0);
  TimeSunrise2		  = ((clamp(time, 23255.0, 24000.0) - 23255.0) / 745.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
  TimeSunset2		    = ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 12750.0) - 12000.0) / 750.0);
  TimeAfterSunset	  = ((clamp(time, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(time, 12750.0, 12755.0) - 12750.0) / 5.0);
  TimeMidnight2		  = ((clamp(time, 12750.0, 12755.0) - 12750.0) / 5.0) - ((clamp(time, 23250.0, 23255.0) - 23250.0) / 5.0);


  DayToNightFading	= 1.0 - (clamp((time - 12000.0) / 750.0, 0.0, 1.0) - clamp((time - 12750.0) / 750.0, 0.0, 1.0)
  							          +  clamp((time - 22000.0) / 750.0, 0.0, 1.0) - clamp((time - 23250.0) / 750.0, 0.0, 1.0));

  if (time < 12700 || time > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}

  weatherRatio = getWeatherRatio();

  ambientColor  = vec3(0.0);
  ambientColor += vec3(0.85, 0.9, 1.0)	* 0.6		* TimeSunrise;
  ambientColor += vec3(0.85, 0.9, 1.0)					* TimeNoon;
  ambientColor += vec3(0.85, 0.9, 1.0)	* 0.6		* TimeSunset;
  ambientColor += vec3(0.6, 0.7, 1.0)	  * 0.04	* TimeMidnight;

  ambientColor *= 1.0 - weatherRatio;
  ambientColor += vec3(1.0, 1.0, 1.0)		* 0.8		* TimeSunrise		* weatherRatio;
  ambientColor += vec3(1.0, 1.0, 1.0)		* 0.9		* TimeNoon			* weatherRatio;
  ambientColor += vec3(1.0, 1.0, 1.0)		* 0.8		* TimeSunset		* weatherRatio;
  ambientColor += vec3(0.65, 0.8, 1.0)		* 0.04 	* TimeMidnight	* weatherRatio;

  sunlightColor  = vec3(0.0);
  sunlightColor += vec3(1.0, 0.3, 0.)	  * 0.5		* TimeBeforeSunrise;
  sunlightColor += vec3(1.0, 0.4, 0.0)	* 0.8		* TimeSunrise2;
  sunlightColor += vec3(1.0, 0.75, 0.5)				  * TimeNoon;
  sunlightColor += vec3(1.0, 0.4, 0.0)	* 0.8		* TimeSunset2;
  sunlightColor += vec3(1.0, 0.3, 0.)	  * 0.5		* TimeAfterSunset;
  sunlightColor += vec3(0.65, 0.8, 1.0)	* 0.03	* TimeMidnight2;

  underwaterColor  = vec3(0.0);
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.6		* TimeSunrise;
  underwaterColor += vec3(0.1, 0.75, 1.0)					* TimeNoon;
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.6		* TimeSunset;
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.08	* TimeMidnight;

  torchColor = vec3(1.0, 0.57, 0.3);

  waterColor = vec3(0.7, 0.9, 1.0);

  lowlightColor = vec3(0.65, 0.8, 1.0);

}
