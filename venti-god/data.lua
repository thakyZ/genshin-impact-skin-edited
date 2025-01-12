local skins_factored = require("skins_factored")
VENTI_GOD = {}; ---@type table
VENTI_GOD.is_debug = false ---@type boolean
local shared = require("shared") ---@type table
local char_name = shared.charname ---@type string

-- Setup new animations, etc
local GRAPHICS_PATH = "__venti-god__/graphics/" ---@type string
local SR_IMG_PATH = GRAPHICS_PATH.."SR/" ---@type string
local HR_IMG_PATH = GRAPHICS_PATH.."HR/" ---@type string

skins_factored.create_skin(char_name, {
  icon       = GRAPHICS_PATH.."icon.png",
  reflection = GRAPHICS_PATH.."character-reflection.png",
  armor_animations = {
    idle = {
      layers = {
        {
          filename = SR_IMG_PATH.."idle.png",
          width = 400,
          height = 400,
          shift = util.by_pixel(0.0,-400.0),
          frame_count = 22,
          direction_count = 20,
          animation_speed = 0.15,
          hr_version = {
            filename    = HR_IMG_PATH.."idle.png",
            frame_count = 22,
            size        = 128,
            scale       = 0.15,
          }
        }
      }
    },
    idle_with_gun = {
      layers = {
        {
          filename = SR_IMG_PATH.."idle-with-gun.png",
          width = 400,
          height = 400,
          shift = util.by_pixel(0.0,-400.0),
          frame_count = 20,
          direction_count = 8,
          animation_speed = 0.15,
          hr_version = {
            filename    = HR_IMG_PATH.."idle-with-gun.png",
            frame_count = 20,
            size        = 128,
            scale       = 0.15,
          },
        },
      },
    },
    running = {
      layers = {
        {
          filename = SR_IMG_PATH.."running.png",
          width = 400,
          height = 400,
          shift = util.by_pixel(0.0,-400.0),
          frame_count = 60,
          direction_count = 8,
          animation_speed = 0.15,
          hr_version = {
            filename    = HR_IMG_PATH.."running.png",
            frame_count = 60,
            size        = 128,
            scale       = 0.15,
          },
        },
      },
    },
    running_with_gun = {
      layers = {
        {
          filename = SR_IMG_PATH.."running-with-gun.png",
          width = 400,
          height = 400,
          shift = util.by_pixel(0.0,-400.0),
          frame_count = 60,
          direction_count = 8,
          animation_speed = 0.15,
          hr_version = {
            filename    = HR_IMG_PATH.."running-with-gun.png",
            frame_count = 60,
            size        = 128,
            scale       = 0.15,
          },
        },
      },
    },
    mining_with_tool = {
      layers = {
        {
          filename = SR_IMG_PATH.."mining-with-tool.png",
          width = 400,
          height = 400,
          shift = util.by_pixel(0.0,-400.0),
          frame_count = 20,
          direction_count = 8,
          animation_speed = 0.15,
          hr_version = {
            filename    = HR_IMG_PATH.."mining-with-tool.png",
            frame_count = 20,
            size        = 128,
            scale       = 0.15,
          },
        },
      },
    },
  },
  corpse_animations = {
    layers = {
      {
        filename = SR_IMG_PATH.."dead.png",
        width = 400,
        height = 400,
        shift = util.by_pixel(0.0,-21.0),
        frame_count = 22,
        direction_count = 8,
        animation_speed = 0.15,
        hr_version = {
          filename    = HR_IMG_PATH.."dead.png",
          frame_count = 2,
          size        = 128,
          scale       = 0.15,
        },
      },
    },
  },
})

local shift = util.by_pixel(-0.5,-34.5) ---@type Vector.1

local animation_base = { ---@type AnimationPrototype
  filename = HR_IMG_PATH.."jetpack.png",
  width = 256,
  height = 256,
  line_length = 4,
  shift = shift,
  frame_count = 1,
  direction_count = 32,
  animation_speed = 0.6,
  scale = 0.5
}
local animation_mask = { ---@type AnimationPrototype
  apply_runtime_tint = true,
  filename = HR_IMG_PATH.."jetpack-mask.png",
  width = 256,
  height = 256,
  line_length = 4,
  shift = shift,
  frame_count = 1,
  direction_count = 32,
  animation_speed = 0.6,
  scale = 0.5
}
local animation_flame = { ---@type AnimationPrototype
  draw_as_glow = true,
  filename = HR_IMG_PATH.."jetpack-flame.png",
  width = 256,
  height = 256,
  line_length = 4,
  shift = shift,
  frame_count = 1,
  direction_count = 32,
  animation_speed = 0.6,
  scale = 0.5
}
local animation_layers = { ---@type Array<Animation>
  animation_base,
  animation_mask,
  animation_flame
}

-- make rendering animations
for i, name in pairs({"jetpack-animation", "jetpack-animation-mask", "jetpack-animation-flame"}) do
  local set = table.deepcopy(animation_layers[i]) ---@type AnimationPrototype
  set.type = "animation"
  set.name = char_name.."-"..name
  set.apply_runtime_tint = true
  set.direction_count = 1
  set.frame_count = 32
  if i == 3 then
    set.blend_mode = "additive"
  end
  data:extend({ [0] = set })
end

local jetpack_shadow = { ---@type RotatedAnimation
  type = "animation",
  name = char_name.."jetpack-animation-shadow",
  draw_as_shadow = true,
  filename = HR_IMG_PATH.."jetpack-shadow.png",
  width = 256,
  height = 256,
  line_length = 4,
  shift = util.by_pixel(2,0),
  direction_count = 1,
  frame_count = 32,
  animation_speed = 0.6,
  scale = 0.5
}

data:extend({ [0] = jetpack_shadow })