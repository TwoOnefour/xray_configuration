## Description
分享一些我稳定用的xray配置

配置内有我的注解，可以跟着填写

目前我在使用的协议为[vless-vision-reality](https://github.com/TwoOnefour/xray_configuration/tree/main/vless-vision-reality)

不推荐使用xhttp，若喜欢玩cdn，可以自行研究

若配置有问题的话可以提issue，若有什么不明白的也可以提issue，我很乐意回答

## 一键部署xray服务器(reality)
### 使用
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh)
### 卸载
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh) uninstall

此脚本会生成订阅配置，源代码可以访问这个url看或者直接看仓库内的setup.sh

### 内容
建议配合[官方文档阅读](xray.github.io)

#### [vless-vision-reality](https://github.com/TwoOnefour/xray_configuration/tree/main/vless-vision-reality)
我目前正在稳定使用的代理配置，已支持抗量子配置(mldsa), 预链接配置（仅客户端需要配置）

#### [xray-any-https（进阶配置阅读推荐）](https://github.com/TwoOnefour/xray_configuration/tree/main/xray-any-https)
xray一个端口复用很多种逻辑的配置

#### [xray_with_frp](https://github.com/TwoOnefour/xray_configuration/tree/main/xray_with_frp)
我的frp通过路径，配合xray可以实现加密frp反代流量

#### [xray_reverse_proxy](https://github.com/TwoOnefour/xray_configuration/tree/main/xray_reverse_proxy)
xray的反向代理，和frp一样的功能, 其中还有 vless encrytion 的示例配置

## 碎碎念
可以不看

### 避免被和谐的方法

1. 不用高位端口，reality只用443
2. 最好使用邻居的sni, 最好是和vps主机商一个网站，尽量不用cdn
3. 不要直连ssh
4. 不要使用明文http面板
5. 如果你会的话，你可以在443开一个按sni分流的rule，`tunnel`入栈，回落到其他逻辑比如自己的nginx，作为伪装站
