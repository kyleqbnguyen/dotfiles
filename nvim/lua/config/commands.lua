vim.api.nvim_create_user_command("Init", function()
	vim.fn.mkdir("include", "p")
	vim.fn.mkdir("src", "p")
	vim.fn.mkdir("tmp", "p")

	if vim.fn.filereadable("CMakeLists.txt") == 0 then
		vim.fn.writefile({}, "CMakeLists.txt")
	end

	if vim.fn.filereadable(".gitignore") == 0 then
		vim.fn.writefile({
			"build/",
			".cache/",
			"tmp/",
		}, ".gitignore")
	end
end, {})

local function run(command)
	vim.cmd("!" .. command)
end

vim.api.nvim_create_user_command("Cmd", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmdt", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmdtb", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON -DBUILD_BENCH=ON " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmr", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmrt", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmrb", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_BENCH=ON " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmrtb", function(opts)
	run("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -DBUILD_BENCH=ON " .. opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmb", function(opts)
	local args = opts.args ~= "" and (" " .. opts.args) or ""
	run("cmake --build build -j$(nproc)" .. args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("Cmclean", function()
	run("cmake --build build --target clean")
end, {})

vim.api.nvim_create_user_command("Cmt", function(opts)
	run("ctest --test-dir build --output-on-failure " .. opts.args)
end, { nargs = "*" })
