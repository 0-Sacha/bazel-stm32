"""
"""

load("@%{arm_none_eabi_repo_name}//:rules.bzl", "arm_none_eabi_binary")

def stm32_binary(name, deps = [], **kwargs):
    """stm32_toolchain

    Args:
        name: The output binaries name
        deps: The deps list to forward to arm_none_eabi_binary -> cc_binary
        **kwargs: All others arm_none_eabi_binary attributes
    """
    arm_none_eabi_binary(
        name = name,
        deps = [ "%{MCU_ID}_startup" ] + deps,
        target_compatible_with = json.decode(target_compatible_with_packed),
        **kwargs
    )

