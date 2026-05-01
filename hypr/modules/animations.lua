hl.config({
    animations = {
        enabled = true,

        -- ── Bézier curves ──────────────────────────────────────────────
        beziers = {
            cinema   = { 0.25, 0.46, 0.45, 0.94 },
            weight   = { 0.34, 1.26, 0.64, 1     },
            snappy   = { 0.23, 1,    0.32, 1      },
            exit     = { 0.55, 0,    1,    0.45   },
            momentum = { 0.16, 1,    0.3,  1      },
        },

        animations = {
            -- ── Global fallback ────────────────────────────────────────────
            { name = "global",        enable = true, speed = 4,   curve = "cinema"                        },

            -- ── Border ─────────────────────────────────────────────────────
            { name = "border",        enable = true, speed = 8,   curve = "cinema"                        },

            -- ── Windows ────────────────────────────────────────────────────
            { name = "windows",       enable = true, speed = 3.5, curve = "weight",   style = "slide"     },
            { name = "windowsIn",     enable = true, speed = 3.5, curve = "weight",   style = "slide"     },
            { name = "windowsOut",    enable = true, speed = 2,   curve = "exit",     style = "slide"     },
            { name = "windowsMove",   enable = true, speed = 3,   curve = "cinema",   style = "slide"     },

            -- ── Fade ───────────────────────────────────────────────────────
            { name = "fade",          enable = true, speed = 3.5, curve = "cinema"                        },
            { name = "fadeIn",        enable = true, speed = 4,   curve = "cinema"                        },
            { name = "fadeOut",       enable = true, speed = 2,   curve = "exit"                          },

            -- ── Layers ─────────────────────────────────────────────────────
            { name = "layers",        enable = true, speed = 3,   curve = "cinema",   style = "slide"     },
            { name = "layersIn",      enable = true, speed = 3,   curve = "weight",   style = "slide"     },
            { name = "layersOut",     enable = true, speed = 1.8, curve = "exit",     style = "slide"     },
            { name = "fadeLayersIn",  enable = true, speed = 3.5, curve = "cinema"                        },
            { name = "fadeLayersOut", enable = true, speed = 1.8, curve = "exit"                          },

            -- ── Workspaces ─────────────────────────────────────────────────
            { name = "workspaces",    enable = true, speed = 4,   curve = "momentum", style = "slidefade 20%" },
            { name = "workspacesIn",  enable = true, speed = 4,   curve = "momentum", style = "slidefade 20%" },
            { name = "workspacesOut", enable = true, speed = 2.5, curve = "exit",     style = "slidefade 20%" },

            -- ── Zoom (scrolling layout) ────────────────────────────────────
            { name = "zoomFactor",    enable = true, speed = 4,   curve = "cinema"                        },
        },
    },
})