"""
"""

def _impl_stm32_flash(ctx):
    if len(ctx.files._st_flash_folder_script) == 0:
        # If we use the local binary of st-flash
        st_flash_executable = "st-flash"
    else:
        # Else, use the provided one
        st_flash_executable = ctx.files._st_flash_folder_script[0].path

    binary = ctx.attr.binary[OutputGroupInfo].bin.to_list()[0]
    script_content = "{st_flash} write {binary} {address}".format(
        st_flash = st_flash_executable,
        binary = binary.path,
        address = ctx.attr.flash_address,
    )

    flash_extention = ".sh"
    if ctx.configuration.host_path_separator == '\\':
        flash_extention = ".bat"

    flasher_wrapper = ctx.actions.declare_file(ctx.label.name + flash_extention)
    ctx.actions.write(
        output = flasher_wrapper,
        is_executable = True,
        content = script_content,
    )

    runfiles = ctx.runfiles([flasher_wrapper, binary])
    return [
        DefaultInfo(
            executable = flasher_wrapper,
            default_runfiles = runfiles,
        )
    ]

stm32_flash = rule(
    implementation = _impl_stm32_flash,
    attrs = {
        "binary": attr.label(mandatory = True),
        "flash_address": attr.string(default = "0x08000000"),

        "_st_flash_folder_script": attr.label(default = Label("@bazel_stm32//flash:st_flash_executable")),
    },
    provides = [DefaultInfo],
)
