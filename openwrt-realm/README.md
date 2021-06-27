# Shadowsocks-Rust for OpenWrt

[![Download][b]][2]
[![Release](https://img.shields.io/github/release/honwen/openwrt-shadowsocks-rust.svg)](https://github.com/honwen/openwrt-shadowsocks-rust/releases)

## 简介

本项目是 [shadowsocks-rust][1] 在 OpenWrt 上的移植

## 特性

软件包只包含 [shadowsocks-rust][1] 的可执行文件, 可与 [luci-app-shadowsocks][3] 搭配使用

- shadowsocks-rust

  ```
  usr/
    └── bin/
        ├── sslocal       // 提供 HTTP/SOCKS 代理, 透明代理, 端口转发(可用于 DNS 查询)
        └── ssurl         // SIP002: ShadowSocks URLs (可选)
        └── ssserver      // 提供 ShadowSocks 服务 (可选)
        └── ssmanager     // 管理 ShadowSocks 服务 (可选)
  ```

## 编译

- 从 OpenWrt 的 [SDK][s] 编译

  ```bash
  # 以 ar71xx 平台为例
  tar xjf OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
  cd OpenWrt-SDK-ar71xx-*
  # 获取 shadowsocks-rust Makefile
  git clone https://github.com/honwen/openwrt-shadowsocks-rust.git package/shadowsocks-rust
  # 选择要编译的包 Network -> shadowsocks-rust
  make menuconfig
  # 开始编译
  make package/shadowsocks-rust/compile V=99
  ```

## 配置

软件包本身并不包含配置文件, 配置文件内容为 JSON 格式, 支持的键:

| 键名          | 数据类型 | 说明                                                      |
| ------------- | -------- | --------------------------------------------------------- |
| server        | 字符串   | 服务器地址, 可以是 IP 或者域名                            |
| server_port   | 整数值   | 服务器端口号                                              |
| local_address | 字符串   | 本地绑定的 IP 地址, 默认 `127.0.0.1`                      |
| local_port    | 整数值   | 本地绑定的端口号                                          |
| password      | 字符串   | 服务端设置的密码                                          |
| method        | 字符串   | 加密方式, [详情参考][e]                                   |
| timeout       | 整数值   | 超时时间（秒）, 默认 60                                   |
| plugin        | 字符串   | 插件名称, eg: `v2ray-plugin`                              |
| plugin_opts   | 字符串   | 插件参数, eg: `tls;host=www.bing.com;path=/websocket`     |
| nofile        | 整数值   | 设置 Linux ulimit                                         |
| mode          | 枚举值   | 转发模式, 可用值: [`tcp_only`, `udp_only`, `tcp_and_udp`] |

[1]: https://github.com/shadowsocks/shadowsocks-rust
[2]: https://github.com/honwen/openwrt-shadowsocks/releases/latest
[b]: https://img.shields.io/crates/v/shadowsocks-rust.svg
[3]: https://github.com/shadowsocks/luci-app-shadowsocks
[a]: https://shadowsocks.org/en/spec/one-time-auth.html
[e]: https://github.com/honwen/luci-app-shadowsocks/wiki/Encrypt-method
[s]: https://wiki.openwrt.org/doc/howto/obtain.firmware.sdk
