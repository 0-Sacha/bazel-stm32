"""
"""

load("@%{arm_none_eabi_repo_name}//:rules.bzl", "arm_binary")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def stm32_platform(name = "%{MCU_ID}"):
    native.platform(
        name = name,
        constraint_values = %{toolchain_mcu_constraint},
    )

    # TODO: Check whether an constraint_value can be usefull
    # native.constraint_value(name = "%{MCU_ID}", constraint_setting = "")

def stm32_binary(
        name,
        ldscript,
        startupfile,
        deps = [],
        linkopts = [],
        **kwargs
    ):
    """stm32_toolchain

    Args:
        name: The output binaries name
        ldscript: ldscript
        startupfile: startupfile

        deps: The deps list to forward to arm_binary -> cc_binary
        linkopts: linkopts
        **kwargs: All others arm_binary attributes
    """
    maybe(
        native.cc_library,
        name = "%{MCU_ID}_startup",
        srcs = [ startupfile ],
        copts = [ "-x", "assembler-with-cpp" ],
        target_compatible_with = %{target_compatible_with},
        visibility = ["//visibility:public"],
    )

    arm_binary(
        name = name,
        deps = [ "%{MCU_ID}_startup" ] + deps,
        linkopts = [ "-T{}".format(ldscript) ] + linkopts,
        target_compatible_with = %{target_compatible_with},
        **kwargs,
    )
