#### 家庭 Pi-hole 的双树莓派高可用实现(草稿)
  1. 目的： 全屋 DNS，UPNP
  2. 实现：考虑到 UPNP (AirPlay) ，树莓派必须和家庭无线路由器在同一个网络内
    - 树莓派 USB 口供电后，默认获取动态IP地址，在路由器管理界面上修改树莓派为根据 MAC 地址绑定静态 IP，例如设定为: 192.168.8.8
    - PC 上浏览器进入：192.168.8.8/admin/ 配置树莓派上的 Pi-hole，配置完成后，PC 端用 nslookup www.baidu.com 192.168.8.8 命令验证确认能返回正确的地址
    - 验证无误后，去无线路由器的局域网配置，设置 DNS 服务器为 192.168.8.8, 114.114.114.114

  1. 硬件：安装 Ubuntu 20.04 LTS 版本的树莓派3+ 或者4，设为 A和B，IP 地址为 192.168.7.11/12，连接到光猫的 LAN 口
  2. 家庭光猫路由器地址： 192.168.7.1
  3. 家庭支持 Wi-Fi 6 的无线路由器网关，192.168.6.1，WAN 口配置为 192.168.7.5，配置 DNS 为 A & B
  4. A & B 都安装 Pi-hole 以及 Unbound，都可以独立从 root 解析 DNS (即不走运营商的 DNS)
  5. A & B 都安装 SS/kcptun 客户端科学上网，wpad.local 解析到本机，wpad.dat (PAC脚本)使用本地地址

  - 结论：任意一个树莓派 Down 掉时， DNS 以及 wpad 都能指向本机，依旧保持整体的网络连通性。
  - 单点风险：
    - 光猫以及后面的线路
    - 无线路由器
