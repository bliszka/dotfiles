return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      menu = {
        auto_show = true,
        border = "rounded",
        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
      },
      documentation = { window = { border = "rounded" } },
      trigger = {
        show_on_keyword = true,
        show_on_trigger_character = true,
      },
      ghost_text = {
        enabled = true,
      },
    },
    signature = {
      enabled = false,
      window = { border = "rounded" },
    },
  },
}
