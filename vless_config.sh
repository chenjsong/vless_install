#! /bin/bash
# echo_class自用，by kakaruoter

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"


mkdir /root/vless
mv /root/ws* /root/vless &>/dev/null
mv /root/tcp* /root/vless &>/dev/null
mv /root/hap* /root/vless &>/dev/null
mv /root/trojan.json /root/vless/ &>/dev/null
mv /root/trojan.service /root/vless/ &>/dev/null

v2ray_install() {
	if [ ! -d /usr/bin/v2ray ];then
		timedatectl set-timezone Asia/Shanghai 
		wget https://install.direct/go.sh
		chmod +x go.sh
		./go.sh &>/dev/null
	fi
	rm -rf /etc/v2ray/config.json
	uuid1=`cat /proc/sys/kernel/random/uuid` &>/dev/null
}

uuid1=`cat /proc/sys/kernel/random/uuid` &>/dev/null

vless_download() {
	cd vless
	wget https://github.com/rprx/v2ray-vless/releases/download/clean2/v2ray-linux-64.zip
	unzip v2ray-linux-64.zip
	mv /usr/bin/v2ray/* /opt
	cp -r * /usr/bin/v2ray/
	chmod +x /usr/bin/v2ray/v2ray
	chmod +x /usr/bin/v2ray/v2ctl
	cd /root/
}

checkIP() {
 # read -p "请输入你所绑定到本vps的域名: " dname
  #local realIP="$(curl -s `curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/custom/ip_api`)"
  	local realIP="$(curl -s ifconfig.me)"
  	local resolvedIP="$(ping $dname -c 1 | head -n 1 | grep  -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"

  	if [[ "${realIP}" == "${resolvedIP}" ]]; then
    	return 0
  	else
    	return 1
  	fi
}

install_all() {
	while true; do
	read -p "请输入您绑定到本vps的域名:" dname
	echo -e "${Green_font_prefix}域名解析中...${Font_color_suffix}"
	checkIP
	if checkIP "${dname}"; then
		echo -e "${Green_font_prefix}解析正确, 即将开始安装${Font_color_suffix}"
		break
	else
		echo -e "${Red_font_prefix}解析错误，请重新输入!${Font_color_suffix}"
		continue
	fi
	done
}


trojan_install() {
	read -p "请输入trojan密码:" password1
	mkdir /etc/v2ray
	cd /etc/
	wget https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
	tar -xf trojan-1.16.0-linux-amd64.tar.xz
	rm -rf trojan-1.16.0-linux-amd64.tar.xz
	cp /etc/trojan/trojan /usr/bin/
	cp /etc/trojan/trojan /etc/init.d
	rm -rf /etc/trojan/config.json
	cd
	mv /root/vless/trojan.service /etc/systemd/system/trojan.service
	sed -i 's/passwd/'$password1'/g' /root/vless/trojan.json
	cp /root/vless/trojan.json /etc/trojan/
}

change_json() {
	sed -ri '10s/.*/            "id":"'$uuid1'",/' /root/vless/ws.json
	sed -ri '10s/.*/                        "id":"'$uuid1'"/' /root/vless/tcp.json
	sed -ri '10s/.*/              "id":"'$uuid1'",/' /root/vless/wsv.json
	sed -ri '10s/.*/                        "id":"'$uuid1'",/' /root/vless/tcpv.json 
	sed -i 's/example.com/'$dname'/g' /root/vless/tcp.conf
	sed -i 's/example.com/'$dname'/g' /root/vless/ws.conf
}

acme_install() {
	if [ ! -d /root/.acme.sh ];then
		apt-get install openssl cron socat curl -y	
		curl  https://get.acme.sh | sh
		~/.acme.sh/acme.sh --issue -d $dname --standalone --keylength ec-256 --force
		~/.acme.sh/acme.sh --installcert -d $dname --ecc \
                          	--fullchain-file /etc/v2ray/v2ray.crt \
                          	--key-file /etc/v2ray/v2ray.key
		mkdir /etc/ssl/private
		cat /etc/v2ray/v2ray.crt /etc/v2ray/v2ray.key > /etc/ssl/private/v2ray.pem
	fi
}
#vless_ws() {
#	cp ws.json /etc/v2ray/config.json
#}

haproxy_install() {
	if [ ! -d /etc/haproxy ];then
		apt install haproxy -y
	fi
	rm -rf /etc/haproxy/haproxy.cfg
	sed -i 's/example.com/v2ray/g' /root/vless/haproxy.cfg
	cp /root/vless/haproxy.cfg /etc/haproxy/haproxy.cfg
}

bbr_install() {
	wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
	chmod +x tcp.sh
	./tcp.sh
}

delete() {
	rm -rf /root/vless
	rm -rf /root/vless.zip
	rm -rf /root/html-p.zip
	rm -rf /root/432
}

html_install() {
	unzip html-p.zip
	rm -rf /var/www/html/*
	cp -r /root/432/* /var/www/html/
}

uprint() {
	echo ""
	echo -e "${Green_font_prefix}你的uuid为：$uuid1${Font_color_suffix}"
}

pathprint() {
	echo -e "${Green_font_prefix}ws路径：/ray${Font_color_suffix}"
}

nginx_install() {
		if [ ! -d /etc/nginx ];then
				apt install nginx -y
		fi
		rm -rf /etc/nginx/conf.d/*
}

delete_all() {
	read -p "将会删除证书文件以外的其它科学上网程序，请确定(y/n):" yn
	case "$yn" in
	[yY])
		rm -rf /etc/v2ray/config.json &>/dev/null
		rm -rf /etc/trojan &>/dev/null
		rm -rf /usr/bin/v2ray &>/dev/null
		rm -rf /usr/bin/trojan &>/dev/null
		rm -rf /etc/init.d/v2ray &>/dev/null
		rm -rf /etc/init.d/trojan &>/dev/null
		rm -rf /etc/systemd/system/trojan.service &>/dev/null
		rm -rf /etc/systemd/system/v2ray.service &>/dev/null
		;;
	[nN])
		exit
		;;
	*)
		echo -e "${red_font_prefix}error${Font_color_suffix}"
		exit
	esac
}

clear

echo && echo -e "          科学上网一键安装脚本：       
         ${Green_font_prefix}----  by echo_class ----${Font_color_suffix}
      ——————————————————————————————————
             ${Green_font_prefix}1、${Font_color_suffix}vless+ws+tls+web
             ${Green_font_prefix}2、${Font_color_suffix}vless+tcp+tls+web
             ${Green_font_prefix}3、${Font_color_suffix}vmess+ws+tls+web
             ${Green_font_prefix}4、${Font_color_suffix}vmess+tcp+tls+web
             ${Green_font_prefix}5、${Font_color_suffix}trojan
             ${Green_font_prefix}6、${Font_color_suffix}bbr install           
             ${Green_font_prefix}7、${Font_color_suffix}delete all
             ${Green_font_prefix}8、${Font_color_suffix}exit
      ——————————————————————————————————
         ${Green_font_prefix}该脚本会自动安装伪装网站${Font_color_suffix}"
#read -p "请输入您绑定的域名(务必输入正确！)": dname
#install_all
echo
read -p "请输入您的选择:" choice
case "$choice" in
1)
	install_all
	v2ray_install
	vless_download
	change_json
	acme_install
	nginx_install
	cp /root/vless/wsv.json /etc/v2ray/config.json
	cp /root/vless/ws.conf /etc/nginx/conf.d/ws.conf
	html_install
	systemctl restart v2ray
	systemctl restart nginx
	delete
	clear
	uprint
	pathprint
	;;
2)
	install_all
	v2ray_install
	vless_download
	change_json
	acme_install
	nginx_install
	haproxy_install
	cp /root/vless/tcpv.json /etc/v2ray/config.json
	cp /root/vless/tcp.conf /etc/nginx/conf.d/tcp.conf
	html_install
	systemctl restart v2ray
	systemctl restart nginx
	systemctl restart haproxy
	delete
	clear
	uprint
	;;
3)
	install_all
	v2ray_install
	change_json
	acme_install
	nginx_install
	cp /root/vless/ws.json /etc/v2ray/config.json
	cp /root/vless/ws.conf /etc/nginx/conf.d/ws.conf
	html_install
	systemctl restart v2ray
	systemctl restart nginx
	clear
	delete
	uprint
	pathprint
	;;
4)
	install_all
	v2ray_install
	change_json
	acme_install
	nginx_install
	haproxy_install
	cp /root/vless/tcp.json /etc/v2ray/config.json
	cp /root/vless/tcp.conf /etc/nginx/conf.d/tcp.conf
	html_install
	systemctl restart v2ray
	systemctl restart nginx
	systemctl restart haproxy
	delete
	clear
	uprint
	;;
5)
	install_all
	trojan_install
	change_json
	acme_install
	nginx_install
	cp /root/vless/tcp.conf /etc/nginx/conf.d/tcp.conf
	html_install
	systemctl restart nginx
	systemctl restart trojan
	delete
	clear
	echo -e "${Greed_font_prefix}trojan部署完成！${Font_color_suffix}"
	;;
6)
	bbr_install
	;;
7)
	delete_all
	;;
8)
	exit
	;;
*)
	echo -e "${Red_background_prefix}error${Font_color_suffix}"
	exit
esac
