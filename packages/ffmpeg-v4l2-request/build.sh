#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
set -euo pipefail

snapshot_commit="${1:?FFmpeg commit is required}"
package_version="${2:?Package version is required}"
threads="${3:--j2}"
export SOURCE_DATE_EPOCH="${4:?Source timestamp is required}"
export LC_ALL=C.UTF-8
export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
export PKG_CONFIG_PATH=

compiler=()
if [[ "$(dpkg --print-architecture)" != arm64 ]]; then
	compiler=(--enable-cross-compile --cross-prefix=aarch64-linux-gnu-)
fi

mkdir -p /build/objects /build/package/DEBIAN /build/debian
cd /build/objects
/build/src/configure \
	--prefix=/opt/ffmpeg-v4l2-request --arch=aarch64 --cpu=cortex-a53 --target-os=linux \
	"${compiler[@]}" --pkg-config=pkg-config \
	--enable-shared --disable-static --enable-pic --disable-autodetect \
	--enable-gpl --enable-version3 --enable-libdrm --enable-libudev \
	--enable-v4l2-request --enable-v4l2-m2m --enable-libx264 --enable-openssl \
	--enable-encoder=mjpeg_v4l2m2m \
	--enable-decoder=mjpeg_v4l2m2m --enable-hwaccel=mjpeg_v4l2request \
	--enable-zlib --enable-bzlib --enable-lzma --disable-doc --disable-debug --disable-ffplay \
	--extra-version=armbian-v4l2-request
grep -qx 'CONFIG_MJPEG_V4L2M2M_ENCODER=yes' ffbuild/config.mak
grep -qx 'CONFIG_MJPEG_V4L2M2M_DECODER=yes' ffbuild/config.mak
grep -qx 'CONFIG_MJPEG_V4L2REQUEST_HWACCEL=yes' ffbuild/config.mak
make "${threads}" REVISION="git-${snapshot_commit}"
make REVISION="git-${snapshot_commit}" DESTDIR=/build/package install

prefix=/build/package/opt/ffmpeg-v4l2-request
rm -rf "${prefix}/include" "${prefix}/lib/pkgconfig"
for binary in "${prefix}"/bin/*; do
	patchelf --set-rpath '$ORIGIN/../lib' "${binary}"
done
libraries=()
for library in "${prefix}"/lib/*.so.*; do
	[[ -L "${library}" ]] && continue
	patchelf --set-rpath '$ORIGIN' "${library}"
	libraries+=("-e${library}")
	name="${library##*/}"
	printf '%s %s ffmpeg-v4l2-request\n' "${name%%.so.*}" "${name#*.so.}" |
		awk '{split($2,v,"."); print $1, v[1], $3}' >> /build/debian/shlibs.local
done

cd /build
cat > debian/control <<- CONTROL
	Source: ffmpeg-v4l2-request

	Package: ffmpeg-v4l2-request
	Architecture: arm64
	Description: FFmpeg with V4L2 Request codec support
CONTROL
DEB_HOST_ARCH=arm64 dpkg-shlibdeps -O -xffmpeg-v4l2-request \
	"-l${prefix}/lib" "-e${prefix}/bin/ffmpeg" "-e${prefix}/bin/ffprobe" \
	"${libraries[@]}" | sed 's/^shlibs:Depends=//' > /build/dependencies
test -s /build/dependencies

mkdir -p package/usr/bin package/usr/share/doc/ffmpeg-v4l2-request
for binary in ffmpeg ffprobe; do
	ln -s "../../opt/ffmpeg-v4l2-request/bin/${binary}" "package/usr/bin/${binary}-v4l2-request"
done
cp src/COPYING.GPLv3 package/usr/share/doc/ffmpeg-v4l2-request/copyright
cp objects/ffbuild/config.mak package/usr/share/doc/ffmpeg-v4l2-request/build-config
printf 'FFmpeg: %s\nPackage: %s\n' \
	"${snapshot_commit}" "${package_version}" > package/usr/share/doc/ffmpeg-v4l2-request/sources
