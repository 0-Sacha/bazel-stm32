"""
"""

def _impl_stm32_flash(ctx):
    st_flash_executable = ""
    if len(ctx.files._st_flash_folder_script) == 0:
        # If we use the local binary of st-flash
        st_flash_executable = "st-flash"
    else:
        # Else, use the provided one
        st_flash_executable = ctx.files._st_flash_folder_script[0].path

    ctx.actions.write(
        output = ctx.outputs.flash_script,
        is_executable = True,
        content = "{st_flash} write {binary} {address}".format(
            st_flash = st_flash_executable,
            binary = ctx.attr.binary[OutputGroupInfo].bin.to_list()[0].path,
            address = ctx.attr.flash_address,
        )
    )
    return [
        DefaultInfo(
            files = depset([ ctx.outputs.flash_script ])
        )
    ]

_gen_stm32_flash_script = rule(
    implementation = _impl_stm32_flash,
    attrs = {
        "flash_script": attr.output(),
        "_st_flash_folder_script": attr.label(default = Label("@bazel_stm32//flash:st_flash_executable")),

        "binary": attr.label(),
        "flash_address": attr.string(),
    },
    provides = [DefaultInfo],
)

def stm32_flash(
        name,
        binary,
        flash_address = "0x08000000",
    ):
    """ stm32_flash rule

    Args:
        name: rule name to call for flash
        binary: binary rule to flash (should be an stm32_binary rule)
        flash_address: The program adress in flash memory
    """
    _gen_stm32_flash_script(
        name = name + "_flash_script",
        flash_script = name + ".flash_script.sh",
        binary = binary,
        flash_address = flash_address,
    )

    native.sh_binary(
        name = name,
        srcs = [ name + ".flash_script.sh" ],
        data = [
            "@bazel_stm32//flash:st_flash_executable",
            binary,
            ":" + name + ".flash_script.sh",
        ],
    )
