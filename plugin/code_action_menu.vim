function! s:CodeActionFromSelected(type)
  call luaeval("require('code_action_menu').open_code_action_menu(_A)", a:type)
endfunction

vnoremap <silent> <Plug>(coc-codeaction-selected-menu)   <CMD>call luaeval("require('code_action_menu').open_code_action_menu(_A)", visualmode())<CR>
nnoremap <silent> <Plug>(coc-codeaction-selected-menu)   <CMD>set operatorfunc=<SID>CodeActionFromSelected<CR>g@
