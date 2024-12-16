#!/bin/bash
# 此脚本使用xtls-vision-reality-fallback-nginx的方案，无需证书
# 可使用 bash setup.sh uninstall 卸载此脚本xray
case $1 in
    install)
        echo "安装xray"
        ;;
    uninstall)
        echo "卸载xray"
        [ ! -e /etc/xray ] && echo "没有xray安装，退出脚本" && exit 0
        echo "停止xray服务并移除服务文件"
        systemctl stop xray >> /dev/null 2>&1
        systemctl disable xray >> /dev/null 2>&1
        rm -rf /usr/lib/systemd/system/xray.service >> /dev/null 2>&1
        systemctl daemon-reload
        echo "清理xray连接文件"
        unlink /usr/local/bin/xray
        unlink /usr/local/bin/geosite.dat
        unlink /usr/local/bin/geoip.dat
        unlink /usr/local/etc/xray/config.json
        echo "删除xray日志文件夹"
        rm -rf /var/log/xray
        echo "删除xray文件夹"
        rm -rf /etc/xray
        echo "卸载完成"
        exit 0
        ;;
    *)
        ;;
esac

echo '注意，本脚本只适用于linux-64位安装'

OS=$(cat /etc/*-release | grep '^ID=')

# 判断Linux发行版
case $OS in
    *'debian'*)
        echo "This is a Debian system."
        os_version=1
        ;;
    *'centos'*)
        echo "This is a CentOS system."
        os_version=0
        ;;
    *'ubuntu'*)
        echo "This is an Ubuntu system."
        os_version=2
        ;;
    *)
        echo "This system is not Debian, CentOS, or Ubuntu."
        exit 0
        ;;
esac

if [ -e /etc/xray ]
then
    echo 脚本不是第一次运行，请运行 ./setup.sh uninstall或bash <(curl -Ls https://bucket-cf.voidval.com/proxy/setup.sh) uninstall清理文件
    exit 0
fi

echo '自动安装必要环境, 并更换国内源(若不需要国内源请在修改后自行把.bak文件还原'
if [ $os_version -eq 0 ]
then
    if [ ! -e /usr/bin/unzip ] || [ ! -e /etc/nginx ] || [ ! -e /etc/firewalld ]
    then
        sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo
        (yum update && yum upgrade -y )>> /dev/null 2>&1
        (yum install unzip wget nginx firewalld curl systemd -y) >> /dev/null 2>&1
    fi
else
    if [ $os_version -eq 1 ]
    then
        if [ ! -e /usr/bin/unzip ] || [ ! -e /etc/nginx ] || [ ! -e /etc/firewalld ]
        then
            mv /etc/apt/sources.list /etc/apt/sources.list.bak \
            && echo -e 'deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware' > /etc/apt/sources.list
        fi
    else
        mv /etc/apt/sources.list /etc/apt/sources.list.bak \
        && echo -e 'deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse\n
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse\n
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse\n
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse' > /etc/apt/sources.list
    fi
    (apt-get update && apt-get upgrade -y) >> /dev/null 2>&1
    (apt-get -f install unzip wget nginx firewalld curl systemd -y) >> /dev/null 2>&1
fi
echo "已安装必要包"

mkdir /etc/xray >> /dev/null 2>&1
cd /etc/xray
echo "下载xray文件"
wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip >> /dev/null 2>&1
unzip -qq -o Xray-linux-64.zip
rm -rf Xray-linux-64.zip
echo "xray下载完成"


echo "生成xray.service文件用于自启动"
cat << EOF > xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
echo "xray.service生成完毕"

open_bbr(){
    echo '正在开启bbr'

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf

    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    sysctl -p >> /dev/null

    result=$(lsmod|grep bbr)
    if [ ! -z "$result" ];
    then
        echo 'bbr开启完毕'
    else
        echo "bbr开启失败，可能是其他原因或不支持，请自行解决"
    fi
}

echo '检查bbr状态'

result=$(lsmod|grep bbr)
if [ -z "$result" ]; then
        echo bbr未开启，正在开启bbr
        open_bbr
fi

echo '开始部署xray'

mkdir /usr/local/etc/xray >> /dev/null 2>&1



/usr/bin/ln -f /etc/xray/xray /usr/local/bin/xray

/usr/bin/ln -f /etc/xray/xray.service /usr/lib/systemd/system/xray.service

/usr/bin/ln -f /etc/xray/geoip.dat /usr/local/bin/geoip.dat

/usr/bin/ln -f /etc/xray/geosite.dat /usr/local/bin/geosite.dat

chmod a+x /usr/local/bin/xray

chmod a+x /usr/local/bin/geosite.dat

chmod a+x /usr/local/bin/geoip.dat

systemctl daemon-reload


systemctl start firewalld
systemctl enable firewalld
echo '开启防火墙443端口'
firewall-cmd --add-port=443/tcp --permanent >> /dev/null 2>&1
firewall-cmd --reload >> /dev/null 2>&1

echo '默认config.json位于/usr/local/etc/xray下，请自行修改后重启xray'

ip=$(curl -Ls http://4.ipw.cn)

uuid=$(xray uuid)
keys=$(xray x25519)

private_key=$(echo "$keys" | sed -n 's/Private key: \([^\\]*\).*/\1/p')
public_key=$(echo "$keys" | sed -n 's/Public key: \([^\\]*\).*/\1/p')
sid=$(openssl rand -hex 8)
echo "生成config.json文件"
cat << EOF > config.json
{
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid", // 执行 xray uuid 生成，或 1-30 字节的字符串
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false, // 若为 true，输出调试信息
                    "dest": "www.copymanga.tv:443", // 目标网站最低标准：国外网站，支持 TLSv1.3、X25519 与 H2，域名非跳转用（主域名可能被用于跳转到 www）
                    "xver": 0,
                    "serverNames": [ // 客户端可用的 serverName 列表，暂不支持 * 通配符
                        "www.copymanga.tv" // Chrome - 输入 "dest" 的网址 - F12 - 安全 - F5 - 主要来源（安全），填 证书 SAN 的值
                    ],
                    "privateKey": "$private_key", // 执行 xray x25519 生成，填 "Private key" 的值
                    "shortIds": [ // 客户端可用的 shortId 列表，可用于区分不同的客户端
                        "$sid" // 0 到 f，长度为 2 的倍数，长度上限为 16，可留空，或执行 openssl rand -hex 8 生成
                    ]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ]
            }
        }
    ],
      "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "freedom",
            "tag": "blocked"
        }
      ],
      "routing": {
          "domainStrategy": "AsIs",
          "rules": [
          {
              "type": "field",
              "domain": [
                "geosite:category-ads-all"
              ],
              "outboundTag": "blocked"
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
              "geosite:geolocation-!cn"
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
EOF
echo "config.json生成完毕"
echo "生成nginx文件用于回落"
cat <<EOF >/etc/nginx/conf.d/fallback.conf
server{
    listen 81 http2 ssl proxy_protocol;
    listen [::]:81 http2 ssl proxy_protocol;
    ssl_certificate "/etc/nginx/fullchain.cer";
    ssl_certificate_key "/etc/nginx/cerkey.key";
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
            proxy_pass                         https://www.copymanga.tv;
            proxy_set_header Host              \$proxy_host;

            proxy_http_version                 1.1;
            proxy_cache_bypass                 \$http_upgrade;

            proxy_ssl_server_name on;

            proxy_set_header Upgrade           \$http_upgrade;
            proxy_set_header X-Real-IP         \$proxy_protocol_addr;

            proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Host  \$host;
            proxy_set_header X-Forwarded-Port  \$server_port;

            proxy_connect_timeout              60s;
            proxy_send_timeout                 60s;
            proxy_read_timeout                 60s;

            resolver 1.1.1.1;
    }
}
EOF
/usr/bin/ln -f  /etc/xray/config.json /usr/local/etc/xray/config.json
echo "重启nginx"
systemctl restart nginx >> /dev/null 2>&1
systemctl enable nginx >> /dev/null 2>&1
echo "xtls-vless-vision-reality-nginx配置完成"
echo '默认配置订阅连接：'
echo "vless://${uuid}@${ip}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.copymanga.tv&fp=safari&pbk=${public_key}&sid=${sid}&type=tcp&headerType=none#server"
echo "建议配置证书使用自己的证书方案，本方案是偷别人证书的方案，不是很推荐，但也能用"
systemctl start xray
systemctl enable xray >> /dev/null 2>&1
