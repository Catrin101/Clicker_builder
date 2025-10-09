shader_type canvas_item;

// La textura de ruido es necesaria para el efecto de olas.
// Godot no tiene una función 'noise()' directa en el fragment shader 2D.
uniform sampler2D noise_texture; 

// Colores del agua que puedes ajustar en el Inspector
uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.6, 1.0); // Azul principal
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.5); // Color de la "espuma"/brillo

// Parámetros de las olas que puedes ajustar en el Inspector
uniform float wave_speed : hint_range(0.1, 5.0) = 0.5;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.05;
uniform float wave_scale : hint_range(1.0, 100.0) = 40.0; 

// Parámetro para un segundo patrón de ruido (pequeñas ondas)
uniform float detail_strength : hint_range(0.0, 0.05) = 0.01;
uniform float detail_scale : hint_range(1.0, 50.0) = 15.0;

void fragment() {
	vec2 base_uv = UV;
	float time = TIME;
	
	// Ajustar las UV para controlar la escala del ruido
	vec2 scaled_uv = base_uv * (1.0 / wave_scale);
	
	// 1. Muestrear el Ruido Principal (Olas grandes)
	// Desplaza la coordenada de muestreo con el tiempo para simular el movimiento
	float noise1 = texture(noise_texture, scaled_uv + vec2(time * wave_speed, 0.0)).r;
	
	// 2. Muestrear el Ruido de Detalle (Olas pequeñas)
	vec2 detail_scaled_uv = base_uv * (1.0 / detail_scale);
	float noise2 = texture(noise_texture, detail_scaled_uv + vec2(0.0, time * wave_speed * 1.5)).r;
	
	// 3. Desplazamiento de Coordenadas UV (Efecto de distorsión)
	// Mueve la coordenada UV en base a los valores de ruido
	vec2 distorted_uv = base_uv;
	distorted_uv.x += (noise1 * 2.0 - 1.0) * wave_strength; // * 2.0 - 1.0 para centrar el rango en 0
	distorted_uv.y += (noise2 * 2.0 - 1.0) * detail_strength;
	
	// 4. Obtener el color final (mezcla y brillo)
	// La combinación de ruido define el brillo/oscuridad en ese punto
	float final_noise = (noise1 * 0.7 + noise2 * 0.3); // Ponderamos los ruidos
	
	// Remapear el ruido para crear el efecto de "brillo" en las crestas (más blanco/espuma)
	float foam_factor = smoothstep(0.4, 0.7, final_noise); 
	
	// Mezcla el color del agua con el color de la espuma usando el factor
	vec4 final_color = mix(water_color, foam_color, foam_factor);
	
	// 5. Salida
	COLOR = final_color;
}