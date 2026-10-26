#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0

function compile_ffmpeg-v4l2-request() {
	: "${artifact_version:?artifact_version is not set}"
	declare build_arch
	build_arch="$(dpkg --print-architecture)"
	[[ "${build_arch}" == amd64 || "${build_arch}" == arm64 ]] ||
		exit_with_error "FFmpeg V4L2 Request requires an amd64 or arm64 build host"
	declare cleanup_id="" tmp_dir=""
	prepare_temp_dir_in_workdir_and_schedule_cleanup "ffmpeg-v4l2-request" cleanup_id tmp_dir
	declare rootfs="${tmp_dir}/rootfs"
	declare architectures="${build_arch}"
	[[ "${build_arch}" == arm64 ]] || architectures+=",arm64"
	declare includes="build-essential,ca-certificates,pkg-config,patchelf,libdrm-dev:arm64,libudev-dev:arm64,libx264-dev:arm64,libssl-dev:arm64,zlib1g-dev:arm64,libbz2-dev:arm64,liblzma-dev:arm64"
	[[ "${build_arch}" == arm64 ]] || includes+=",gcc-aarch64-linux-gnu"
	run_host_command_logged_raw env TMPDIR=/tmp mmdebstrap --mode=root --variant=minbase \
		--architectures="${architectures}" --include="${includes}" \
		"${RELEASE}" "${rootfs}" "http://${DEBIAN_MIRROR:-deb.debian.org/debian}"
	fetch_from_repo "${GITHUB_SOURCE}/FFmpeg/FFmpeg" "ffmpeg-v4l2-request" "commit:${FFMPEG_V4L2_REQUEST_COMMIT}"
	declare source_dir="${SRC}/cache/sources/ffmpeg-v4l2-request"
	mkdir -p "${rootfs}/build/src"
	run_host_command_logged_raw git -C "${source_dir}" archive \
		--output="${tmp_dir}/source.tar" "${FFMPEG_V4L2_REQUEST_COMMIT}"
	run_host_command_logged_raw tar -xf "${tmp_dir}/source.tar" -C "${rootfs}/build/src"
	declare codec_patch
	for codec_patch in ffmpeg-v4l2-request.patch ffmpeg-mjpeg-v4l2m2m.patch ffmpeg-cavs2-v4l2-request.patch ffmpeg-cavs-v4l2-request.patch ffmpeg-cavs-legacy-v4l2-request.patch ffmpeg-jpeg-v4l2-decode.patch ffmpeg-mpeg4-v4l2-request.patch ffmpeg-cavs2-fields-v4l2-request.patch ffmpeg-cedrus-mpeg1-sorenson.patch; do
		run_host_command_logged_raw env GIT_CEILING_DIRECTORIES="${rootfs}/build" \
			git -C "${rootfs}/build/src" apply "${SRC}/patch/misc/${codec_patch}"
	done
	cp "${SRC}/packages/ffmpeg-v4l2-request/build.sh" "${rootfs}/build/build.sh"
	declare source_date_epoch
	source_date_epoch="$(git -C "${source_dir}" show -s --format=%ct "${FFMPEG_V4L2_REQUEST_COMMIT}")"
	run_host_command_logged_raw env -u TMPDIR chroot "${rootfs}" /bin/bash /build/build.sh \
		"${FFMPEG_V4L2_REQUEST_COMMIT}" "${artifact_version}" "${CTHREADS}" "${source_date_epoch}"
	declare destination="${rootfs}/build/package"
	cat <<- CONTROL > "${destination}/DEBIAN/control"
		Package: ffmpeg-v4l2-request
		Version: ${artifact_version}
		Architecture: ${ARCH}
		Maintainer: ${MAINTAINER} <${MAINTAINERMAIL}>
		Depends: $(cat "${rootfs}/build/dependencies")
		Section: video
		Priority: optional
		Homepage: https://ffmpeg.org/
		Description: Shared FFmpeg with V4L2 Request codec support
	CONTROL
	dpkg_deb_build "${destination}" "ffmpeg-v4l2-request"
	done_with_temp_dir "${cleanup_id}"
}
