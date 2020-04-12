Some Precompiled Tools for OpenWrt
===

编译
---

 - 从 OpenWrt 的 [SDK][S] 编译

   ```bash
   # 以 ar71xx 平台为例
   tar xJf openwrt-sdk-18.06.1-ar71xx-tiny_gcc-7.3.0_musl.Linux-x86_64.tar.xz
   cd openwrt-sdk-*-ar71xx-*
   # 获取 precompiled-feeds Makefile
   git clone https://github.com/chenhw2/openwrt-precompiled-feeds.git package/precompiled
   # 选择要编译的包
   make menuconfig
   # 开始编译
   make package/precompiled/compile V=99
   ```


  [S]: https://openwrt.org/docs/guide-developer/using_the_sdk#obtain_the_sdk
