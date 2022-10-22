pre_upgrade() {
    pkgbase=linux-starfive-visionfive
    cd /boot
    cp -f ${pkgbase} ${pkgbase}.bak
    cp -f ${pkgbase}.dtb ${pkgbase}.dtb.bak
}
