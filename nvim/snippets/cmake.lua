local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local sn = ls.snippet_node
local rep = require("luasnip.extras").rep
local ai = require("luasnip.nodes.absolute_indexer")

local function projectMacroName(args)
	local name = args[1][1] or ""
	return name:upper():gsub("[^%w]", "_")
end

local function buildTestsOption(ref)
	return f(function(args)
		return projectMacroName(args) .. "_BUILD_TESTS"
	end, { ref })
end

local function bodySubLib()
	return sn(nil, {
		t({ 'file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "*.cpp")', "", "add_library(${PROJECT_NAME}_" }),
		i(1, "name"),
		t({ " STATIC ${SOURCES})", "", "target_include_directories(${PROJECT_NAME}_" }),
		rep(1),
		t({ "", "                          PUBLIC ${CMAKE_SOURCE_DIR}/src", ")", "", "add_library(${PROJECT_NAME}::" }),
		rep(1),
		t(" ALIAS ${PROJECT_NAME}_"),
		rep(1),
		t(")"),
	})
end

local function bodySubExe()
	return sn(nil, {
		t({ 'file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "*.cpp")', "", "add_executable(${PROJECT_NAME}_" }),
		i(1, "name"),
		t({ " ${SOURCES})", "", "target_link_libraries(${PROJECT_NAME}_" }),
		rep(1),
		t(" PRIVATE ${PROJECT_NAME})"),
	})
end

local function bodyExecutable()
	return sn(nil, {
		t({
			'file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "src/*.cpp")',
			"",
			"add_executable(${PROJECT_NAME} ${SOURCES})",
			"",
			"target_include_directories(${PROJECT_NAME}",
			"                           PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)",
			"",
			"target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)",
		}),
	})
end

local function bodyTestedLibrary()
	return sn(nil, {
		t("option("),
		buildTestsOption(ai[2]),
		t(' "Build tests" '),
		c(1, { t("ON"), t("OFF") }),
		t({ ")", "", "" }),
		t({
			'file(GLOB_RECURSE LIB_SOURCES CONFIGURE_DEPENDS "src/*.cpp")',
			"",
			"add_library(${PROJECT_NAME} ${LIB_SOURCES})",
			"",
			"target_include_directories(",
			"  ${PROJECT_NAME} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>",
			"                         $<INSTALL_INTERFACE:include>)",
			"",
			"target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)",
			"",
			"if(",
		}),
		buildTestsOption(ai[2]),
		t({
			")",
			"  enable_testing()",
			"  add_subdirectory(tests)",
			"endif()",
		}),
	})
end

local function bodyLibPlusExe()
	return sn(nil, {
		t("option("),
		buildTestsOption(ai[2]),
		t(' "Build tests" '),
		c(1, { t("ON"), t("OFF") }),
		t({ ")", "", "" }),
		t({
			'file(GLOB_RECURSE LIB_SOURCES CONFIGURE_DEPENDS "src/*.cpp")',
			"",
			"add_library(${PROJECT_NAME}_lib ${LIB_SOURCES})",
			"",
			"target_include_directories(",
			"  ${PROJECT_NAME}_lib",
			"  PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)",
			"",
			"target_compile_options(${PROJECT_NAME}_lib PRIVATE -Wall -Wextra -Wpedantic)",
			"",
			"add_executable(${PROJECT_NAME} app/main.cpp)",
			"target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_lib)",
			"",
			"if(",
		}),
		buildTestsOption(ai[2]),
		t({
			")",
			"  enable_testing()",
			"  add_subdirectory(tests)",
			"endif()",
		}),
	})
end

local function bodySubModules()
	return sn(nil, {
		t("option("),
		buildTestsOption(ai[2]),
		t(' "Build tests" '),
		c(1, { t("ON"), t("OFF") }),
		t({ ")", "", "" }),
		t({
			"list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)",
			"include(deps)",
			"",
			"add_subdirectory(src)",
			"",
			"if(",
		}),
		buildTestsOption(ai[2]),
		t({
			")",
			"  enable_testing()",
			"  add_subdirectory(tests)",
			"endif()",
		}),
	})
end

return {
	s("file", {
		t("file(GLOB_RECURSE "),
		i(1, "SOURCES"),
		t(' CONFIGURE_DEPENDS "'),
		i(2, "*.cpp"),
		t('")'),
	}),

	s("cms", {
		c(1, { t("# lib"), t("# exe") }),
		t({ "", "" }),
		d(2, function(args)
			if args[1][1] == "# lib" then
				return bodySubLib()
			else
				return bodySubExe()
			end
		end, { 1 }),
	}),

	--- cm: shared-top CMake with body cycling
	s("cm", {
		t("cmake_minimum_required(VERSION "),
		i(1, "3.20"),
		t({ ")", "project(", "  " }),
		i(2, "name"),
		t({ "", "  VERSION " }),
		i(3, "0.0.0"),
		t({ "", '  DESCRIPTION "' }),
		i(4, "desc"),
		t({ '"', "  LANGUAGES CXX)", "", "" }),
		t("set(CMAKE_CXX_STANDARD "),
		c(5, { t("20"), t("23"), t("17") }),
		t({
			")",
			"set(CMAKE_CXX_STANDARD_REQUIRED ON)",
			"set(CMAKE_CXX_EXTENSIONS OFF)",
			"set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
			"",
			"",
		}),
		t({ "if(NOT CMAKE_BUILD_TYPE)", "  set(CMAKE_BUILD_TYPE " }),
		c(6, { t("Debug"), t("Release") }),
		t({ ")", "endif()", "", "# " }),
		c(7, {
			t("exe"),
			t("lib"),
			t("lib+exe"),
			t("submodules"),
		}),
		t({ "", "" }),
		d(8, function(args)
			local mode = args[1][1]
			if mode == "lib" then
				return bodyTestedLibrary()
			elseif mode == "lib+exe" then
				return bodyLibPlusExe()
			elseif mode == "exe" then
				return bodyExecutable()
      else
				return bodySubModules()
			end
		end, { 7 }),
	}),

	--- cmh: header-only library
	s("cmh", {
		t("cmake_minimum_required(VERSION "),
		i(1, "3.20"),
		t({ ")", "project(" }),
		i(2, "my_header_lib"),
		t(" VERSION "),
		i(3, "0.1.0"),
		t({ " LANGUAGES CXX)", "", "" }),
		t({
			"add_library(${PROJECT_NAME} INTERFACE)",
			"",
			"target_include_directories(${PROJECT_NAME}",
			"    INTERFACE",
			"        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>",
			"        $<INSTALL_INTERFACE:include>",
			")",
			"",
			"target_compile_features(${PROJECT_NAME} INTERFACE cxx_std_",
		}),
		c(4, { t("20"), t("23"), t("17") }),
		t({ ")", "", "" }),
		t("option("),
		buildTestsOption(2),
		t(' "Build tests" '),
		c(5, { t("ON"), t("OFF") }),
		t({ ")", "" }),
		t("if("),
		buildTestsOption(2),
		t({
			" AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)",
			"    enable_testing()",
			"    add_subdirectory(tests)",
			"endif()",
		}),
	}),

	--- cmg: tests or bench CMakeLists.txt with FetchContent
	s("cmg", {
		t({ "include(FetchContent)", "", "FetchContent_Declare(", "  " }),
		c(1, { t("googletest"), t("googlebenchmark") }),
		d(2, function(args)
			if args[1][1] == "googletest" then
				return sn(nil, {
					t({
						"",
						"  GIT_REPOSITORY https://github.com/google/googletest.git",
						"  GIT_TAG ",
					}),
					i(1, "v1.14.0"),
					t({ "", ")", "FetchContent_MakeAvailable(googletest)", "", "" }),
					t({ 'file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS "*.cpp")', "", "add_executable(" }),
					i(2, "${PROJECT_NAME}_tests"),
					t({ " ${TEST_SOURCES})", "", "" }),
					t("target_link_libraries("),
					rep(2),
					t(" PRIVATE "),
					i(3, "${PROJECT_NAME}"),
					t({ "", "                                                    GTest::gtest_main)", "", "" }),
					t({ "include(GoogleTest)", "gtest_discover_tests(" }),
					rep(2),
					t(")"),
				})
			else
				return sn(nil, {
					t({
						"",
						"  GIT_REPOSITORY https://github.com/google/benchmark.git",
						"  GIT_TAG ",
					}),
					i(1, "v1.9.1"),
					t({
						")",
						"",
						"set(BENCHMARK_ENABLE_TESTING OFF)",
						"FetchContent_MakeAvailable(googlebenchmark)",
						"",
						'file(GLOB_RECURSE BENCH_SOURCES CONFIGURE_DEPENDS "*.cpp")',
						"",
						"add_executable(${PROJECT_NAME}_bench ${BENCH_SOURCES})",
						"",
						"target_link_libraries(${PROJECT_NAME}_bench PRIVATE ${PROJECT_NAME}",
						"                                                    benchmark::benchmark_main)",
					}),
				})
			end
		end, { 1 }),
	}),
}
