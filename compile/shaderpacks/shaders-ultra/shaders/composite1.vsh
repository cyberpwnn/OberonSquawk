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

#define minimumLight

varying vec3 lightVector;
varying vec2 texcoord;
varying float weatherRatio;

varying vec3 rayColor;
varying vec3 sunColor;
varying vec3 moonColor;
varying vec3 skyColor;
varying vec3 horizonColor;
varying vec3 fogColor;
varying vec3 underwaterColor;
varying vec3 cloudColor;

varying float TimeSunrise;
varying float TimeNoon;
varying float TimeSunset;
varying float TimeMidnight;
varying float TimeDay;
varying float DayToNightFading;

uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float rainStrength;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float screenBrightness;

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

	if (float(worldTime) < 12700 || float(worldTime) > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}

  float time = worldTime;
  TimeSunrise		= ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
  TimeNoon			= ((clamp(time, 0.0, 3000.0)) / 3000.0) - ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0);
  TimeSunset		= ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0);
  TimeMidnight	= ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0) - ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0);

  TimeDay			  = TimeSunrise + TimeNoon + TimeSunset;

  DayToNightFading	= 1.0 - (clamp((time - 12000.0) / 750.0, 0.0, 1.0) - clamp((time - 12750.0) / 750.0, 0.0, 1.0)
  							          +  clamp((time - 22000.0) / 750.0, 0.0, 1.0) - clamp((time - 23250.0) / 750.0, 0.0, 1.0));

	weatherRatio = getWeatherRatio();
  float minLight = screenBrightness + nightVision * 2.0;

  #ifdef minimumLight
    minLight += 1.0;
  #endif

  // Set up colors.
	rayColor  = vec3(0.0);
	rayColor += vec3(1.0, 0.7, 0.5) 	* 2.0 	* TimeSunrise;
	rayColor += vec3(1.0, 1.0, 1.0) 	* 2.0		* TimeNoon;
	rayColor += vec3(1.0, 0.7, 0.5) 	* 2.0		* TimeSunset;
	rayColor += vec3(0.65, 0.8, 1.0) 					* TimeMidnight * max(minLight, 1.0);

	sunColor  = vec3(0.0);
	sunColor += vec3(1.0, 0.7, 0.5) 	* 2.0	* TimeSunrise;
	sunColor += vec3(1.0, 1.0, 1.0) 	* 2.0	* TimeNoon;
	sunColor += vec3(1.0, 0.7, 0.5) 	* 2.0	* TimeSunset;
	sunColor += vec3(1.0, 0.45, 0.2)				* TimeMidnight;

	moonColor = vec3(1.0);

  skyColor  = vec3(0.0);
  skyColor += vec3(0.7, 0.85, 1.0)	 * 0.7		* TimeSunrise;
  skyColor += vec3(0.6, 0.75, 1.0)		  		  * TimeNoon;
  skyColor += vec3(0.7, 0.85, 1.0)	 * 0.7		* TimeSunset;
  skyColor += vec3(0.65, 0.8, 1.0)	 * 0.03	  * TimeMidnight * max(minLight, 1.0);


  skyColor *= 1.0 - weatherRatio;
  skyColor += vec3(1.0, 1.0, 1.0)	  * 0.6	 	* TimeSunrise		* weatherRatio;
  skyColor += vec3(1.0, 1.0, 1.0)   * 0.7	 	* TimeNoon			* weatherRatio;
  skyColor += vec3(1.0, 1.0, 1.0)	  * 0.6	 	* TimeSunset		* weatherRatio;
  skyColor += vec3(0.65, 0.8, 1.0)	* 0.03	* TimeMidnight	* weatherRatio * max(minLight, 1.0);

  horizonColor  = vec3(0.0);
  horizonColor += vec3(1.0, 0.85, 0.7)	* 0.9		* TimeSunrise;
  horizonColor += vec3(1.0, 0.95, 0.9)				   * TimeNoon;
  horizonColor += vec3(1.0, 0.85, 0.7)	* 0.9		* TimeSunset;
  horizonColor += vec3(0.65, 0.8, 1.0) 	* 0.06	* TimeMidnight * max(minLight, 1.0);

  horizonColor *= 1.0 - weatherRatio;
  horizonColor += vec3(1.0, 0.9, 0.8)		* 0.9		* TimeSunrise		* weatherRatio;
  horizonColor += vec3(1.0, 1.0, 1.0)		* 0.8		* TimeNoon			* weatherRatio;
  horizonColor += vec3(1.0, 0.9, 0.8)		* 0.9		* TimeSunset		* weatherRatio;
  horizonColor += vec3(0.65, 0.8, 1.0) 	* 0.045	* TimeMidnight	* weatherRatio * max(minLight, 1.0);

  fogColor  = vec3(0.0);
  fogColor += vec3(1.0, 1.0, 1.0) 	  * 0.7		* TimeSunrise;
  fogColor += vec3(0.85, 0.9, 1.0)		* 0.9		* TimeNoon;
  fogColor += vec3(1.0, 1.0, 1.0) 	  * 0.7		* TimeSunset;
  fogColor += vec3(0.65, 0.8, 1.0)		* 0.04	* TimeMidnight * max(minLight, 1.0);

  fogColor *= 1.0 - weatherRatio;
  fogColor += vec3(1.0, 0.95, 0.9)  * 0.9		* TimeSunrise  * weatherRatio;
  fogColor += vec3(1.0, 1.0, 1.0) 	* 1.0		* TimeNoon     * weatherRatio;
  fogColor += vec3(1.0, 0.95, 0.9)  * 0.9		* TimeSunset   * weatherRatio;
  fogColor += vec3(0.65, 0.8, 1.0)	* 0.04 	* TimeMidnight * weatherRatio * max(minLight, 1.0);

  underwaterColor  = vec3(0.0);
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.6		* TimeSunrise;
  underwaterColor += vec3(0.1, 0.75, 1.0)					* TimeNoon;
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.6		* TimeSunset;
  underwaterColor += vec3(0.1, 0.75, 1.0)	* 0.08	* TimeMidnight;

  cloudColor  = vec3(0.0);
  cloudColor += vec3(1.0, 0.8, 0.65)		* 0.9		* TimeSunrise;
  cloudColor += vec3(1.0, 1.0, 1.0)							* TimeNoon;
  cloudColor += vec3(1.0, 0.8, 0.65)		* 0.9	  * TimeSunset;
  cloudColor += vec3(0.65, 0.8, 1.0)	  * 0.05	* TimeMidnight * max(minLight, 1.0);

  cloudColor *= 1.0 - weatherRatio;
  cloudColor += vec3(1.0, 0.95, 0.9)	* 0.6		* TimeSunrise		* weatherRatio;
  cloudColor += vec3(1.0, 1.0, 1.0)		* 0.8		* TimeNoon			* weatherRatio;
  cloudColor += vec3(1.0, 0.95, 0.9)	* 0.6		* TimeSunset		* weatherRatio;
  cloudColor += vec3(0.65, 0.8, 1.0)	* 0.03	* TimeMidnight	* weatherRatio * max(minLight, 1.0);

}
