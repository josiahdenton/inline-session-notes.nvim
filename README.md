# inline-session-notes.nvim

Create inline notes for your nvim session.

> [!caution]
> plugin still in a "draft" state.

## Install


#### [Lazy](https://github.com/folke/lazy.nvim)

```lua
{
    "josiahdenton/inline-session-notes.nvim",
    config = function()
        local inline = require("inline-session-notes")
        inline.setup({
            border = true, -- if you want your notes to have borders
        })

        vim.keymap.set("n", "<leader>ta", function()
            inline.add()
        end)

        vim.keymap.set("n", "<leader>te", function()
            inline.edit()
        end)

        vim.keymap.set("n", "<leader>td", function()
            inline.delete()
        end)
    end,
},
```
