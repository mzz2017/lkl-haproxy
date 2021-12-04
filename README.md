# BBRPLUS lkl-haproxy

`lkl-linux`+`haproxy` hack 版本 bbrplus，在 `OpenVZ` 工作良好。

**注意**: 
1. 默认参数下需要至少 `256M` 空闲内存并开启 `TUN/TAP`。
2. 如有更多内存，可对 `/etc/redirect.sh` 中的参数 `net.ipv4.tcp_wmem` 及 `LKL_HIJACK_BOOT_CMDLINE=mem` 进行调优。例如分别修改为：
   ```
   net.ipv4.tcp_wmem=4096 32768 4194304
   LKL_HIJACK_BOOT_CMDLINE=mem=512M
   ```
   或
   ```
   net.ipv4.tcp_wmem=4096 131072 6048576
   LKL_HIJACK_BOOT_CMDLINE=mem=2048M
   ```

## 使用方法

支持 Alpine / Debian / Ubuntu / CentOS

```bash
wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh && bash lkl-haproxy.sh
```

## Linux Kernel Library

https://github.com/mzz2017/linux

## 感谢

[tcp-nanqinlang/lkl-haproxy](https://github.com/tcp-nanqinlang/lkl-haproxy)

[linhua55/lkl_study](https://github.com/linhua55/lkl_study)

[bbrplus by dog250](https://blog.csdn.net/dog250/article/details/80629551)
