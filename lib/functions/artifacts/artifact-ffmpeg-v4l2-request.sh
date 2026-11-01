#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0

function artifact_ffmpeg-v4l2-request_config_dump() {
	artifact_input_variables[ARCH]="${ARCH}"
	artifact_input_variables[RELEASE]="${RELEASE}"
	artifact_input_variables[FFMPEG_V4L2_REQUEST_COMMIT]="${FFMPEG_V4L2_REQUEST_COMMIT}"
}

function artifact_ffmpeg-v4l2-request_prepare_version() {
	[[ "${ARCH}" == arm64 && "${RELEASE}" == trixie ]] ||
		exit_with_error "FFmpeg V4L2 Request requires RELEASE=trixie ARCH=arm64"
	declare -g FFMPEG_V4L2_REQUEST_COMMIT="${FFMPEG_V4L2_REQUEST_COMMIT:-a881f0a9addd3d104b87d4f6b58b111b1d0cfd28}"
	[[ "${FFMPEG_V4L2_REQUEST_COMMIT}" =~ ^[0-9a-f]{40}$ ]] ||
		exit_with_error "FFMPEG_V4L2_REQUEST_COMMIT requires a full Git commit hash"
	declare hash_files=""
	calculate_hash_for_bash_deb_artifact \
		"artifacts/artifact-ffmpeg-v4l2-request.sh" \
		"compilation/packages/ffmpeg-v4l2-request-deb.sh" \
		"${SRC}/packages/ffmpeg-v4l2-request/build.sh" \
		"${SRC}/patch/misc/ffmpeg-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-v4l2-request-nv12-capture.patch" \
		"${SRC}/patch/misc/ffmpeg-mjpeg-v4l2m2m.patch" \
		"${SRC}/patch/misc/ffmpeg-cavs2-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-cavs-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-cavs-legacy-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-jpeg-v4l2-decode.patch" \
		"${SRC}/patch/misc/ffmpeg-mpeg4-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-cavs2-fields-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-cedrus-mpeg1-sorenson.patch" \
		"${SRC}/patch/misc/ffmpeg-cedrus-encoder-rate-roi.patch" \
		"${SRC}/patch/misc/ffmpeg-h263-annex-v4l2-request.patch" \
		"${SRC}/patch/misc/ffmpeg-cedrus-adaptive-vbr.patch" \
		"${SRC}/patch/misc/ffmpeg-v4l2-m2m-dmabuf-input.patch" \
		"${SRC}/patch/misc/ffmpeg-v4l2-m2m-copy-encoded-packets.patch"
	artifact_version="1-S${FFMPEG_V4L2_REQUEST_COMMIT:0:12}-B${hash_files:0:12}"
	artifact_version_reason="FFmpeg ${FFMPEG_V4L2_REQUEST_COMMIT}; recipe and patches ${hash_files}"
	artifact_name="ffmpeg-v4l2-request-${RELEASE}-${ARCH}"
	artifact_type="deb"
	artifact_deb_repo="extra/${RELEASE}-utils"
	artifact_deb_arch="${ARCH}"
	artifact_map_packages=(["ffmpeg-v4l2-request"]="ffmpeg-v4l2-request")
	artifact_final_version_reversioned="${REVISION}-${RELEASE}"
}

function artifact_ffmpeg-v4l2-request_build_from_sources() {
	LOG_SECTION="compile_ffmpeg-v4l2-request" do_with_logging compile_ffmpeg-v4l2-request
}

function artifact_ffmpeg-v4l2-request_cli_adapter_pre_run() {
	declare -g ARMBIAN_COMMAND_REQUIRE_BASIC_DEPS="yes"
	cli_standard_relaunch_docker_or_sudo
}

function artifact_ffmpeg-v4l2-request_cli_adapter_config_prep() {
	enable_extension "ffmpeg-v4l2-request"
	use_board="yes" prep_conf_main_minimal_ni < /dev/null
}

function artifact_ffmpeg-v4l2-request_get_default_oci_target() {
	artifact_oci_target_base="${OCI_SERVER}/${OCI_PATH}/"
}

function artifact_ffmpeg-v4l2-request_is_available_in_local_cache() {
	is_artifact_available_in_local_cache
}

function artifact_ffmpeg-v4l2-request_is_available_in_remote_cache() {
	is_artifact_available_in_remote_cache
}

function artifact_ffmpeg-v4l2-request_obtain_from_remote_cache() {
	obtain_artifact_from_remote_cache
}

function artifact_ffmpeg-v4l2-request_deploy_to_remote_cache() {
	upload_artifact_to_oci
}
