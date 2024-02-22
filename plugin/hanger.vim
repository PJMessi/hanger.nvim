if exists("g:loaded_hanger")
    finish
endif

let g:loaded_hanger = 1

command! -nargs=0 Greet lua require("hanger").greet()
command! -nargs=0 CPath lua require("hanger").copyAbsPath()
