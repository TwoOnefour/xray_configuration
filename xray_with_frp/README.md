# Description
**安全的xray+frps反代服务**

如果想要不暴露frps怎么办？如果怕frps直连服务端口，被墙怎么办？想一个端口直接复用所有服务怎么办？

直接用xray纯配置实现，给frps流量加一条代理就行啦

## 流量路径
### 反代流量
frp 客户端 -> xray 客户端 -> xray 服务端 -> frp 服务端

### 流量形式 (双向)
正常服务 <> frp数据包 <> reality 流量 <> caddy/nginx https服务器反代 <> 用户

**外部看到的就只有reality流量**