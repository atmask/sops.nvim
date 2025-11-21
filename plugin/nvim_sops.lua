-- nvim_sops.lua - SOPS transparent encryption/decryption plugin
-- Entry point that sets up autocommands for YAML/JSON files

local nvim_sops = require('nvim_sops')

-- Create user commands for manual encryption/decryption
vim.api.nvim_create_user_command('SopsDecrypt', function()
  nvim_sops.decrypt()
end, { desc = 'Manually decrypt current SOPS file' })

vim.api.nvim_create_user_command('SopsEncrypt', function()
  nvim_sops.encrypt()
end, { desc = 'Manually encrypt current SOPS file' })

-- Create autocommand group for SOPS operations
local group = vim.api.nvim_create_augroup('NvimSops', { clear = true })

-- Set up automatic decryption if enabled (default: true)
if nvim_sops.config.auto_decrypt then
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = group,
    pattern = { '*.yaml', '*.yml', '*.json' },
    callback = function(args)
      nvim_sops.decrypt_buffer(args.buf)
    end,
    desc = 'Decrypt SOPS files on open',
  })
end

-- Set up automatic encryption if enabled (default: true)
if nvim_sops.config.auto_encrypt then
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    pattern = { '*.yaml', '*.yml', '*.json' },
    callback = function(args)
      nvim_sops.encrypt_buffer(args.buf)
    end,
    desc = 'Encrypt SOPS files before save',
  })
end

