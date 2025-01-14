# inline-session-notes.nvim

Create inline notes for your nvim session.

> [!caution]
> while you can use the plugin, it may not be bug free! file an issue if you find anything (or open a PR)

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

## Usage

<img width="1512" alt="image" src="https://github.com/user-attachments/assets/7405e3d5-2023-4f8e-b389-44cd94ed8b26" />

<img width="1512" alt="image" src="https://github.com/user-attachments/assets/8b5208ea-fa16-4339-b60a-1c4812db1b0c" />

### Demo

https://github.com/user-attachments/assets/af564b23-5bc6-43d4-a8e2-5c3ca7c2d31e



