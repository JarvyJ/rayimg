return {
   build_dir = "build",
   source_dir = "src",
   gen_compat = "off",
   include_dir = {"src/_types", "src/lua_libs"},
   dont_prune = {"build/libs/*.so"},
}
