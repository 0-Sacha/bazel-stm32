[![bazel_stm32/stm32F4](https://github.com/0-Sacha/bazel_stm32/actions/workflows/stm32F4.yml/badge.svg)](https://github.com/0-Sacha/bazel_stm32/actions/workflows/stm32F4.yml)

# bazel_stm32

A Bazel module that configure an `arm-none-eabi` toolchain for stm32 targets.

## How to Use
MODULE.bazel
```python
bazel_dep(name = "rules_cc", version = "0.0.10")
bazel_dep(name = "platforms", version = "0.0.10")

git_override(module_name="bazel_utilities", remote="https://github.com/0-Sacha/bazel_utilities.git", commit="aa399bb2599e2cd64a35a2275ce0f73a539524a5")
git_override(module_name="bazel_arm", remote="https://github.com/0-Sacha/bazel_arm.git", commit="5f8d6ccf9915f6dc0b90655226fc518a75f7bef5")

# Replace with git_override from my repo `https://github.com/0-Sacha/bazel_stm32.git`
local_path_override(module_name = "bazel_stm32", path = "../../")

bazel_dep(name = "bazel_utilities", version = "0.0.1", dev_dependency = True)
bazel_dep(name = "bazel_arm", version = "0.0.1", dev_dependency = True)
bazel_dep(name = "bazel_stm32", version = "0.0.1", dev_dependency = True)

stm32_toolchain_extension = use_extension("@bazel_stm32//:rules.bzl", "stm32_toolchain_extension")
inject_repo(stm32_toolchain_extension, "platforms", "bazel_utilities", "bazel_arm", "bazel_stm32")
stm32_toolchain_extension.stm32_platform(
    name = "my_repo_name",

    # mcu full name
    mcu = "STM32F401CCU6",
    # The HAL's expected device group, you can find the one for your MCU on STM32CubeMx or on the generated Makefile 
    device_group = "STM32F401xC",
    
    copts = [],
    cxxopts = [ "-std=c++20" ],
    linkopts = [
        "-lstdc++",
        "-u _printf_float",
    ],

    # The specs to use, change how the libc will be linked, you can use any specs supported by `arm-none-eabi` [ "nosys", "nano" ]
    specs = [ "nosys" ],
)
use_repo(stm32_toolchain_extension, "my_repo_name")
use_repo(stm32_toolchain_extension, "arm-none-eabi-my_repo_name")
register_toolchains("@arm-none-eabi-my_repo_name//:toolchain")
```
This will declare you the `stm32_binary` rule that you will need to use in order to correctly link your's linker-script and startup-file:
BUILD.bazel
```python
load("@STM32F401//:rules.bzl", "stm32_binary")

stm32_binary(
    name = "HelloWorld",
    srcs = [ "main.cpp" ],
    copts = [],
    # Thoses are the libs to link from the generated folders `Core` and `Drivers`. You can copy the file in the Examples/STM32F401CCU folder
    # Be aware, thoses lib include specification of the mcu HAL config, see `Drivers/BUILD.bazel` -> defines = [ "STM32F401xC" ];
    # Again, you can find this value in the generated Makefile
    deps = [
        "//Core:Core",
        "//Drivers:Drivers",
    ],
    # Generated linker-script and startup-file
    ldscript = "STM32F401CCUx_FLASH.ld",
    startupfile = "startup_stm32f401xc.s",

    visibility = ["//visibility:public"],
)
```

To build this, you will need to use the associated platform `--platforms=@my_repo_name//:platform`, see the `.bazelrc` in the `Examples` folder.
