""

load("@bazel_arm_none_eabi//:rules.bzl", "arm_none_eabi_toolchain")
load("@bazel_stm32//:stm32_famillies.bzl", "STM32_FAMILLIES_LUT")

def _stm32_rules_impl(rctx):
    substitutions = {
        "%{rctx_name}": rctx.name,
        "%{toolchain_path_prefix}": "external/{}/".format(rctx.name),

        "%{arm_none_eabi_repo_name}": rctx.attr.arm_none_eabi_repo_name,

        "%{MCU_ID}": rctx.attr.stm32_mcu,
        "%{MCU_FAMILLY}": rctx.attr.stm32_familly,

        "%{target_compatible_with_packed}": json.encode(target_compatible_with).replace("\"", "\\\"")
    }
    rctx.template(
        "rules.bzl",
        Label("//templates:rules.bzl.tpl"),
        substitutions
    )

_stm32_rules = repository_rule(
    attrs = {
        'arm_none_eabi_repo_name': attr.string(mandatory = True),

        'stm32_mcu': attr.string(mandatory = True),
        'stm32_familly': attr.string(mandatory = True),

        'target_compatible_with': attr.string_list(default = [])
    },
    local = False,
    implementation = _stm32_rules_impl,
)

def stm32_toolchain(
        name,
        stm32_mcu,

        mcu_ldscript,
        mcu_device_group,
        mcu_startupfile,

        copts = [],
        conlyopts = [],
        cxxopts = [],
        linkopts = [],
        defines = [],
        includedirs = [],
        linkdirs = [],

        gc_sections = True,
        use_mcu_constraint = True,

        target_compatible_with = [],
        arm_none_eabi_version = "latest",
    ):
    """STM32 toolchain

    This macro create a repository containing all files needded to get an STM32 toolchain using an arm-none-eabi Toolchain

    Args:
        name: Name of the repo that will be created
        stm32_mcu: STM32 mcu name

        mcu_ldscript: mcu_ldscript
        mcu_device_group: mcu_device_group
        mcu_startupfile: mcu_startupfile

        copts: copts
        conlyopts: conlyopts
        cxxopts: cxxopts
        linkopts: linkopts
        defines: defines
        includedirs: includedirs
        linkdirs: linkdirs

        gc_sections: Enable the garbage collection of unused sections
        use_mcu_constraint: Add the mcu_constraint list (cpu / stm32 familly) to the target_compatible_with

        target_compatible_with: The target_compatible_with list for the toolchain

        arm_none_eabi_version: The arm-none-eabi archive version
    """
    stm32_mcu = stm32_mcu.upper()
    stm32_familly = stm32_mcu[:7]

    defines.append("USE_HAL_DRIVER")
    includedirs += [
        "-ICore/Inc",
        "-IDrivers/{stm32_familly}xx_HAL_Driver/Inc".format(stm32_familly = stm32_familly),
        "-IDrivers/{stm32_familly}xx_HAL_Driver/Inc/Legacy".format(stm32_familly = stm32_familly),
        "-IDrivers/CMSIS/Device/ST/{stm32_familly}xx/Include".format(stm32_familly = stm32_familly),
        "-IDrivers/CMSIS/Include"
    ]
    linkopts += [
        "-lc",
        "-lm",
        "-lnosys",
        "-specs=nosys.specs",
    ]

    stm32_familly_info = STM32_FAMILLIES_LUT[stm32_familly]
    mcu = [ stm32_familly_info.cpu, "-mthumb" ]
    if hasattr(stm32_familly_info, "fpu") and stm32_familly_info.fpu != None:
        mcu += [ stm32_familly_info.fpu, stm32_familly_info.fpu_abi ]

    copts += mcu + [ "-D{}".format(mcu_device_group) ]
    linkopts +=  mcu + [ "-T{}".format(mcu_ldscript) ]

    if gc_sections:
        copts += [ "-fdata-sections", "-ffunction-sections" ]
        linkopts.append("-Wl,--gc-sections")

    toolchain_mcu_constraint = [
        "@platforms//cpu:{}".format(stm32_familly_info.arm_cpu_version),
        "@bazel_stm32//stm32_famillies:{}".format(stm32_familly.lower()),
    ]

    native.platform(
        name = mcu_id.lower(),
        constraint_values = toolchain_mcu_constraint
    )

    # TODO: Check whether an constraint_value can be usefull
    # native.constraint_value(name = mcu_id.lower(), constraint_setting = "")

    if use_mcu_constraint:
        target_compatible_with = target_compatible_with + toolchain_mcu_constraint

    arm_none_eabi_toolchain(
        name = "arm-none-eabi-" + stm32_mcu,
        version = arm_none_eabi_version,

        target_name = stm32_familly,
        target_cpu = stm32_mcu[len(stm32_familly):],

        copts = copts,
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        linkopts = linkopts,
        defines = defines,
        includedirs = includedirs,
        linkdirs = linkdirs,

        target_compatible_with = target_compatible_with,
    )

    native.cc_library(
        name = "{}_startup".format(stm32_mcu),
        srcs = [ mcu_startupfile ],
        copts = [ "-x", "assembler-with-cpp" ],
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:public"],
    )

    _stm32_rules(
        name = name,
        arm_none_eabi_repo_name = "arm-none-eabi-" + stm32_mcu,
        stm32_mcu = stm32_mcu,
        stm32_familly = stm32_familly,
        target_compatible_with = target_compatible_with,
    )
