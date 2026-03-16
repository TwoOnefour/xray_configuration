## Description
分享一些我稳定用的xray配置

配置内有我的注解，可以跟着填写

目前我在使用的协议为[vless-vision-reality](https://github.com/TwoOnefour/xray_configuration/tree/main/vless-vision-reality)

不推荐使用xhttp，若喜欢玩cdn，可以自行研究

## 一键部署xray服务器(reality)
### 使用
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh)
### 卸载
> bash <(curl -Ls https://raw.githubusercontent.com/TwoOnefour/xray_configuration/refs/heads/main/setup.sh) uninstall

此脚本会生成订阅配置，源代码可以访问这个url看或者直接看仓库内的setup.sh

### 内容
#### vless-vision-reality
我目前正在稳定使用的代理配置，已支持抗量子配置(mldsa), 预链接配置（仅客户端需要配置）

#### xray_with_frp
我的frp通过路径，配合xray可以实现加密frp反代流量

#### xray_reverse_proxy
xray的反向代理，和frp一样的功能

## 碎碎念
可以不看

### 避免被和谐的方法

1. 不用高位端口，reality只用443
2. 最好使用邻居的sni, 最好是和vps主机商一个网站，尽量不用cdn
3. 不要直连ssh
4. 不要使用明文http面板
5. 如果你会的话，你可以在443开一个按sni分流的rule，`tunnel`入栈，回落到其他逻辑比如自己的nginx，作为伪装站

**实例**
```server-config.json
{
    "inbounds": [
        {
            "tag": "dokodemo-in",
            "port": 443,
            "protocol": "dokodemo-door",
            "settings": {
                "followRedirect": false,
                "network": "tcp"
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "tls"
                ],
                "routeOnly": true
            }
        },
        {
            "listen": "127.0.0.1",
            "port": 4431,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "xxxxx",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "speed.cloudflare.com:443",
                    "serverNames": [
                        "speed.cloudflare.com"
                    ],
                    "privateKey": "xxxx",
                    "shortIds": [
                        "xxx"
                    ]
                }
            },
            "sniffing": {
                "routeOnly": true,
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ]
            },
            "tag": "vless-in"
        }
    ],
    "outbounds": [
        { "protocol": "freedom", "settings": { "domainStrategy": "UseIPv4v6" }, "tag": "direct" },
        { "protocol": "freedom", "settings": { "domainStrategy": "UseIPv4", "redirect": "127.0.0.1:4431" }, "tag": "to-vless" },
        { "protocol": "freedom", "settings": { "domainStrategy": "UseIPv4", "redirect": "127.0.0.1:4432" }, "tag": "to-alist" }, // alist反代
        { "protocol": "blackhole", "tag": "block" }
    ],
    "routing": {
        "rules": [
            { "inboundTag": ["dokodemo-in"], "domain": ["speed.cloudflare.com"], "outboundTag": "to-vless" },
            { "inboundTag": ["dokodemo-in"], "domain": ["alist.example.com"], "outboundTag": "to-alist" }, 
            { "inboundTag": ["dokodemo-in"], "outboundTag": "block" }
        ]
    }
}
```

```/etc/nginx/conf.d/alist.conf
server {
    listen 127.0.0.1:4432 ssl;
    ssl_certificate "/etc/nginx/example/fullchain.cer";
    ssl_certificate_key "/etc/nginx/example/cerkey.key";
    ssl_protocols TLSv1.3 TLSv1.2;
    server_name alist.example.com;

  location / {
    proxy_pass http://127.0.0.1:20010;
  }
}
```

### dokodemo-door入站的好处？
你可以开一个sniffing，根据sni分流你想要的节点/网站，一个端口可以复用
