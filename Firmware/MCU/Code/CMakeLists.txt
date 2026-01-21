#
# Copyright (c) 2018 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-BSD-5-Clause-Nordic
#
cmake_minimum_required(VERSION 3.20.0)

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
project(nvs)

# NORDIC SDK APP START

target_sources(app PRIVATE
  src/main.c 
  services/fpgarelated_service.c
  services/gattapp.c
  services/iCE40update_service.c
  services/deviceinfo_service.c
  users/spi.c
  users/timer.c
  users/iCE40.c
  users/flash.c
  ptx30w/plat/ptxPlat_I2C.c
  ptx30w/plat/ptxPlat_IRQ.c
  ptx30w/plat/ptxPlat_Timer.c
  ptx30w/ptx/ndef/ptxNDEFMessage.c
  ptx30w/ptx/ndef/ptxNDEFRecord.c
  ptx30w/ptx/ndef/ptxNDEFRecord_BT_SP.c
  ptx30w/ptx/ndef/ptxNDEFRecord_Text.c
  ptx30w/ptx/ndef/ptxNDEFRecord_URI.c
  ptx30w/ptx/ptx30w.c
  ptx30w/ptx/ptx30w_ConfigHelper.c
  ptx30w/ptx/ptx30w_Crc.c
  ptx30w/ptx/ptx30w_Hip.c
  ptx30w/ptx/ptx30w_Hip_Int.c
  ptx30w/ptx/ptx30w_Nsc.c
  ptx30w/ptx/ptx30w_Nvm_Int.c
  ptx30w/ptx/ptx30w_uCode_Int.c
  ptx30w/user_ptx30w_app.c
)

# NORDIC SDK APP END
zephyr_library_include_directories(.)