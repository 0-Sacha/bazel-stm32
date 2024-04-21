""

load("@bazel_arm//:rules.bzl", "arm_toolchain")
load("@bazel_stm32//:stm32_famillies.bzl", "STM32_FAMILLIES_LUT")

def _stm32_rules_impl(rctx):
    substitutions = {
        "%{rctx_name}": rctx.name,
        "%{toolchain_path_prefix}": "external/{}/".format(rctx.name),

        "%{arm_none_eabi_repo_name}": rctx.attr.arm_none_eabi_repo_name,

        "%{MCU_ID}": rctx.attr.stm32_mcu,
        "%{MCU_FAMILLY}": rctx.attr.stm32_familly,

        "%{mcu_startupfile}": rctx.attr.mcu_startupfile,

        "%{toolchain_mcu_constraint}": json.encode(rctx.attr.toolchain_mcu_constraint),
        "%{target_compatible_with}": json.encode(rctx.attr.target_compatible_with),
    }
    rctx.template(
        "BUILD",
        Label("//templates:BUILD.tpl"),
        substitutions
    )
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
        'mcu_startupfile': attr.string(mandatory = True),

        'toolchain_mcu_constraint': attr.string_list(default = []),
        'target_compatible_with': attr.string_list(default = []),
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
        arm_toolchain_package = None,
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
        arm_toolchain_package: The arm_toolchain to use
    """
    stm32_mcu = stm32_mcu.upper()
    stm32_familly = stm32_mcu[:7]

    defines = defines + [ "USE_HAL_DRIVER" ]
    includedirs = includedirs + [
        "-ICore/Inc",
        "-IDrivers/{stm32_familly}xx_HAL_Driver/Inc".format(stm32_familly = stm32_familly),
        "-IDrivers/{stm32_familly}xx_HAL_Driver/Inc/Legacy".format(stm32_familly = stm32_familly),
        "-IDrivers/CMSIS/Device/ST/{stm32_familly}xx/Include".format(stm32_familly = stm32_familly),
        "-IDrivers/CMSIS/Include"
    ]
    linkopts = linkopts + [
        "-lc",
        "-lm",
        "-lnosys",
        "-specs=nosys.specs",
    ]

    stm32_familly_info = STM32_FAMILLIES_LUT[stm32_familly]
    mcu = [ stm32_familly_info.cpu, "-mthumb" ]
    if hasattr(stm32_familly_info, "fpu") and stm32_familly_info.fpu != None:
        mcu += [ stm32_familly_info.fpu_abi, stm32_familly_info.fpu ]

    copts = mcu + [ "-D{}".format(mcu_device_group) ] + copts
    linkopts =  mcu + [ "-T{}".format(mcu_ldscript) ] + linkopts

    if gc_sections:
        copts += [ "-fdata-sections", "-ffunction-sections" ]
        linkopts.append("-Wl,--gc-sections")

    toolchain_mcu_constraint = [
        "@platforms//cpu:{}".format(stm32_familly_info.arm_cpu_version),
        "@bazel_stm32//:{}".format(stm32_familly.lower()),
    ]

    if use_mcu_constraint:
        target_compatible_with = target_compatible_with + toolchain_mcu_constraint

    if arm_toolchain_package == None:
        arm_toolchain_package = "arm-none-eabi-" + stm32_mcu
        arm_toolchain(
            name = "arm-none-eabi-" + stm32_mcu,
            arm_toolchain_type = "arm-none-eabi",
            arm_toolchain_version = arm_none_eabi_version,

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

    _stm32_rules(
        name = name,
        arm_none_eabi_repo_name = arm_toolchain_package,
        stm32_mcu = stm32_mcu,
        stm32_familly = stm32_familly,
        mcu_startupfile = mcu_startupfile,
        toolchain_mcu_constraint = toolchain_mcu_constraint,
        target_compatible_with = target_compatible_with,
    )
