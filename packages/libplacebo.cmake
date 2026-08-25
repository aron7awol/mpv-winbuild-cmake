get_property(src_glad TARGET glad PROPERTY _EP_SOURCE_DIR)
get_property(src_fast_float TARGET fast_float PROPERTY _EP_SOURCE_DIR)
file(GLOB libplacebo_patches CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/libplacebo-*.patch")
list(SORT libplacebo_patches)
set(libplacebo_patch_fingerprint "")
foreach(libplacebo_patch IN LISTS libplacebo_patches)
    file(SHA256 "${libplacebo_patch}" libplacebo_patch_sha256)
    string(APPEND libplacebo_patch_fingerprint "${libplacebo_patch_sha256}")
endforeach()
string(SHA256 libplacebo_patch_fingerprint "${libplacebo_patch_fingerprint}")

ExternalProject_Add(libplacebo
    DEPENDS
        vulkan
        shaderc
        spirv-cross
        lcms2
        glad
        fast_float
        xxhash
    GIT_REPOSITORY https://github.com/haasn/libplacebo.git
    GIT_TAG 22ee762e8e0890fc54068beb670310f0edce7263
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    PATCH_COMMAND bash -c "git am --abort 2>/dev/null || true"
    COMMAND ${EXEC} git reset --hard 22ee762e8e0890fc54068beb670310f0edce7263
    COMMAND ${EXEC} git am --3way ${libplacebo_patches}
    # Include the patch contents in the generated step command so restored
    # ExternalProject stamps cannot preserve a stale source checkout.
    COMMAND ${CMAKE_COMMAND} -E echo
        "libplacebo patch stack ${libplacebo_patch_fingerprint}"
    CONFIGURE_COMMAND ""
    COMMAND bash -c "rm -rf <SOURCE_DIR>/3rdparty/glad"
    COMMAND bash -c "rm -rf <SOURCE_DIR>/3rdparty/fast_float"
    COMMAND bash -c "ln -s ${src_glad} <SOURCE_DIR>/3rdparty/glad"
    COMMAND bash -c "ln -s ${src_fast_float} <SOURCE_DIR>/3rdparty/fast_float"
    COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --default-library=static
        -Dd3d11=enabled
        -Ddebug=true
        -Dblack-level-diagnostics=false
        -Db_ndebug=true
        -Doptimization=3
        -Dvulkan-registry='${MINGW_INSTALL_PREFIX}/share/vulkan/registry/vk.xml'
        -Ddemos=false
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

# ExternalProject does not track files consumed only by PATCH_COMMAND. Give
# the patch step a file-level predecessor so adding or editing a patch makes
# cached builds rerun patch -> configure -> build -> install for libplacebo.
ExternalProject_Add_Step(libplacebo patchset-dependency
    DEPENDEES update
    DEPENDERS patch
    DEPENDS ${libplacebo_patches}
    INDEPENDENT TRUE
    COMMAND ${CMAKE_COMMAND} -E echo
        "libplacebo patch set changed; invalidating cached package stamps"
)

force_rebuild_git(libplacebo)
force_meson_configure(libplacebo)
cleanup(libplacebo install)
