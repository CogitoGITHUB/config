if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = 1,
        manage_window_blur = 1,
        default_theme = "dark",
        default_preset = "clear",

        glass_opacity = 0.75,
        blur_strength = 2.0,
        blur_iterations = 3,
        refraction_strength = 0.6,
        chromatic_aberration = 0.5,
        fresnel_strength = 0.6,
        specular_strength = 0.8,
        edge_thickness = 0.06,
        lens_distortion = 0.5,
        tint_color = 0x8899aa22,
        brightness = 0.82,
        contrast = 0.90,
        saturation = 0.80,
        vibrancy = 0.15,
        adaptive_dim = 0.4,
    })
end