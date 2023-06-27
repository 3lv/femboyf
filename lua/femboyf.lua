local M = {}
-- Default config
M.config = {
	when = 'always',
	style = '1perword',
	color1 = '#b0da6c',
	color2 = '#648424',
}
-- aliases
local a = vim.api
local fn = vim.fn
-- create a namespace used for highlightings
local ns_id = a.nvim_create_namespace('currentline')
-- highlighting groups used: HI[1] for first and HI[2] for second
local HI = { 'FFirst', 'FSecond' }

-- check if character is a word character [1-9,a-z,A-Z] -- removed _
local function is_word(char)
	if char:match('%w') then
		return true
	else
		return false
	end
end

-- Highlight character on line,column with highlight_group = hl_group
local function hl_char(hl_group, line, col)
	-- if any param is nil, exit!
	if hl_group and line and col == nil then
		return
	end
	-- Current buffer (buf_id = 0), namespace_id = ns_id, hl_group
	-- -1 because these start from 0 and were counted them from 1
	-- => line - 1 and the interval to highlight [col-1,col)
	a.nvim_buf_add_highlight(0, ns_id, hl_group, line - 1, col - 1, col)
end

-- Clear namespace 'currentline' in buffer buf or current buffer if not specified
local function Unhighlight_general( buf )
	buf = buf or 0
	-- Current buffer (buf_id = 0), namespace_id, from line 0 to the end(-1)
	a.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
end

-- Highlight a FULL LINE (current line) showing how far(f movments) are the letters(relative to cursor)
-- Optional inDirection, if given 'right' = highlight only in the right of the cursor
-- 'left' the same but in left
local function Highlight_line( inDirection )
	-- Get informations about position
	local line = fn.line('.') -- current line nr(starting from 1)
	local col = fn.col('.') -- current col nr(starting from 1)
	local str = a.nvim_get_current_line() -- current line(string)
	--[1, 2] = doing both right and left,  [1, 1] = right, [2, 2] = left
	local da, db = 1, 2
	if inDirection == 'right' then da, db = 1, 1 end
	if inDirection == 'left' then da, db = 2, 2 end
	for direction = da, db do
		local poz_start, poz_end, step
		local f_letter = {} -- The frequency of each character
		 -- direction = 1 = right => Prepare [col + 1, #str, 1]
		 -- for the next for(going right)
		if direction == 1 then
			poz_start, poz_end, step = col + 1, #str, 1
		-- 2 = left => [col - 1, 1, -1]
		elseif direction == 2 then
			poz_start, poz_end, step = col - 1, 1, -1
		end
		-- go through the positions determined by direction
		for i = poz_start, poz_end, step do
			 -- get the i-th character of the string
			 -- we will operate on it(count how many
			 -- times it appears at one point
			local c = str:sub(i,i)
			-- initialize f_letter with 0 when needed
			if f_letter[c] == nil then f_letter[c] = 0 end
			-- increment the frequency
			f_letter[c] = f_letter[c] + 1
			-- if frequency <= 2 aka it's in the first 2 characters of that type
			-- aka it's not too far
			if f_letter[c] <= 2 then
				-- highlight with HI[1] if first or HI[2] if second
				hl_char(HI[f_letter[c]], line, i)
			end
		end
	end
end

-- Same as Highlight_line() but only 1 highlight per word
local function Highlight_line_per_word( inDirection )
	local line = fn.line('.')
	local col = fn.col('.')
	local str = a.nvim_get_current_line()
	local da, db = 1, 2
	if inDirection == 'right' then da, db = 1, 1 end
	if inDirection == 'left' then da, db = 2, 2 end
	for direction = da,db do
		local f_letter = {}
		local first_f1, first_f2 -- nil
		local in_initial_word = true
		if is_word(str:sub(col,col)) == false then
			in_initial_word = false
		end
		local poz_start, poz_end, step;
		if direction == 1 then -- in right
			poz_start, poz_end, step = col + 1, #str, 1
		elseif direction == 2 then -- in left
			poz_start, poz_end, step = col - 1, 1, -1
		end
		for i = poz_start, poz_end, step do
			local c = str:sub(i,i)
			if f_letter[c] == nil then f_letter[c] = 0 end
			f_letter[c] = f_letter[c] + 1
			-- if we are not on a word character that means we left a word
			if is_word(c) == false then
				-- because we just left a word, we can't be in the initial word
				in_initial_word = false
				if first_f1 ~= nil then
					hl_char(HI[1], line, first_f1)
				elseif first_f2 ~= nil then
					hl_char(HI[2], line, first_f2)
				end
				first_f1, first_f2 = nil, nil
			else
				-- check if we are not in the initial word
				-- (don't highlight anything in initial word)
				if in_initial_word == false then
					if f_letter[c] == 1 and first_f1 == nil then
						first_f1 = i
					end
					if f_letter[c] == 2 and first_f2 == nil then
						first_f2 = i
					end
				end
			end
		end
		if in_initial_word == false then
			if first_f1 ~= nil then
				hl_char(HI[1], line, first_f1)
			elseif first_f2 ~= nil then
				hl_char(HI[2], line, first_f2)
			end
		end
	end
end

-- Chooses the correct function to highlight with
-- if necessay (check for mode)
local function Refresh_Highlight( inDirection )
	-- unhighlight the previous buffer if valid
	-- (the buffer before cursor moved or other events)
	if vim.api.nvim_buf_is_valid(PreviousBuffer) then
		Unhighlight_general(PreviousBuffer)
	end
	-- if only called for clearing
	if inDirection == 'clear' then
		return 'cleared'
	end
	-- sets the PreviousBuffer for the next function call
	PreviousBuffer = vim.fn.bufnr('%')
	-- do not highlight in terminal buffers
	if vim.api.nvim_buf_get_option(vim.fn.bufnr('%'), 'buftype') == 'terminal' then
		return
	end
	local mode = vim.fn.mode()
	-- modes that require highlighting
	local modes_to_highlight = {
		n = true,
		v = true,
		V = true,
		[''] = true,
	}
	-- if one of the modes above choose
	-- the function used for highlighting
	if modes_to_highlight[mode] ~= nil then
		if M.config.style == '1perword' then
			Highlight_line_per_word( inDirection )
		elseif M.config.style == 'line' then
			Highlight_line( inDirection )
		end
	end
end

local async_refresh_request = vim.loop.new_async(vim.schedule_wrap(Refresh_Highlight))
local function async_refresh_call() async_refresh_request:send() end

-- Setup function, used to setup everything for the plugin.
-- Optionally may use 'user_config' as configuration
--
-- initialize variables
-- links the highlighting groups if they don't exist,
-- sets autocommands for runnying functions when needed
-- may refresh highlighting for instant results
--
M.setup = function  ( user_config )
	M.config = vim.tbl_deep_extend("force", M.config, user_config or { })
	PreviousBuffer = 0
	if M.config.when == 'always' then
		vim.cmd(string.format([[
		augroup femboyf
		autocmd!
		autocmd CursorMoved,InsertEnter,InsertLeave,FocusGained * lua require('femboyf').async_refresh()
		autocmd FocusLost * lua require('femboyf').refresh('clear')
		autocmd ColorScheme * hi FFirst guifg=%s ctermfg=Green
		autocmd ColorScheme * hi FSecond guifg=%s ctermfg=DarkGreen
		augroup END
		]], M.config.color1, M.config.color2))
		require('femboyf').async_refresh()
	end
end

-- Aliases that can be used by requiring this file
M.async_refresh = async_refresh_call
M.refresh = Refresh_Highlight

return M
