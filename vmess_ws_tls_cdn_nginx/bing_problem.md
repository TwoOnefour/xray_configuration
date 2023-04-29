# 前言
博主是一个广西人，回到广西以后，发现自己的cdn解析到了德国，我的网页卡的不行，今天想来解决

一下这个问题
# 路由追踪
我先用了ipip.net的besttrace软件，使用本地dns的时候，正常解析到广州，然后就直接飞德国了

![image-1673379334514](https://bucket.pursuecode.cn/upload/2023/01/10.png)

哪有这样玩的dns啊

我觉得问题多半出在广州这个dns服务器上，他已经把cloudfront的香港域名解析给ban了，于是我从

网上找了一个绕一点的dns服务器，香港的

![image-1673379447511](https://bucket.pursuecode.cn/upload/2023/01/11.png)

虽然比之前好了，但是还是没有解决问题，我的目的是让cdn直接分发香港的边缘节点给我，那该怎么

办呢，我想了一下，如果是因为cloudfront被拒绝解析了，那么我换一个域名去解析这个cloudfront不

就好了，于是去试了一下。还是不行，痛苦，先埋个坑吧

目前已经手动将cloudfront的节点ip设置成hosts，在speedtest里让延迟有所改善了，就这样吧，太玄

学了

# bing重定向问题

昨天解决了类似的问题，这个问题是bing重定向过多

在国内使用魔法上网访问bing的时候，不管是美国的服务器还是香港的服务器都会出现bing重定向过

多，但是我自己亚马逊的服务器就不会出现这个问题

## 问题排查

### ipv6导致的重定向

我登陆服务器curl了一下bing

![香港服务器curl](https://bucket.pursuecode.cn/upload/2023/04/10.png)

![美国服务器curl](https://bucket.pursuecode.cn/upload/2023/04/11.png)

均会返回这个重定向

但是亚马逊服务器就不会有这个问题

![亚马逊服务器curl](https://bucket.pursuecode.cn/upload/2023/04/12.png)

通过比对发现aws没有ipv6地址，而其他两个服务器都有，我就在猜测会不会是这个问题导致的重定向

尝试

```
curl -4 https://www.bing.com
```

这下没有返回重定向了，而是直接有结果

![香港服务器curl4](https://bucket.pursuecode.cn/upload/2023/04/13.png)

于是我把魔法的监听地址从0.0.0.0改成127.0.0.1

重新试了试

仍然重定向

### nginx导致的重定向

我的魔法部署和亚马逊云的魔法部署还有一点不一样是nginx的配置不相同

前者的魔法使用了nginx反向代理+ws+协议

后者的魔法使用了fallback到nginx

而且我的nginx配置可能也有点问题

于是我比较了一下两者的nginx的配置

![香港服务器nginx配置](https://bucket.pursuecode.cn/upload/2023/04/14.png)

![亚马逊服务器nginx配置](https://bucket.pursuecode.cn/upload/2023/04/15.png)

可以看到X-Real-IP写的是$remote_addr

而$remote_addr表示的是addr是连接到代理服务器前，主机的真实ip地址

我觉得是X-Real-IP的问题

还有个X-Forwarded-For的问题

这X-Real-IP的header定义是这样的：

在http经过代理服务器时，由于可能需要获取客户端自身ip的逻辑应用，于是有了X-Real-IP

将客户端自身ip加入到请求头中

X-Forwarded-For的定义和X-Real-IP的定义很相似

但不同的是X-Forwarded-For有多个ip

每当经过一个代理节点以后，就会将代理节点的ip添加到X-Forwarded-For中

例如

客户端ip为1.1.1.1

代理服务器ip为2.2.2.2

客户端通过代理服务器访问 www.baidu.com 

www.baidu.com收到的header应该是这样的

```
header:
X-Real-IP: 1.1.1.1
X-Forwarded-For: 1.1.1.1, 2.2.2.2
```

但注意，X-Forwarded-For和X-Real-IP是可以篡改的

即回到刚才的话题

我的nginx配置可能是写上了自己的客户端ip，于是被bing识别到geoip属于cn，跳回 cn.bing.com 

但又因为当前代理服务器的ip已经作为代理，实际后端收到的请求ip还是代理服务器的ip

又触发了跳转到 www.bing.com

于是就反复横跳，出现了这个问题

当然以上都只是我的猜想，我把nginx配置改成了亚马逊的nginx的配置

现在变成了偶尔可以正常访问，但是还是会出现重定向的问题

我索性把X-Forwarded-For和X-Real-IP去掉

问题好多了，但是还是会重定向

### 魔法自带的dns问题

我把魔法的客户端和服务端配置都整改了一遍，其中服务端不使用nginx代理

配置如下
```
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "****",
            "settings": {
                "clients": [
                    {
                        "id": "", // fill in your UUID
                        "flow": "",
                        "level": 0,
                        "email": "love@example.com"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "h2",
                        "dest": "****", 
                        "xver": 2
                    },
                    {
                        "dest": "/dev/shm/h1.sock",
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1",
                        "h2"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/nginx/fullchain.cer", // Replace with your certificate, absolute path
                            "keyFile": "/etc/nginx/cerkey.key" // Replace it with your private key, absolute path
                        }
                    ]
                }
            },
            "tag": "****"
        },
        {
            "listen": "****", 
            "protocol": "trojan",
            "settings": {
              "clients": [
                {
                  "email":"general@trojan-tcp",
                  "password": "",
                  "level": 0
                }
              ],
              "fallbacks": [
                {
                  // if it was not a valid trojan reuqest, for example the trojan password was wrong, pass it to the NGINX HTTP2 cleartext UDS
                  "dest": "/dev/shm/h1.sock",
                  "xver": 2 //Enable PROXY protocol sending, and send the real source IP and port to Nginx. 1 or 2 indicates the PROXY protocol version. Consistent with the above, configuration 2 is recommended.
                }
              ]
            },
            "streamSettings": {
              "network": "tcp",
              "security": "none",
              "tcpSettings": {
                "acceptProxyProtocol": true //Enable PROXY protocol reception, receive the real source IP and port
              }
            },
            "sniffing": {
              "enabled": true,
              "destOverride": [
                "http",
                "tls"
              ]
            },
            "tag": "***"
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct",
            "settings": {
              "domainStrategy": "UseIP"
            }
            
        },
        {
          "protocol": "Blackhole",
          "tag": "blocked",
          "settings": {
            "domainStrategy": "UseIP"
          }
        }
    ],
    "routing": {
        "domainStrategy": "IPOnDemand",
        "rules": [{
          "type": "field",
          "domain": [
            "geoip:geolocation-!cn"
          ],
          "network": "tcp",
          "inboundTag": [
            "***"
          ],
          "outboundTag": "direct"
          // "balancerTag": "balancer"
        },
        {
          "type": "field",
          "domain": [
            "geosite:category-ads-all",
            "geosite:cn"
          ],
          "network": "tcp",
          "inboundTag": [
            "***"
          ],
          "outboundTag": "blocked"
          // "balancerTag": "balancer"
        }]
    },
    "dns": {
      "hosts": {
        "bing.com": "204.79.197.200",
        "dns.google": "8.8.8.8"
      },
      "servers": [
        {
          "address": "https://dns.google/dns-query",
          "domains": [
            "domain:bing.com",
            "domain:geosite:geolocation-!cn"
          ],
          "exceptIPs": [
            "geoip:cn"
          ]
        },
        {
          "address": "114.114.114.114",
          "domains": [
            "domain:geosite:cn" 
          ]
        },
        "8.8.8.8",
        "8.8.4.4",
        "localhost"
      ]
    }
}
```

***客户端使用了客户端dns本地解析***（就是这一步坑的，之前没发现）

虽然已经配置好了但是问题依旧

我就在想会不会和dns解析的地域有关系呢

于是我把客户端dns给去掉，问题居然解决了

# 总结

一般都和魔法的**dns解析策略**有关系，只要好好配置就可以轻松解决，不会踩那么多坑

