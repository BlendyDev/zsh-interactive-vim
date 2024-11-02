# zsh-interactive-vim

## Installation

#### 1. Install [fzf](https://github.com/junegunn/fzf)
#### 2. Install [bat](https://github.com/sharkdp/bat)
#### 3. (Manual)
- Clone this repo somewhere and source `zsh-interactive-vim.plugin.zsh` in your `.zshrc`
#### 3. ([Oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) plugin)
- Run this command
`rm -rf ~/.oh-my-zsh/plugins/zsh-interactive-vim; git clone git@github.com:BlendyDev/zsh-interactive-vim.git ~/.oh-my-zsh/plugins/zsh-interactive-vim`
- Add `zsh-interactive-vim` to your plugins array in your `.zshrc`
#### 4. Restart your shell or `source .zshrc`

## Usage

    Use tab to auto-complete to directories/files while typing your *vim command.

## Flags (set as env variables)
   
   `ziv_custom_keybind`: Changes keybind to trigger completion (^I (TAB)) by default 

   `ziv_regex`: Custom regex pattern to match programs (default: `.?vim`)

   `ziv_file_preview`: Program to use for previewing files (default: `ls`)
   `ziv_file_preview_flags`: Array of flags to pass to file preview program (default: `()`)

   `ziv_dir_preview`: Program to use for previewing directories (default: `bat`)
   `ziv_dir_preview_flags`: Array of flags to pass to directory preview program (default: `("--color=always")`)

   `ziv_case_insensitive`: Case insensitive matching (set to `"true"` to enable)

   `__ziv_default_completion`: Fallback TAB completion when ziv is not applicable **(only change if you know what you are doing)**

## Warnings
   - If you use fzf shell integration, be sure to enable that in your `.zshrc` BEFORE enabling this plugin 
   - Enable this plugin after any plugin that might take over the TAB binding and not fallback properly (like `zsh-interactive-cd`)

