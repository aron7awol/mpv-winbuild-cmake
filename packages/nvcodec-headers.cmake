ExternalProject_Add(nvcodec-headers
    # Was https://git.videolan.org/git/ffmpeg/nv-codec-headers.git -- the only
    # package on that host, and it failed the clone 2h35m into a cold build
    # (136 of 178 deps had already cloned fine from GitHub). This is the
    # upstream project's own automatic mirror, no GIT_TAG is pinned, and the
    # default branch matches, so the swap is content-identical.
    GIT_REPOSITORY https://github.com/FFmpeg/nv-codec-headers.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR>
        PREFIX=${MINGW_INSTALL_PREFIX}
        install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(nvcodec-headers)
cleanup(nvcodec-headers install)
