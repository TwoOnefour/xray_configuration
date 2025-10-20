#!/bin/bash
# 此脚本使用xtls-vision-reality的方案，无需证书
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
    echo 脚本不是第一次运行，请运行 ./setup.sh uninstall或bash <(curl -Ls https://bucket.voidval.com/proxy/setup.sh) uninstall清理文件
    exit 0
fi

echo '自动安装必要环境'
if [ $os_version -eq 0 ]
then
    if [ ! -e /usr/bin/unzip ]
    then
        (yum update)>> /dev/null 2>&1
        (yum install unzip wget curl -y) >> /dev/null 2>&1
    fi
else
    (apt-get update) >> /dev/null 2>&1
    (apt-get -f install unzip wget curl -y) >> /dev/null 2>&1
fi
echo "已安装必要包unzip wget curl"

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

echo '默认config.json位于/usr/local/etc/xray下，若需要修改配置，请自行修改后重启xray'

ip=$(curl -4 -Ls http://ip.sb)

uuid=$(xray uuid)
keys=$(xray x25519)
mldsa=$(xray mldsa65)
private_key=$(echo "$keys" | sed -n 's/PrivateKey: \([^\\]*\).*/\1/p')
public_key=$(echo "$keys" | sed -n 's/Password: \([^\\]*\).*/\1/p')
mldsa_seed=$(echo "$mldsa" | sed -n 's/Seed: \([^\\]*\).*/\1/p')
mldsa_verify=$(echo "$mldsa" | sed -n 's/Verify: \([^\\]*\).*/\1/p')
sid=$(openssl rand -hex 8)
echo "生成config.json文件"
cat << EOF > config.json
{
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "target": "www.microsoft.com:443",
                    "serverNames": [
                        "www.microsoft.com"
                    ],
                    "privateKey": "${private_key}",
                    "mldsa65Seed": "${mldsa_seed}",
                    "shortIds": [
                        "${sid}"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF
echo "config.json生成完毕"

/usr/bin/ln -f  /etc/xray/config.json /usr/local/etc/xray/config.json
echo "xtls-vless-vision-reality配置完成"
echo '默认配置订阅连接：'
echo "vless://${uuid}@${ip}:443?encryption=none&security=reality&sni=www.microsoft.com&fp=safari&flow=xtls-rprx-vision&pbk=${public_key}&sid=${sid}&type=tcp&headerType=none#server"
echo "若你希望使用mldsa65, 请使用以下订阅链接："
echo "vless://${uuid}@${ip}:443?encryption=none&security=reality&sni=www.microsoft.com&fp=safari&flow=xtls-rprx-vision&pbk=${public_key}&sid=${sid}&type=tcp&headerType=none&pqv=${mldsa_verify}#server"
systemctl start xray
systemctl enable xray >> /dev/null 2>&1