// Realce de saturacao global (estilo "vibrance"/saturacao do painel da AMD no Windows).
// O Hyprland aplica este shader em toda a tela via decoration:screen_shader, entao
// o efeito vale pra desktop, jogos e videos, sem daemon e de forma fixa.
//
// Ajuste o fator abaixo:
//   SATURATION = 1.0  -> sem alteracao (100%, cores originais)
//   SATURATION = 1.5  -> +50% de saturacao (equivalente aos 150% do painel da AMD)
// Depois de alterar, recarregue com: hyprctl reload

#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float SATURATION = 1.5;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Luminancia perceptual (coeficientes Rec. 709)
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Interpola entre o cinza (luma) e a cor original; > 1.0 aumenta a saturacao
    color.rgb = clamp(mix(vec3(luma), color.rgb, SATURATION), 0.0, 1.0);

    fragColor = color;
}
