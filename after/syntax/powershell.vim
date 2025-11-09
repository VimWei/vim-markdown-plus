" PowerShell syntax loader - loads both base and patch syntax

" Clear any existing syntax to avoid conflicts
if exists("b:current_syntax")
  unlet b:current_syntax
endif

" 1. First load the base syntax
runtime! after/syntax/ps1.vim

" 2. Then load the patch syntax
runtime! after/syntax/ps1-patch.vim

" Set the current syntax identifier
let b:current_syntax = "ps1"
