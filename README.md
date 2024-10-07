# Description
分享一些我稳定用的xray配置

里面有使用说明

[关于cdn解析的问题和bing重定向的问题](https://github.com/TwoOnefour/xray_configuration/blob/main/vmess_ws_tls_cdn_nginx/bing_problem.md)

目前我在使用的协议为[xhttp_with_reality](https://github.com/TwoOnefour/xray_configuration/tree/main/xhttp_with_reality)

在443端口有两个协议同时监听(tcp和udp)

# 一键部署xray服务器
## 使用
>bash <(curl -Ls https://bucket-cf.voidval.com/proxy/setup.sh)
## 卸载
> bash <(curl -Ls https://bucket-cf.voidval.com/proxy/setup.sh) uninstall