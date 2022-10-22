# WARNING: modified for cross compile
# Maintainer: Estela ad Astra <i@estela.cn>

pkgbase=linux-starfive-visionfive
_pkgver=6.1-rc1
pkgver=${_pkgver//-/}
pkgrel=1
pkgdesc='Linux for StarFive RISC-V VisionFive Board'
url="https://github.com/starfive-tech/linux/"
arch=(riscv64)
license=(GPL2)
makedepends=(bc libelf pahole cpio perl tar xz)
options=('!strip')
source=("https://git.kernel.org/torvalds/t/linux-v${_pkgver}.tar.gz"
  "visionfive-6.1.x.patch" ##extracted from https://github.com/starfive-tech/linux/
  "config")

sha256sums=('38a298755a2aed77eb1c5667c0a8a6cf944304dfbea3ff7e0bdf913ae81c3af8'
  '42c0fd5db0e55cae8ed28dac0f272a0c850c7a67a06d74004f601eceeaf6959b'
  'b61e9eb06cb6491e78360fda05a966abb06b7dbc818c5975f9952382156e53b2')

export KBUILD_BUILD_HOST=archlinux
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

_srcname=linux-v${_pkgver}
_arch="ARCH=riscv"
_cc="CROSS_COMPILE=riscv64-linux-gnu-"
strip=riscv64-linux-gnu-strip

prepare() {
  cd $_srcname

  echo "Setting version..."
  scripts/setlocalversion --save-scmversion
  echo "-$pkgrel" >localversion.10-pkgrel
  echo "${pkgbase#linux}" >localversion.20-pkgname

  patch -Np1 <"../visionfive-6.1.x.patch"

  echo "Setting config..."
  cp ../config .config
  make ${_arch} ${_cc} olddefconfig
  diff -u ../config .config || :

  make ${_arch} kernelrelease >version
  echo "Prepared $pkgbase version $(<version)"
}

build() {
  cd $_srcname
  make ${_arch} ${_cc} all
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=(coreutils kmod)
  optdepends=('wireless-regdb: to set the correct wireless channels of your country'
    'linux-firmware: firmware images needed for some devices')
  install=install.sh

  cd $_srcname
  local kernver="$(<version)"
  local modulesdir="$pkgdir/usr/lib/modules/$kernver"

  echo "Installing boot image..."
  #install -Dm644 "arch/riscv/boot/Image.gz" "$modulesdir/vmlinuz"
  install -Dm644 "arch/riscv/boot/Image" "$modulesdir/Image"

  #install -Dm644 "arch/riscv/boot/Image.gz" "$pkgdir/boot/vmlinuz-mainline"
  install -Dm644 "arch/riscv/boot/Image" "$pkgdir/boot/${pkgbase}"
  install -Dm644 "arch/riscv/boot/dts/starfive/jh7100-starfive-visionfive-v1.dtb" "$pkgdir/boot/${pkgbase}.dtb"

  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing modules..."
  make ${_arch} ${_cc} INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 modules_install

  echo "Installing dtbs..."
  make ${_arch} ${_cc} INSTALL_DTBS_PATH="$pkgdir/usr/share/dtbs/$kernver" dtbs_install

  # remove build links
  rm "$modulesdir"/build
}

_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=(pahole)

  cd $_srcname
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  echo "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/riscv" -m644 arch/riscv/Makefile
  cp -t "$builddir" -a scripts

  # required when DEBUG_INFO_BTF_MODULES is enabled
  install -Dt "$builddir/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/*

  echo "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/riscv" -a arch/riscv/include
  install -Dt "$builddir/arch/riscv/kernel" -m644 arch/riscv/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  echo "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */riscv/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  echo "Removing documentation..."
  rm -r "$builddir/Documentation"

  echo "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  echo "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -bi "$file")" in
    application/x-sharedlib\;*) # Libraries (.so)
      $strip -v $STRIP_SHARED "$file" ;;
    application/x-archive\;*) # Libraries (.a)
      $strip -v $STRIP_STATIC "$file" ;;
    application/x-executable\;*) # Binaries
      $strip -v $STRIP_BINARIES "$file" ;;
    application/x-pie-executable\;*) # Relocatable binaries
      $strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  echo "Stripping vmlinux..."
  $strip -v $STRIP_STATIC "$builddir/vmlinux"

  echo "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

pkgname=("$pkgbase" "$pkgbase-headers")
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
  }"
done

# vim:set ts=8 sts=2 sw=2 et:
