# Description
这是一个cdn+vmess（vless）+nginx反向代理+ws+tls+ssl证书的方案，这是最稳定的方案

可以选择性套用cdn，如果被墙可以优先用这个方案，让他复活

# Deploy
主要是cdn的配置，如果你有钱就使用国内的cdn，没钱可以使用cloudflare和cloudfront，我用的是免费的cloudfront方案

首先把你的cdn缓存策略全部关闭

策略请求选择源请求

然后使用配置即可

# Subscribe
你可以将subscribe文件直接放到nginx网站根目录下，然后直接访问网站路径就可以直接获取订阅

比如放到根目录下

https://your.domain/clash.yaml

就是一个订阅链接