return {
	include_dir = {os.getenv"HOME" .. "/dev/teal-types/types/neovim/"},
	preload_modules = {"vim"},
	skip_compat53 = true,
	source_dir = "teal",
	build_dir = "lua"
}
