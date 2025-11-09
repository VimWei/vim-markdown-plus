" ~/.vim/after/syntax/ps1-patch.vim
" PowerShell syntax patch - enhancements only

if !exists("b:current_syntax_ps1_patch_loaded")
  let b:current_syntax_ps1_patch_loaded = 1

  " Define high-frequency aliases and short commands
  syn keyword ps1Alias contained irm iex iwr curl wget gal gci gp gl gm gwmi sls select where sort group measure foreach %
  syn keyword ps1Alias contained cat cd cp mv rm ls man mkdir ps kill history cls clear echo exit pwd popd pushd diff mount

  " Enhanced function and command matching
  syn match ps1Function /\<\w\+\>/ contains=ps1Cmdlet,ps1Alias

  " Network-related commands with prominent highlighting
  syn keyword ps1NetCommand contained Invoke-RestMethod Invoke-Expression Invoke-WebRequest
  syn match ps1NetCommand /\<(irm\|iex\|iwr)\>/ contained
  syn match ps1Function /\<\w\+\>/ contains=ps1Cmdlet,ps1Alias,ps1NetCommand

  " Highlight linking
  hi def link ps1Alias Function
  hi def link ps1NetCommand Special
endif
