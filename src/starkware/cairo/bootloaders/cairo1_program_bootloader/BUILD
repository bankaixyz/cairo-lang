load("//src/starkware/cairo/lang:cairo_rules.bzl", "cairo_binary")

cairo_binary(
    name = "cairo1_program_bootloader",
    cairoopts = [
        "--debug_info_with_source",
        "--proof_mode",
    ],
    compiled_program_name = "cairo1_program_bootloader_compiled.json",
    main = "cairo1_program_bootloader.cairo",
    deps = ["//src/starkware/cairo/bootloaders/simple_bootloader:simple_bootloader_lib"],
)

package(default_visibility = ["//visibility:public"])
