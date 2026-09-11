pragma Singleton

import Quickshell
import qs.modules.common
import qs.modules.common.functions

Singleton {
    // Formats
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]

    function isValidImageByName(name) {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    // Thumbnails
    // https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html
    readonly property var thumbnailSizes: ({
        "normal": 128,
        "large": 256,
        "x-large": 512,
        "xx-large": 1024
    })
    function thumbnailSizeNameForDimensions(width, height) {
        const sizeNames = Object.keys(thumbnailSizes);
        for(let i = 0; i < sizeNames.length; i++) {
            const sizeName = sizeNames[i];
            const maxSize = thumbnailSizes[sizeName];
            if (width <= maxSize && height <= maxSize) return sizeName;
        }
        return "xx-large";
    }

    function getFreedesktopThumbnail(filePath, size) {
        if (!size) size = "x-large";
        if (!filePath || filePath.length === 0) return "";
        const clean = FileUtils.trimFileProtocol(filePath);
        const encoded = clean.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encoded}`);
        const cacheDir = FileUtils.trimFileProtocol(Directories.genericCache);
        return `${cacheDir}/thumbnails/${size}/${md5Hash}.png`;
    }

    function getStaticWallpaperImage(filePath, fallbackThumb) {
        if (!filePath || filePath.length === 0) return "";
        const clean = FileUtils.trimFileProtocol(filePath);
        const isVid = /\.(mp4|webm|mkv|avi|mov)$/i.test(clean);
        if (!isVid) {
            return clean;
        }
        const fdThumb = getFreedesktopThumbnail(clean, "x-large");
        if (fallbackThumb && fallbackThumb.length > 0 && !/\.(mp4|webm|mkv|avi|mov)$/i.test(fallbackThumb)) {
            const cleanFallback = FileUtils.trimFileProtocol(fallbackThumb);
            if (!/\/[0-9]+\.mp4\.jpg$/i.test(cleanFallback)) {
                return cleanFallback;
            }
        }
        return fdThumb;
    }
}
