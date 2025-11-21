# nvim_sops

A Neovim plugin for transparent encryption and decryption of [SOPS](https://github.com/mozilla/sops)-encrypted files.

## Features

- **Transparent Decryption**: Automatically decrypts SOPS-encrypted YAML and JSON files when opened
- **Automatic Re-encryption**: Re-encrypts files on save, maintaining encryption keys and metadata
- **Manual Mode**: Optional commands and keybindings for manual encrypt/decrypt operations
- **Graceful Error Handling**: Shows error messages without preventing file access if decryption fails
- **Configurable**: Enable/disable automatic operations as needed
- **Zero Configuration**: Works out of the box with sensible defaults

## Requirements

- Neovim 0.7.0 or later
- [SOPS](https://github.com/mozilla/sops) installed and available in your PATH
- Properly configured encryption keys (GPG, age, AWS KMS, GCP KMS, Azure Key Vault, or HashiCorp Vault)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Default configuration (automatic mode):**
```lua
{
  'atmask/nvim_sops',
  ft = { 'yaml', 'json' },  -- Lazy load on YAML/JSON files
}
```

**Custom configuration (manual mode with keybindings):**
```lua
{
  'atmask/nvim_sops',
  ft = { 'yaml', 'json' },
  opts = {
    auto_decrypt = false,
    auto_encrypt = false,
  },
  keys = {
    { '<leader>sd', '<cmd>SopsDecrypt<cr>', desc = 'Decrypt SOPS file' },
    { '<leader>se', '<cmd>SopsEncrypt<cr>', desc = 'Encrypt SOPS file' },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'atmask/nvim_sops',
  ft = { 'yaml', 'json' },
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'atmask/nvim_sops'
```

### Manual Installation

Clone this repository into your Neovim plugin directory:

```bash
git clone https://github.com/atmask/nvim_sops.git ~/.local/share/nvim/site/pack/plugins/start/nvim_sops
```

## Configuration

By default, the plugin automatically decrypts files when opened and re-encrypts them when saved. You can customize this behavior using the `setup()` function:

```lua
require('nvim_sops').setup({
  -- Enable automatic decryption when opening files (default: true)
  auto_decrypt = true,
  -- Enable automatic encryption when saving files (default: true)
  auto_encrypt = true,
})
```

### Disabling Automatic Operations

If you prefer manual control, disable automatic operations and use commands/keybindings instead:

```lua
require('nvim_sops').setup({
  auto_decrypt = false,
  auto_encrypt = false,
})
```

## Usage

### Automatic Mode (Default)

With default settings, the plugin works transparently:

1. **Opening Files**: When you open a `.yaml`, `.yml`, or `.json` file that contains SOPS metadata, it will be automatically decrypted
2. **Editing**: Edit the decrypted content as you normally would
3. **Saving**: When you save the file, it will be automatically re-encrypted with the same keys

**Example Workflow:**
```bash
# Create a new SOPS-encrypted file
sops secrets.yaml

# Open it in Neovim - it will be automatically decrypted
nvim secrets.yaml

# Edit the content, then save - it will be automatically re-encrypted
:w
```

### Manual Mode

When automatic operations are disabled, use commands or keybindings:

**Commands:**
- `:SopsDecrypt` - Decrypt the current buffer
- `:SopsEncrypt` - Encrypt the current buffer

**Example Keybindings:**
```lua
-- Add to your Neovim config
vim.keymap.set('n', '<leader>sd', '<cmd>SopsDecrypt<cr>', { desc = 'Decrypt SOPS file' })
vim.keymap.set('n', '<leader>se', '<cmd>SopsEncrypt<cr>', { desc = 'Encrypt SOPS file' })
```

**Manual Workflow:**
```bash
# Open an encrypted file
nvim secrets.yaml

# Decrypt it manually
:SopsDecrypt
# or use keybinding: <leader>sd

# Edit the content

# Encrypt it manually before saving
:SopsEncrypt
# or use keybinding: <leader>se

# Save the file
:w
```

## How It Works

The plugin uses Neovim's autocommands to hook into file operations:

- **BufReadPost**: After reading a YAML/JSON file, checks for SOPS metadata and decrypts if present
- **BufWritePre**: Before writing a file that was originally encrypted, re-encrypts the content

The plugin detects SOPS files by looking for the `sops:` metadata block in YAML files or the `"sops":` key in JSON files.

## Error Handling

If decryption fails (e.g., missing encryption keys), the plugin will:
- Display an error message via `vim.notify()`
- Keep the encrypted content in the buffer
- Allow you to view (but not meaningfully edit) the encrypted file

If encryption fails on save, the plugin will:
- Display an error message
- Prevent the save operation to avoid data loss
- Keep the decrypted content in the buffer

## Supported File Formats

- YAML (`.yaml`, `.yml`)
- JSON (`.json`)

## Security Considerations

- Decrypted content exists in memory while editing
- Swap files and undo files contain decrypted content - consider disabling them for sensitive files
- The plugin does not modify SOPS encryption keys or metadata

### Recommended Security Settings

Add this to your Neovim config for files containing sensitive data:

```lua
vim.api.nvim_create_autocmd('BufRead', {
  pattern = { '*/secrets/*', '*secret*.yaml', '*secret*.json' },
  callback = function()
    vim.opt_local.swapfile = false
    vim.opt_local.backup = false
    vim.opt_local.undofile = false
  end,
})
```

## Troubleshooting

### "sops command not found"

Make sure SOPS is installed and in your PATH:

```bash
# Install SOPS
# macOS
brew install sops

# Linux
# Download from https://github.com/mozilla/sops/releases

# Verify installation
sops --version
```

### "Failed to decrypt SOPS file"

This usually means:
- Your encryption keys are not properly configured
- You don't have access to the keys used to encrypt the file
- The file is corrupted

Check your SOPS configuration and ensure you have access to the required keys (GPG, age, etc.).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [SOPS](https://github.com/mozilla/sops) by Mozilla for the encryption tool
- Inspired by the need for secure configuration management in development workflows

