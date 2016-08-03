#!/bin/sh

export PWD_DIR=$(pwd)
export SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)

export IMAGE_BUILDER_URL=https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64.tar.bz2
export PACKAGES_BASE="luci luci-theme-bootstrap luci-i18n-base-zh-cn"
export PACKAGES_TOOLS="openssh-sftp-server nano bind-dig htop iftop iperf curl whereis wget ca-certificates"
export PACKAGES_APPS="luci-i18n-ddns-zh-cn luci-i18n-wol-zh-cn luci-i18n-upnp-zh-cn luci-i18n-qos-zh-cn luci-i18n-commands-zh-cn luci-i18n-privoxy-zh-cn"
export PACKAGES_GFW="-dnsmasq dnsmasq-full ip ipset iptables-mod-nat-extra iptables-mod-tproxy libpolarssl"
export PACKAGES_SDK="python python-pip python-logging"
#export PACKAGES_SMB="luci-app-samba luci-app-hd-idle kmod-nls-utf8 kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras kmod-usb-uhci"
#export PACKAGES_VPN="strongswan"

function list_files() {
    local file_list=""
    if [ ! $# == 2 ]; then
        echo "Usage: $0 path ext_name"
        return 1;
    else
        local file_path=$1
        local file_ext=$2
        files=`ls $file_path`
        for filename in $files; do
            test -z $(echo $(basename $filename) | grep "$file_ext") || file_list="${file_list} ${filename}"
        done
        echo $file_list
        return 0;
    fi
}

function list_ipk_files() {
    local file_list=""
    if [ ! $# == 2 ]; then
        echo "Usage: $0 path ext_name"
        return 1;
    else
        local file_path=$1
        local file_ext=$2
        files=`ls $file_path`
        for filename in $files; do
            if [ -n $(echo $(basename $filename) | grep "$file_ext") ]; then
                file_list="${file_list} ${filename%%_*}"
            fi
        done
        echo $file_list
        return 0;
    fi
}

function update_gfwlist_conf() {
    local GFWLIST_DIR=$SCRIPTDIR/upload-files/usr/share/gfwlist
    local GFWLIST_SCRIPT=$GFWLIST_DIR/gfwlist_update.sh
    local DNSMASQ_DIR=$SCRIPTDIR/upload-files/etc/dnsmasq.d
    mkdir -p $DNSMASQ_DIR
    cd $DNSMASQ_DIR
    $GFWLIST_SCRIPT
}

function make_openwrt_image() {
    local IMAGE_BUILDER_FILE=$(basename $IMAGE_BUILDER_URL)
    local IMAGE_BUILDER_EXT=.tar.bz2
    local IMAGE_BUILDER_DIR=$(basename $IMAGE_BUILDER_FILE $IMAGE_BUILDER_EXT)
    local IMAGE_BUILDER_PACKAGES_DIR=$SCRIPTDIR/$IMAGE_BUILDER_DIR/packages
    local ADD_OTHER_DIR=$SCRIPTDIR/upload-files
    local ADD_IPK_DIR=$SCRIPTDIR/ipk-files
    local PACKAGES_IPK=""

    cd $SCRIPTDIR

    # Download ImageBuilder
    if [ ! -f $IMAGE_BUILDER_FILE ]; then
        wget $IMAGE_BUILDER_URL -O $IMAGE_BUILDER_FILE
    fi

    # Unzip ImageBuilder
    if [ ! -d $IMAGE_BUILDER_DIR ]; then
        tar -xjf $IMAGE_BUILDER_FILE
    fi

    cd $SCRIPTDIR/$IMAGE_BUILDER_DIR

    # Fix ar71xx-nand-4300
    if echo $IMAGE_BUILDER_FILE | grep "ar71xx-nand"; then
        local MAKEFILE_FILE=$SCRIPTDIR/$IMAGE_BUILDER_DIR/target/linux/ar71xx/image/Makefile
        local MAKEFILE_BAK=$MAKEFILE_FILE.bak
        echo $MAKEFILE_FILE
        if [ ! -f $MAKEFILE_BAK ]; then
            mv $MAKEFILE_FILE $MAKEFILE_BAK
            sed 's/23552k(ubi)/121856k(ubi)/g' $MAKEFILE_BAK > $MAKEFILE_FILE
            echo "*****************************"
            echo "Fix ar71xx-nand-4300 ROM 128M"
            echo "*****************************"
        fi
    fi

    # Fix ar71xx-nand-4300
    if echo $IMAGE_BUILDER_FILE | grep "ar71xx-generic"; then
        PACKAGES_SDK="python-light python-logging python-openssl python-codecs"
    fi

    # Add ipk files
    mkdir -p $ADD_IPK_DIR
    cp -rf $ADD_IPK_DIR/ $IMAGE_BUILDER_PACKAGES_DIR/
    PACKAGES_IPK=$(list_ipk_files $ADD_IPK_DIR .ipk)

    # Make image file
    make info
    PACKAGE_ALL="${PACKAGES_BASE} ${PACKAGES_TOOLS} ${PACKAGES_APPS} ${PACKAGES_GFW} ${PACKAGES_SDK} ${PACKAGES_SMB} ${PACKAGES_VPN} ${PACKAGES_IPK}"
    if [ -d $UPLOAD_DIR ]; then
        make image PROFILE=WNDR4300 PACKAGES="$PACKAGE_ALL" FILES=$ADD_OTHER_DIR
    else
        make image PROFILE=WNDR4300 PACKAGES="$PACKAGE_ALL"
    fi

    echo "*****************************"
    echo "<$PACKAGE_ALL>"

    # Make upload script
    cd bin/ar71xx
    cat > tftp-upload.sh <<EOF
#!/bin/sh
cat > tftp-upload.cmd <<CMD_EOF
connect 192.168.1.1
binary
put openwrt-15.05.1-ar71xx-nand-wndr4300-ubi-factory.img
quit
CMD_EOF

tftp < tftp-upload.cmd
EOF
    chmod a+x tftp-upload.sh
}

function main() {
    update_gfwlist_conf
    make_openwrt_image
}

main
