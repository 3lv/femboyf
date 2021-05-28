# femboyf
Blazingly fast highlighting for unique characters on a line, helping you using <kbd>f</kbd>, <kbd>F</kbd>, <kbd>t</kbd>, <kbd>T</kbd> **super easily**

**Requires neovim 0.5.0+**

## Install
* packer.nvim
```lua
use {
	'3lv/femboyf',
	-- Your configuration function
	config = function() require'femboyf'.setup{} end
}
```
### Maybe add some custom config?
```lua
require('femboyf').setup {
	-- These are all optional
	-- change the defaults here:

	-- When to highlight?
	-- 'always'             always in normal and visual mode (default)
	-- 'onkeypress'         only when f,F,t,T are pressed (not implemented yet)
	when = 'always',

	-- How to highlight?
	-- '1perword':          1 character per word (default)
	-- 'line':              all possible characters in a line
	style = '1perword',

	-- What colors to use? #HEX / default vim colors
	color1 = '#b0da6c',
	color2 = '#648424',
}
```
