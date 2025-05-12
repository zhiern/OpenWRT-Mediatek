#!/bin/bash

# 自定义URL
export mirror=https://script.kejizero.online

# 下载进度条
CURL_BAR="--progress-bar"

# 替换插件
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 翻译
echo -e "\nmsgid \"Control\"" >> feeds/luci/modules/luci-base/po/zh_Hans/base.po
echo -e "msgstr \"控制\"" >> feeds/luci/modules/luci-base/po/zh_Hans/base.po

echo -e "\nmsgid \"NAS\"" >> feeds/luci/modules/luci-base/po/zh_Hans/base.po
echo -e "msgstr \"网络存储\"" >> feeds/luci/modules/luci-base/po/zh_Hans/base.po

# 取消bootstrap为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile

# 更改主机名
sed -i "s/hostname='.*'/hostname='ZeroWrt'/g" package/base-files/files/bin/config_generate

# 修改默认ip
sed -i "s/192.168.6.1/$LAN/g" package/base-files/files/bin/config_generate

# 加入作者信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='ZeroWrt-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By OPPEN321'/g" package/base-files/files/etc/openwrt_release

# WiFi
sed -i "s/MT7986_AX6000_2.4G/ZeroWrt-2.4G/g" package/mtk/drivers/wifi-profile/files/mt7986/mt7986-ax6000.dbdc.b0.dat
sed -i "s/MT7986_AX6000_5G/ZeroWrt/g" package/mtk/drivers/wifi-profile/files/mt7986/mt7986-ax6000.dbdc.b1.dat

sed -i "s/MT7981_AX3000_2.4G/ZeroWrt-2.4G/g" package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b0.dat
sed -i "s/MT7981_AX3000_5G/ZeroWrt-5G/g" package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b1.dat

# New WiFi
sed -i "s/ImmortalWrt-2.4G/ZeroWrt-2.4G/g" package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i "s/ImmortalWrt-5G/ZeroWrt-5G/g" package/mtk/applications/mtwifi-cfg/files/mtwifi.sh

# TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# reboot
pushd feeds/luci
    curl -s $mirror/openwrt/patch/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch | patch -p1
popd

## golang 为 1.24.x
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/new/luci-theme-argon
curl -s $mirror/Customize/argon/bg1.jpg > package/new/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/new/luci-app-argon-config
sed -i "s/bing/none/g" package/new/luci-app-argon-config/root/etc/config/argon

# adguardhome
git clone --depth=1 -b lua https://github.com/sirpdboy/luci-app-adguardhome package/new/luci-app-adguardhome

# nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/new/OpenWrt-nikki

# Toolchain Cache
if [ "$BUILD_FAST" = "y" ]; then
    TOOLCHAIN_URL=https://github.com/oppen321/openwrt_caches/releases/download/OpenWrt_Toolchain_Cache
    curl -L -k ${TOOLCHAIN_URL}/toolchain_gcc13_mediatek.tar.zst -o toolchain.tar.zst $CURL_BAR
    tar -I "zstd" -xf toolchain.tar.zst
    rm -f toolchain.tar.zst
    mkdir bin
    find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
    find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1
fi

# install feeds
./scripts/feeds update -a
./scripts/feeds install -a
