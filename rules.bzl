""

load("@bazel_arm//:registry.bzl", "ARM_REGISTRY")
load("@bazel_arm//:rules.bzl", "arm_toolchain", "arm_compiler_archive")
load("@bazel_skylib//lib:sets.bzl", "sets")

load("//mcu:stm32_famillies.bzl", "STM32_FAMILLIES_LUT")

def _stm32_rules_impl(rctx):
    substitutions = {
        "%{rctx_name}": rctx.name,
        "%{toolchain_path}": "external/{}/".format(rctx.name),

        "%{arm_none_eabi_repo_name}": rctx.attr.arm_none_eabi_repo_name,

        "%{MCU_ID}": rctx.attr.mcu,
        "%{MCU_FAMILLY}": rctx.attr.stm32_familly,

        "%{exec_compatible_with}": json.encode(rctx.attr.exec_compatible_with),
        "%{target_compatible_with}": json.encode(rctx.attr.target_compatible_with),

        "%{toolchain_mcu_constraint}": json.encode(rctx.attr.toolchain_mcu_constraint),
    }
    rctx.template(
        "BUILD.bazel",
        Label("//templates:BUILD.bazel.tpl"),
        substitutions
    )
    rctx.template(
        "rules.bzl",
        Label("//templates:rules.bzl.tpl"),
        substitutions
    )

_stm32_rules = repository_rule(
    implementation = _stm32_rules_impl,
    attrs = {
        'arm_none_eabi_repo_name': attr.string(mandatory = True),

        'mcu': attr.string(mandatory = True),
        'stm32_familly': attr.string(mandatory = True),

        'exec_compatible_with': attr.string_list(default = []),
        'toolchain_mcu_constraint': attr.string_list(default = []),
        'target_compatible_with': attr.string_list(default = []),
    },
)

def stm32_toolchain(
        name,

        mcu,
        device_group,

        copts = [],
        conlyopts = [],
        cxxopts = [],
        linkopts = [],
        defines = [],
        includedirs = [],
        linkdirs = [],
        linklibs = [],
        # dbg / opt
        dbg_copts = [],
        dbg_linkopts = [],
        opt_copts = [],
        opt_linkopts = [],

        specs = [],

        gc_sections = True,

        arm_toolchain_extras_filegroups = [],

        exec_compatible_with = [],
        target_compatible_with = [],
        use_mcu_constraint = True,

        arm_none_eabi_version = "latest",
        arm_registry = None,
        arm_compiler_archive_package = None,
    ):
    """STM32 toolchain

    This macro create a repository containing all files needded to get an STM32 toolchain using an arm-none-eabi Toolchain

    Args:
        name: Name of the repo that will be created

        mcu: STM32 mcu name
        device_group: device_group

        copts: copts
        conlyopts: conlyopts
        cxxopts: cxxopts
        linkopts: linkopts
        defines: defines
        includedirs: includedirs
        linkdirs: linkdirs
        linklibs: linklibs
        # dbg / opt
        dbg_copts: dbg_copts
        dbg_linkopts: dbg_linkopts
        opt_copts: opt_copts
        opt_linkopts: opt_linkopts

        specs: specs for the compiler (nano, nosys, ...)

        gc_sections: Enable the garbage collection of unused sections

        arm_toolchain_extras_filegroups: arm_toolchain_extras_filegroups

        exec_compatible_with: The exec_compatible_with list for the toolchain
        target_compatible_with: The target_compatible_with list for the toolchain
        use_mcu_constraint: Add the mcu_constraint list (cpu / stm32 familly) to the target_compatible_with

        arm_none_eabi_version: The arm-none-eabi archive version
        arm_registry: The arm registry to use. Default to @bazel_arm//:ARM_REGISTRY
        arm_compiler_archive_package: The arm archive to use. If none are provided, one will be define automatically with this name: ":arm-none-eabi-" + mcu
    """
    mcu = mcu.upper()
    stm32_familly = mcu[:7]

    stm32_familly_info = STM32_FAMILLIES_LUT[stm32_familly]
    mcu_flags = [ stm32_familly_info.cpu, "-mthumb" ]
    if hasattr(stm32_familly_info, "fpu") and stm32_familly_info.fpu != None:
        mcu_flags += [ stm32_familly_info.fpu_abi, stm32_familly_info.fpu ]

    copts = mcu_flags + copts
    linkopts =  mcu_flags + linkopts

    defines = defines + [ "USE_HAL_DRIVER", device_group ]
    includedirs = includedirs + [
        "Core/Inc",
        "Drivers/{stm32_familly}xx_HAL_Driver/Inc".format(stm32_familly = stm32_familly),
        "Drivers/{stm32_familly}xx_HAL_Driver/Inc/Legacy".format(stm32_familly = stm32_familly),
        "Drivers/CMSIS/Device/ST/{stm32_familly}xx/Include".format(stm32_familly = stm32_familly),
        "Drivers/CMSIS/Include"
    ]

    linkopts = linkopts

    if gc_sections:
        copts += [ "-fdata-sections", "-ffunction-sections" ]
        linkopts.append("-Wl,--gc-sections")

    toolchain_mcu_constraint = [
        "@platforms//cpu:{}".format(stm32_familly_info.arm_cpu_version),
        # "@bazel_stm32//mcu:{}".format(stm32_familly.lower()),
    ]

    if use_mcu_constraint:
        target_compatible_with = target_compatible_with + toolchain_mcu_constraint

    arm_toolchain(
        name = "arm-none-eabi-" + name,
        toolchain_type = "arm-none-eabi",
        toolchain_version = arm_none_eabi_version,

        exec_compatible_with = exec_compatible_with,
        target_compatible_with = target_compatible_with,

        copts = copts,
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        linkopts = linkopts,
        defines = defines,
        includedirs = includedirs,
        linkdirs = linkdirs,
        linklibs = linklibs,
        # dbg / opt
        dbg_copts = dbg_copts,
        dbg_linkopts = dbg_linkopts,
        opt_copts = opt_copts,
        opt_linkopts = opt_linkopts,

        specs = specs,

        add_toolchain_linkdirs = False,

        toolchain_extras_filegroups = arm_toolchain_extras_filegroups,

        registry = arm_registry,

        compiler_archive_package = arm_compiler_archive_package,
    )

    _stm32_rules(
        name = name,
        arm_none_eabi_repo_name = "arm-none-eabi-" + name,
        mcu = mcu,
        stm32_familly = stm32_familly,
        toolchain_mcu_constraint = toolchain_mcu_constraint,
        target_compatible_with = target_compatible_with,
    )


def _stm32_toolchain_extension_impl(module_ctx):
    toolchain_versions_list = [
        platform.toolchain_version
        for mod in module_ctx.modules 
        for platform in mod.tags.stm32_platform
    ]
    if len(toolchain_versions_list) == 0:
        toolchain_versions_list.append("latest")
    toolchain_versions_list = sets.to_list(sets.make(toolchain_versions_list))
    arm_registry = ARM_REGISTRY
    for version in toolchain_versions_list:
        arm_compiler_archive(
            name = "archive_arm-none-eabi-" + version,
            toolchain_type = "arm-none-eabi",
            toolchain_version = version,
            registry_json = json.encode(arm_registry),
        )
    
    for mod in module_ctx.modules:
        for platform in mod.tags.stm32_platform:
            stm32_toolchain(
                name = platform.name,

                mcu = platform.mcu,
                device_group = platform.device_group,

                copts = platform.copts,
                conlyopts = platform.conlyopts,
                cxxopts = platform.cxxopts,
                linkopts = platform.linkopts,
                defines = platform.defines,
                includedirs = platform.includedirs,
                linkdirs = platform.linkdirs,
                linklibs = platform.linklibs,
                # dbg / opt
                dbg_copts = platform.dbg_copts,
                dbg_linkopts = platform.dbg_linkopts,
                opt_copts = platform.opt_copts,
                opt_linkopts = platform.opt_linkopts,

                specs = platform.specs,

                gc_sections = platform.gc_sections,

                arm_toolchain_extras_filegroups = platform.arm_toolchain_extras_filegroups,

                exec_compatible_with = platform.exec_compatible_with,
                target_compatible_with = platform.target_compatible_with,
                use_mcu_constraint = platform.use_mcu_constraint,

                arm_compiler_archive_package = "@archive_arm-none-eabi-" + platform.toolchain_version,
            )
    
stm32_toolchain_extension = module_extension(
    implementation = _stm32_toolchain_extension_impl,
    tag_classes = {
        "stm32_platform": tag_class(attrs = {
            'name': attr.string(mandatory = True),

            'toolchain_version': attr.string(default = "latest"),
            
            'mcu': attr.string(mandatory = True),
            'device_group': attr.string(mandatory = True),

            'exec_compatible_with': attr.string_list(default = []),
            'target_compatible_with': attr.string_list(default = []),
            'use_mcu_constraint': attr.bool(default = True),

            'copts': attr.string_list(default = []),
            'conlyopts': attr.string_list(default = []),
            'cxxopts': attr.string_list(default = []),
            'linkopts': attr.string_list(default = []),
            'defines': attr.string_list(default = []),
            'includedirs': attr.string_list(default = []),
            'linkdirs': attr.string_list(default = []),
            'linklibs': attr.string_list(default = []),
            # dbg / opt
            'dbg_copts': attr.string_list(default = []),
            'dbg_linkopts': attr.string_list(default = []),
            'opt_copts': attr.string_list(default = []),
            'opt_linkopts': attr.string_list(default = []),

            'specs': attr.string_list(default = []),

            'gc_sections': attr.bool(default = True),

            'arm_toolchain_extras_filegroups': attr.label_list(default = []),
        }),
    },
)
