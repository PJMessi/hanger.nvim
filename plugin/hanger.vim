if exists("g:loaded_hanger")
    finish
endif

let g:loaded_hanger = 1

command! -nargs=0 RunTest lua require("hanger").run_test()
command! -nargs=0 ReRunTest lua require("hanger").rerun_test()
command! -nargs=0 RunAllTests lua require("hanger").run_all_tests()
command! -nargs=0 ShowTests lua require("hanger").show_tests()

