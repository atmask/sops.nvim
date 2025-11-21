-- init.lua - Main SOPS plugin logic

local utils = require('sops.utils')

local M = {}

-- Default configuration
M.config = {
  -- Enable automatic decryption when opening files
  auto_decrypt = true,
  -- Enable automatic encryption when saving files
  auto_encrypt = true,
}

--- Setup function to configure the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Create autocommand group for SOPS operations
  local group = vim.api.nvim_create_augroup('Sops', { clear = true })
  
  -- Set up automatic decryption if enabled
  if M.config.auto_decrypt then
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = group,
      pattern = { '*.yaml', '*.yml', '*.json' },
      callback = function(args)
        M.decrypt_buffer(args.buf)
      end,
      desc = 'Decrypt SOPS files on open',
    })
  end
  
  -- Set up automatic encryption if enabled
  if M.config.auto_encrypt then
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = group,
      pattern = { '*.yaml', '*.yml', '*.json' },
      callback = function(args)
        M.encrypt_buffer(args.buf)
      end,
      desc = 'Encrypt SOPS files before save',
    })
  end
end

--- Manually decrypt the current buffer (for use with keybindings)
function M.decrypt()
  local bufnr = vim.api.nvim_get_current_buf()
  M.decrypt_buffer(bufnr)
end

--- Decrypt a buffer if it contains SOPS-encrypted content
---@param bufnr number Buffer number
function M.decrypt_buffer(bufnr)
  -- Check if sops is available
  if not utils.has_sops() then
    vim.notify('sops command not found. Please install sops.', vim.log.levels.WARN)
    return
  end
  
  -- Check if the buffer contains SOPS metadata
  if not utils.is_sops_file(bufnr) then
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local encrypted_content = table.concat(lines, '\n')
  
  -- Get file format
  local format = utils.get_file_format(bufnr)
  
  -- Decrypt the content
  local success, result = utils.execute_sops({ '--decrypt', '--input-type', format, '--output-type', format, '/dev/stdin' }, encrypted_content)
  
  if success then
    -- Split the result into lines and update the buffer
    local decrypted_lines = vim.split(result, '\n', { plain = true })
    
    -- Remove the last empty line if present
    if decrypted_lines[#decrypted_lines] == '' then
      table.remove(decrypted_lines)
    end
    
    -- Update buffer with decrypted content
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, decrypted_lines)
    
    -- Mark buffer as originally encrypted
    vim.api.nvim_buf_set_var(bufnr, 'is_sops_encrypted', true)
    
    -- Mark buffer as not modified (since we just read it)
    vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    
    vim.notify('SOPS file decrypted successfully', vim.log.levels.INFO)
  else
    -- Decryption failed - keep encrypted content and show error
    vim.notify('Failed to decrypt SOPS file: ' .. result, vim.log.levels.ERROR)
  end
end

--- Manually encrypt the current buffer (for use with keybindings)
function M.encrypt()
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Check if this buffer was previously decrypted (marked with is_sops_encrypted)
  local ok, is_encrypted = pcall(vim.api.nvim_buf_get_var, bufnr, 'is_sops_encrypted')
  
  -- If not already marked as encrypted, check if the file has SOPS metadata
  if not (ok and is_encrypted) and not utils.is_sops_file(bufnr) then
    vim.notify('This file does not have SOPS metadata. Use sops command to initialize it first.', vim.log.levels.WARN)
    return
  end
  
  -- Mark as encrypted so encrypt_buffer will process it
  vim.api.nvim_buf_set_var(bufnr, 'is_sops_encrypted', true)
  
  M.encrypt_buffer(bufnr)
end

--- Encrypt a buffer before saving if it was originally encrypted
---@param bufnr number Buffer number
function M.encrypt_buffer(bufnr)
  -- Check if this buffer was originally encrypted
  local ok, is_encrypted = pcall(vim.api.nvim_buf_get_var, bufnr, 'is_sops_encrypted')
  if not ok or not is_encrypted then
    return
  end
  
  -- Check if sops is available
  if not utils.has_sops() then
    vim.notify('sops command not found. Cannot encrypt file.', vim.log.levels.ERROR)
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local decrypted_content = table.concat(lines, '\n')
  
  -- Get file format
  local format = utils.get_file_format(bufnr)
  
  -- Get the filename - needed for SOPS to match against .sops.yaml rules
  local filename = vim.api.nvim_buf_get_name(bufnr)
  
  if filename == '' then
    vim.notify('Cannot encrypt unnamed buffer. Save the file first.', vim.log.levels.ERROR)
    error('SOPS encryption failed: unnamed buffer')
  end
  
  -- Encrypt the content
  -- Use --filename-override so SOPS can match against .sops.yaml rules even when using stdin
  local success, result = utils.execute_sops({ 
    '--encrypt', 
    '--filename-override', filename,
    '--input-type', format, 
    '--output-type', format, 
    '/dev/stdin' 
  }, decrypted_content)
  
  if success then
    -- Split the result into lines and update the buffer
    local encrypted_lines = vim.split(result, '\n', { plain = true })
    
    -- Remove the last empty line if present
    if encrypted_lines[#encrypted_lines] == '' then
      table.remove(encrypted_lines)
    end
    
    -- Update buffer with encrypted content
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, encrypted_lines)
    
    vim.notify('SOPS file encrypted successfully', vim.log.levels.INFO)
  else
    -- Encryption failed - show error and prevent save
    vim.notify('Failed to encrypt SOPS file: ' .. result, vim.log.levels.ERROR)
    
    -- Throw an error to prevent the write
    error('SOPS encryption failed')
  end
end

return M

