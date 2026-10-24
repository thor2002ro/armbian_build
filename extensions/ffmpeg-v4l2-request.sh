# @description Builds shared FFmpeg with V4L2 Request codec support for Debian trixie ARM64 images.
# SPDX-License-Identifier: GPL-2.0

function extension_prepare_config__ffmpeg_v4l2_request() {
	declare -g FFMPEG_V4L2_REQUEST_ENABLED=no
	[[ "${SKIP_FFMPEG_V4L2:-no}" == yes ]] && return 0
	if [[ "${ARCH}" != arm64 || "${RELEASE}" != trixie ]]; then
		display_alert "Skipping FFmpeg V4L2 Request" "Requires trixie arm64; got ${RELEASE} ${ARCH}" "warn"
		return 0
	fi
	declare -g FFMPEG_V4L2_REQUEST_ENABLED=yes
}

function add_host_dependencies__ffmpeg_v4l2_request() {
	if [[ "${FFMPEG_V4L2_REQUEST_ENABLED:-no}" == yes || "${WHAT:-}" == ffmpeg-v4l2-request ]]; then
		EXTRA_BUILD_DEPS+=("build-tools::mmdebstrap" "build-tools::debian-archive-keyring")
	fi
}

function post_family_tweaks__ffmpeg_v4l2_request() {
	[[ "${FFMPEG_V4L2_REQUEST_ENABLED:-no}" != yes ]] && return 0
	install_artifact_deb_chroot "ffmpeg-v4l2-request"
	chroot_sdcard /opt/ffmpeg-v4l2-request/bin/ffmpeg -version
	mkdir -p "${SDCARD}/usr/local/bin"
	declare name target
	for name in ffmpeg ffprobe; do
		target="${SDCARD}/usr/local/bin/${name}"
		if [[ -e "${target}" || -L "${target}" ]]; then
			if [[ "$(readlink "${target}" || true)" != "/opt/ffmpeg-v4l2-request/bin/${name}" &&
			"$(readlink "${target}" || true)" != "/opt/ffmpeg-v4l2/bin/${name}" ]]; then
				display_alert "Preserving existing ${name}" "${target}" "warn"
				continue
			fi
		fi
		ln -sfn "/opt/ffmpeg-v4l2-request/bin/${name}" "${target}"
	done
}
