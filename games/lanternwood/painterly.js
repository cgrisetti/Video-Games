import * as THREE from 'three';
import { EffectComposer, RenderPass, EffectPass, Effect, EffectAttribute, BloomEffect, VignetteEffect } from 'postprocessing';
import { loadSaved, save } from './saved.js';

// The painted look: Lanternwood drawn like a storybook painting instead of shiny plastic shapes,
// the way the backgrounds in Kiki's Delivery Service, Over the Garden Wall and Brambly Hedge are
// painted in gouache and watercolor. It works in two layers:
//
//   1. Painted surfaces. Every MeshStandardMaterial in the game (so every tree, hedge, rock, gnome
//      and gate) is shaded the way a painter would: light comes in a few soft steps instead of a
//      smooth plastic gradient, shadows turn cool and violet instead of grey, sunlit edges catch a
//      warm rim of light, and every surface gets brushwork and patchy pigment laid over it, in
//      strokes that follow the surface (grassy flicks on the ground, streaks down tree trunks).
//      Faceted "low-poly" shapes are smoothed into round, soft forms.
//   2. A painted finish over the whole picture (post-processing, with the `postprocessing`
//      library): a Kuwahara filter, which smears the picture into flat dabs of paint the way an oil
//      or gouache brush does; thin wobbly ink lines round the outlines of things; glowing light
//      that bleeds into the air round the lanterns (bloom); a warm golden-hour color grade; the
//      grain of watercolor paper; and darkened corners like an old picture book.
//
// Everything is drawn from code, so there are no image files to download or license.
// Turn it off in Settings ("Painted look") to compare with the old look, or on a slow computer.

// Tweak these to change the painting.
const BRUSH_RADIUS = 3; // How big the Kuwahara paint dabs are, in screen pixels (on a normal screen).
const INK_STRENGTH = 0.55; // How dark the outlines are (0 for none).
const INK_DISTANCE = 45; // Outlines fade out by this far away, as a painter leaves the background soft.
const LIGHT_STEPS = 3; // How many steps the light comes in, like layers of paint (more is smoother).
const STEP_SOFTNESS = 0.55; // How much the steps show (0 smooth, 1 hard-edged bands).
const BRUSHWORK = 1; // How strong the painted texture on surfaces is.
const SHADOW_TINT = new THREE.Color(0.74, 0.74, 1.0); // The cool violet that shadows turn.
const LIGHT_TINT = new THREE.Color(1.08, 1.0, 0.86); // The warm gold of sunlit sides.
const RIM_TINT = new THREE.Color(1.0, 0.82, 0.55); // The glow along sunlit edges.
const BLOOM = 0.75; // How much bright things (lanterns, sunlit clouds) glow.
const PAPER_GRAIN = 0.045; // How much the watercolor paper shows through.

// The "Painted look" setting, saved in this browser.
export const graphicsSettings = { painted: true, ...loadSaved('graphics') };

export function setPainted(on) {
  graphicsSettings.painted = on;
  save('graphics', graphicsSettings);
}

// Shared by every painted material, so changing one changes them all.
export const paintUniforms = {
  uPaintTime: { value: 0 },
  uPaint: { value: 1 }, // 1 painted, 0 the old look.
  uShadowTint: { value: SHADOW_TINT },
  uLightTint: { value: LIGHT_TINT },
  uRimTint: { value: RIM_TINT },
};

// Value noise and fractal noise, in GLSL, for brushwork. (Noise is smooth randomness: nearby spots
// get similar values, so it looks like patches and strokes instead of TV static.)
export const NOISE_GLSL = /* glsl */ `
  float paintHash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
  }
  float paintNoise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(paintHash(i + vec3(0, 0, 0)), paintHash(i + vec3(1, 0, 0)), f.x),
                   mix(paintHash(i + vec3(0, 1, 0)), paintHash(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(paintHash(i + vec3(0, 0, 1)), paintHash(i + vec3(1, 0, 1)), f.x),
                   mix(paintHash(i + vec3(0, 1, 1)), paintHash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
  }
  float paintFbm(vec3 p) {
    return 0.55 * paintNoise(p) + 0.3 * paintNoise(p * 2.13 + 7.1) + 0.15 * paintNoise(p * 4.37 + 3.3);
  }
`;

// --- 1. Painted surfaces ---

// Rewrite a MeshStandardMaterial's shader to paint it. Three.js builds each material's shader from
// named pieces ("chunks"); this swaps a few of them for painted versions. A material can set
// userData.paint to 'character' (smooth skin and fur: less brushwork) or 'plain' (none at all).
export function paintShader(shader) {
  Object.assign(shader.uniforms, paintUniforms);
  const kind = this?.userData?.paint;
  const brushwork = kind === 'plain' ? 0 : kind === 'character' ? 0.35 : BRUSHWORK;

  // Round, soft shapes instead of flat facets. (#undef switches off the facets three.js would add.)
  shader.vertexShader = shader.vertexShader
    .replace('#include <common>', `#include <common>\n#undef FLAT_SHADED\nvarying vec3 vPaintPos;\nuniform float uPaintTime;`)
    .replace(
      '#include <worldpos_vertex>',
      `#include <worldpos_vertex>
      {
        vec4 paintWorld = vec4(transformed, 1.0);
        #ifdef USE_INSTANCING
          paintWorld = instanceMatrix * paintWorld;
        #endif
        vPaintPos = (modelMatrix * paintWorld).xyz;
      }`,
    );

  shader.fragmentShader = shader.fragmentShader
    .replace(
      '#include <common>',
      `#include <common>
      #undef FLAT_SHADED
      varying vec3 vPaintPos;
      uniform float uPaint;
      uniform vec3 uShadowTint;
      uniform vec3 uLightTint;
      uniform vec3 uRimTint;
      ${NOISE_GLSL}`,
    )
    // Brushwork in the pigment: patches of lighter and darker, warmer and cooler paint, plus strokes
    // laid along the surface. It's "triplanar": painted from above, the front and the side, and blended
    // by which way the surface faces, so it never stretches.
    .replace(
      '#include <color_fragment>',
      `#include <color_fragment>
      float paintGrain = 0.5;
      {
        vec3 p = vPaintPos;
        vec3 wN = cross(dFdx(vPaintPos), dFdy(vPaintPos));
        wN = dot(wN, wN) > 1e-12 ? normalize(wN) : vec3(0.0, 1.0, 0.0); // (Leaf cards are flat to the camera.)
        vec3 w = pow(abs(wN), vec3(4.0));
        w /= (w.x + w.y + w.z);
        float patches = paintFbm(p * 0.45);
        // Strokes: long one way, short the other. Down trunks and walls; flicks across the ground.
        float up = paintNoise(vec3(p.x * 1.7, p.z * 7.0, p.y * 0.5)) * w.y;
        float side = paintNoise(vec3(p.z * 6.0, p.y * 1.4, p.x)) * w.x + paintNoise(vec3(p.x * 6.0, p.y * 1.4, p.z)) * w.z;
        float strokes = up + side;
        float fine = paintNoise(p * 9.0);
        paintGrain = strokes;
        float amount = ${brushwork.toFixed(2)} * uPaint;
        vec3 c = diffuseColor.rgb;
        float value = 1.0 + amount * ((patches - 0.5) * 0.34 + (strokes - 0.5) * 0.26 + (fine - 0.5) * 0.08);
        // Warm and cool patches, the way a painter varies the mix as they go.
        vec3 temperature = mix(vec3(0.94, 0.98, 1.08), vec3(1.08, 1.0, 0.9), patches);
        diffuseColor.rgb = c * value * mix(vec3(1.0), temperature, amount * 0.8);
      }`,
    )
    // Wobble the surface direction a little with the brushwork, so light falls in dabs, not smooth plastic.
    .replace(
      '#include <normal_fragment_maps>',
      `#include <normal_fragment_maps>
      {
        vec3 q = vPaintPos * 2.3;
        vec3 wobble = vec3(paintNoise(q), paintNoise(q + 11.3), paintNoise(q + 23.7)) - 0.5;
        normal = normalize(normal + wobble * 0.32 * uPaint);
      }`,
    )
    // Painted light: soft steps, cool violet shadows, warm sunlit sides, a golden rim, matte paint.
    .replace(
      '#include <opaque_fragment>',
      `{
        vec3 albedo = max(material.diffuseColor, vec3(0.004));
        vec3 light = totalDiffuse / albedo; // How much light lands here, whatever the color.
        float level = dot(light, vec3(0.3, 0.59, 0.11));
        vec3 hue = light / max(level, 0.0001);
        // Soft steps, their edges broken up by the brushwork so they look painted, not computed.
        float s = level * ${LIGHT_STEPS.toFixed(1)} + (paintGrain - 0.5) * 0.5;
        float stepped = (floor(s) + smoothstep(0.3, 0.7, fract(s))) / ${LIGHT_STEPS.toFixed(1)};
        float painted = mix(level, stepped, ${STEP_SOFTNESS.toFixed(2)});
        float sunlit = smoothstep(0.2, 1.1, painted);
        vec3 tint = mix(uShadowTint, uLightTint, sunlit);
        // Richer color in the shadows, the way painters push saturation instead of mixing in grey.
        float grey = dot(albedo, vec3(0.3, 0.59, 0.11));
        vec3 rich = mix(vec3(grey), albedo, 1.0 + 0.35 * (1.0 - sunlit));
        vec3 paintedLight = rich * mix(vec3(1.0), hue, 0.6) * max(painted, 0.0) * tint;
        float rim = pow(1.0 - clamp(dot(normal, normalize(vViewPosition)), 0.0, 1.0), 3.0);
        paintedLight += albedo * uRimTint * rim * 0.45 * smoothstep(0.25, 0.9, level);
        // Matte gouache: only glossy things (water) keep much of their shine.
        float shine = mix(1.0, 0.3, smoothstep(0.3, 0.7, material.roughness));
        vec3 paintedOut = paintedLight + totalSpecular * shine + totalEmissiveRadiance;
        outgoingLight = mix(outgoingLight, paintedOut, uPaint);
      }
      #include <opaque_fragment>`,
    );
}

// Every MeshStandardMaterial gets painted, wherever in the game it's made. (Materials that need
// their own shader changes, like the leaves, call paintShader themselves.)
THREE.MeshStandardMaterial.prototype.onBeforeCompile = paintShader;
THREE.MeshStandardMaterial.prototype.customProgramCacheKey = function () {
  return `painted-${this.userData?.paint ?? ''}`;
};

// --- 2. The painted finish over the whole picture ---

// Kuwahara brushwork, ink outlines and paper, in one pass. The Kuwahara filter looks at four
// little squares round each pixel and takes the average color of whichever is most even. Edges
// stay sharp but everything inside them flattens into dabs, which is just what a brush does.
class StorybookEffect extends Effect {
  constructor() {
    super(
      'StorybookEffect',
      /* glsl */ `
      uniform float brush;
      uniform float inkStrength;
      uniform float inkDistance;
      uniform float pixel;
      ${NOISE_GLSL}

      vec3 sector(vec2 uv, vec2 dir, out float variance) {
        vec3 sum = vec3(0.0);
        vec3 sumSq = vec3(0.0);
        float n = 0.0;
        for (int i = 0; i <= ${BRUSH_RADIUS}; i++) {
          for (int j = 0; j <= ${BRUSH_RADIUS}; j++) {
            vec2 offset = vec2(float(i), float(j)) * dir * texelSize * brush;
            vec3 c = texture2D(inputBuffer, uv + offset).rgb;
            sum += c;
            sumSq += c * c;
            n += 1.0;
          }
        }
        vec3 mean = sum / n;
        vec3 v = abs(sumSq / n - mean * mean);
        variance = v.r + v.g + v.b;
        return mean;
      }

      float viewDistance(vec2 uv) {
        return -getViewZ(readDepth(uv));
      }

      void mainImage(const in vec4 inputColor, const in vec2 uv, const in float depth, out vec4 outputColor) {
        // A gentle hand-drawn wobble, so lines and dabs aren't perfectly straight.
        vec2 wobble = (vec2(paintNoise(vec3(uv * 90.0, 1.0)), paintNoise(vec3(uv * 90.0, 7.0))) - 0.5) * texelSize * 2.5 * pixel;
        vec2 p = uv + wobble;

        // Paint dabs (Kuwahara): keep the calmest of four squares round this pixel.
        float v0, v1, v2, v3;
        vec3 m0 = sector(p, vec2(-1.0, -1.0), v0);
        vec3 m1 = sector(p, vec2(1.0, -1.0), v1);
        vec3 m2 = sector(p, vec2(-1.0, 1.0), v2);
        vec3 m3 = sector(p, vec2(1.0, 1.0), v3);
        // Blend by calmness rather than picking one, which keeps the dabs from looking blocky.
        vec4 weight = 1.0 / (pow(vec4(v0, v1, v2, v3) * 400.0, vec4(2.0)) + 0.0001);
        vec3 color = (m0 * weight.x + m1 * weight.y + m2 * weight.z + m3 * weight.w) / (weight.x + weight.y + weight.z + weight.w);

        // Ink outlines where something stands in front of something further back.
        float here = viewDistance(p);
        vec2 t = texelSize * pixel;
        float around = max(max(viewDistance(p + vec2(t.x, 0.0)), viewDistance(p - vec2(t.x, 0.0))),
                           max(viewDistance(p + vec2(0.0, t.y)), viewDistance(p - vec2(0.0, t.y))));
        // (Big jumps only, so blades of grass and leaf clumps don't all get outlined.)
        float gap = around - here;
        float edge = smoothstep(0.1, 0.25, gap / max(here, 0.5)) * smoothstep(0.6, 1.5, gap);
        float near = 1.0 - smoothstep(inkDistance * 0.5, inkDistance, here);
        // The line breaks up here and there, like a pen running dry.
        float pen = smoothstep(0.25, 0.6, paintNoise(vec3(uv * vec2(140.0, 80.0), 3.0)));
        vec3 ink = color * vec3(0.32, 0.24, 0.22);
        color = mix(color, ink, edge * near * pen * inkStrength);

        // Watercolor edges: pigment pools a little darker where one dab meets another.
        float calm = min(min(v0, v1), min(v2, v3));
        color *= 1.0 - clamp(calm * 18.0, 0.0, 0.12);

        outputColor = vec4(color, inputColor.a);
      }
    `,
      {
        attributes: EffectAttribute.CONVOLUTION | EffectAttribute.DEPTH,
        uniforms: new Map([
          ['brush', new THREE.Uniform(1)],
          ['pixel', new THREE.Uniform(1)],
          ['inkStrength', new THREE.Uniform(INK_STRENGTH)],
          ['inkDistance', new THREE.Uniform(INK_DISTANCE)],
        ]),
      },
    );
  }
}

// The color grade and the paper: a warm golden-hour look (cool, violet shadows; honey-gold
// highlights; rich autumn color), soft highlights that never clip to white, and paper grain.
class GradeEffect extends Effect {
  constructor() {
    super(
      'GradeEffect',
      /* glsl */ `
      uniform float grain;
      uniform float pixel;
      ${NOISE_GLSL}
      void mainImage(const in vec4 inputColor, const in vec2 uv, out vec4 outputColor) {
        vec3 c = inputColor.rgb;
        float l = dot(c, vec3(0.3, 0.59, 0.11));
        // Split toning: violet-blue in the darks, honey in the lights.
        c *= mix(vec3(0.9, 0.9, 1.1), vec3(1.0), smoothstep(0.0, 0.35, l));
        c *= mix(vec3(1.0), vec3(1.07, 1.0, 0.87), smoothstep(0.35, 1.0, l));
        // A touch richer overall, and softer at the very top, like paint rather than light.
        c = mix(vec3(l), c, 1.1);
        c = c / (1.0 + max(c - 0.8, 0.0) * 0.6);
        // Paper: fine tooth, and the larger blotches where a wash dried unevenly.
        vec2 px = uv * resolution / pixel;
        float tooth = paintNoise(vec3(px * 0.7, 0.0)) * 0.6 + paintNoise(vec3(px * 0.23, 5.0)) * 0.4;
        float blotch = paintFbm(vec3(uv * vec2(3.0, 2.0), 9.0));
        c *= 1.0 + (tooth - 0.5) * grain * 2.0 + (blotch - 0.5) * grain * 1.2;
        outputColor = vec4(c, inputColor.a);
      }
    `,
      {
        uniforms: new Map([
          ['grain', new THREE.Uniform(PAPER_GRAIN)],
          ['pixel', new THREE.Uniform(1)],
        ]),
      },
    );
  }
}

// Set up the painted renderer. Hand it three.js's renderer; it gives back render(scene, camera, dt)
// and setSize(width, height). It paints or not as the "Painted look" setting says.
export function createPainter(renderer) {
  const composer = new EffectComposer(renderer, {
    frameBufferType: THREE.HalfFloatType, // Room for lights brighter than white, so they can glow.
    multisampling: Math.min(4, renderer.capabilities.maxSamples),
  });
  const placeholder = new THREE.PerspectiveCamera();
  const renderPass = new RenderPass(new THREE.Scene(), placeholder);
  const storybook = new StorybookEffect();
  const bloom = new BloomEffect({ intensity: BLOOM, luminanceThreshold: 0.78, luminanceSmoothing: 0.25, mipmapBlur: true, radius: 0.75 });
  const grade = new GradeEffect();
  const vignette = new VignetteEffect({ offset: 0.32, darkness: 0.5 });
  composer.addPass(renderPass);
  composer.addPass(new EffectPass(placeholder, storybook));
  composer.addPass(new EffectPass(placeholder, bloom, grade, vignette));

  let scene = null;
  let camera = null;

  function setSize(width, height) {
    composer.setSize(width, height);
    // Keep the dabs, lines and grain the same size on a sharp (Retina) screen as on a normal one.
    const pixel = renderer.getPixelRatio();
    storybook.uniforms.get('brush').value = pixel;
    storybook.uniforms.get('pixel').value = pixel;
    grade.uniforms.get('pixel').value = pixel;
  }

  function render(nextScene, nextCamera, dt) {
    paintUniforms.uPaintTime.value += dt;
    paintUniforms.uPaint.value = graphicsSettings.painted ? 1 : 0;
    if (!graphicsSettings.painted) {
      renderer.render(nextScene, nextCamera);
      return;
    }
    if (nextScene !== scene) composer.setMainScene((scene = nextScene));
    if (nextCamera !== camera) composer.setMainCamera((camera = nextCamera));
    composer.render(dt);
  }

  return { render, setSize };
}
