"""
"""

# ARM Cortex-M0
STM32F0 = struct(
    familly_name = "STM32F0",
    arm_cpu_version = "armv6-m",
    cpu = "-mcpu=cortex-m0",
)

# ARM Cortex-M3
STM32F1 = struct(
    familly_name = "STM32F1",
    arm_cpu_version = "armv7-m",
    cpu = "-mcpu=cortex-m3"
)

# ARM Cortex-M3
STM32F2 = struct(
    familly_name = "NOT DONE!! STM32F2",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
    fpu_abi = "-mfloat-abi=hard",
)

# ARM Cortex-M4 with FPU
STM32F3 = struct(
    familly_name = "STM32F3",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
    fpu_abi = "-mfloat-abi=hard",
)

# ARM Cortex-M4 with FPU
STM32F4 = struct(
    familly_name = "STM32F4",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
    fpu_abi = "-mfloat-abi=hard",
)

# ARM Cortex-M4 with FPU
STM32F7 = struct(
    familly_name = "STM32F7",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m7",
    fpu = "-mfpu=fpv4-sp-d16",
    fpu_abi = "-mfloat-abi=hard",
)

# ARM Cortex-M4 with FPU
STM32H5 = struct(
    familly_name = "STM32H5",
    arm_cpu_version = "armv8-m",
    cpu = "-mcpu=cortex-m33",
    fpu = "-mfpu=fpv4-sp-d16",
    fpu_abi = "-mfloat-abi=hard",
)

# ARM Cortex-M4 with FPU
# STM32H7 = stm32_toolchain(
#     familly_name = "STM32H7",
#     arm_cpu_version = "F7: armv7e-mf; F4: armv7e-mf",
#     cpu = "-mcpu=cortex-m4",
#     fpu = "-mfpu=fpv4-sp-d16",
#     fpu_abi = "-mfloat-abi=hard",
# )

def stm32_families_lut(stm32_families):
    """Generate an lookup table for STM32 mcu's famillies

    Args:
        stm32_families: The list of familly
    Returns:
        The stm32's famillies lookup table
    """
    lut = {}
    for familly in stm32_families:
        if len(familly.familly_name) != 7:
            # buildifier: disable=print
            print("STM32 Familly name not len of 7: {}".format(familly.familly_name))
        lut[familly.familly_name.upper()] = familly
    return lut

STM32_FAMILLIES_LUT = stm32_families_lut([
    STM32F0,
    STM32F1,
    STM32F2,
    STM32F3,
    STM32F4,
    STM32F7,
    STM32H5,
    # STM32H7,
])
