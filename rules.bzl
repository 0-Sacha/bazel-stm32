""

load("@bazel_arm//:rules.bzl", "arm_toolchain")
load("@bazel_stm32//:stm32_famillies.bzl", "STM32_FAMILLIES_LUT")

def _stm32_rules_impl(rctx):
    substitutions = {
        "%{rctx_name}": rctx.name,
        "%{toolchain_path}": "external/{}/".format(rctx.name),

        "%{arm_none_eabi_repo_name}": rctx.attr.arm_none_eabi_repo_name,

        "%{MCU_ID}": rctx.attr.stm32_mcu,
        "%{MCU_FAMILLY}": rctx.attr.stm32_familly,

        "%{mcu_startupfile}": rctx.path(rctx.attr.mcu_startupfile).basename,

        "%{exec_compatible_with}": json.encode(rctx.attr.exec_compatible_with),
        "%{target_compatible_with}": json.encode(rctx.attr.target_compatible_with),

        "%{toolchain_mcu_constraint}": json.encode(rctx.attr.toolchain_mcu_constraint),
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
        'mcu_startupfile': attr.label(mandatory = True, allow_single_file = True),

        'exec_compatible_with': attr.string_list(default = []),
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

        libc = True,
        libm = True,
        libnosys = True,
        specs = "-specs=nano.specs",

        gc_sections = True,
        use_mcu_constraint = True,

        exec_compatible_with = [],
        target_compatible_with = [],

        arm_none_eabi_version = "latest",
        arm_toolchain_package = None,

        internal_arm_toolchain_extras_filegroup = "@bazel_utilities//:empty",
        internal_arm_toolchain_local_download = True,
        internal_arm_toolchain_auto_register = True
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

        libc: Does include libc '-lc'
        libm: Does include libm '-lm'
        libnosys: Does include libnosys '-lnosys'
        specs: specs for the compiler (nano, nosys, ...) by default: nano

        gc_sections: Enable the garbage collection of unused sections
        use_mcu_constraint: Add the mcu_constraint list (cpu / stm32 familly) to the target_compatible_with

        exec_compatible_with: The exec_compatible_with list for the toolchain
        target_compatible_with: The target_compatible_with list for the toolchain

        arm_none_eabi_version: The arm-none-eabi archive version
        arm_toolchain_package: The arm_toolchain to use
       
        internal_arm_toolchain_extras_filegroup: internal_arm_toolchain_extras_filegroup
        internal_arm_toolchain_local_download: If the internal arm-none-eabi toolchain is use external download
        internal_arm_toolchain_auto_register: If the internal arm-none-eabi toolchain is registered to bazel using `register_toolchains`
    """
    stm32_mcu = stm32_mcu.upper()
    stm32_familly = stm32_mcu[:7]

    stm32_familly_info = STM32_FAMILLIES_LUT[stm32_familly]
    mcu = [ stm32_familly_info.cpu, "-mthumb" ]
    if hasattr(stm32_familly_info, "fpu") and stm32_familly_info.fpu != None:
        mcu += [ stm32_familly_info.fpu_abi, stm32_familly_info.fpu ]

    copts = mcu + copts
    linkopts =  mcu + [ "-T{}".format(mcu_ldscript) ] + linkopts

    defines = defines + [ "USE_HAL_DRIVER", mcu_device_group ]
    includedirs = includedirs + [
        "Core/Inc",
        "Drivers/{stm32_familly}xx_HAL_Driver/Inc".format(stm32_familly = stm32_familly),
        "Drivers/{stm32_familly}xx_HAL_Driver/Inc/Legacy".format(stm32_familly = stm32_familly),
        "Drivers/CMSIS/Device/ST/{stm32_familly}xx/Include".format(stm32_familly = stm32_familly),
        "Drivers/CMSIS/Include"
    ]

    linkopts = linkopts + ([ specs ] if specs != "" else [])
    linkopts = linkopts + ([ "-lc" ] if libc else [])
    linkopts = linkopts + ([ "-lm" ] if libm else [])
    linkopts = linkopts + ([ "-lnosys" ] if libnosys else [])

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

            copts = copts,
            conlyopts = conlyopts,
            cxxopts = cxxopts,
            linkopts = linkopts,
            defines = defines,
            includedirs = includedirs,
            linkdirs = linkdirs,

            add_toolchain_linkdirs = False,

            exec_compatible_with = exec_compatible_with,
            target_compatible_with = target_compatible_with,

            toolchain_extras_filegroup = internal_arm_toolchain_extras_filegroup,

            local_download =  internal_arm_toolchain_local_download,
            auto_register_toolchain = internal_arm_toolchain_auto_register,
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
