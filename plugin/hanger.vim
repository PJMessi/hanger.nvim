if exists("g:loaded_hanger")
    finish
endif

let g:loaded_hanger = 1

command! -nargs=0 RunSingleTest lua require("hanger").run_single_test()
command! -nargs=0 RerunTest lua require("hanger").rerun_test()
command! -nargs=0 RunFileTests lua require("hanger").run_tests_in_file()
command! -nargs=0 ShowRunnables lua require("hanger").show_runnables()

