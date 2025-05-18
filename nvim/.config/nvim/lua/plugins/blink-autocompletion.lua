if true then
  return {}
end
return {
  "saghen/blink.cmp",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_and_accept" },
    },
  },
}
