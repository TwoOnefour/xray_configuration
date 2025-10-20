# Description
分享一些我稳定用的xray配置

配置内有我的注解，可以跟着填写

目前我在使用的协议为[vless-vision-reality](https://github.com/TwoOnefour/xray_configuration/tree/main/vless-vision-reality)

不推荐使用xhttp，若喜欢玩cdn，可以自行研究

# 一键部署xray服务器(reality)
## 使用
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh)
## 卸载
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh) uninstall

此脚本会生成订阅配置，源代码可以访问这个url看或者直接看仓库内的setup.sh

## 内容
### vless-vision-reality
我目前正在稳定使用的代理配置

### xray_with_frp
我的frp通过路径，配合xray可以实现加密frp反代流量

