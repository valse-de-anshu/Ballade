pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "description": Translation.tr("All-rounder | Good quality, decent quantity"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://yande.re/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "konachan": {
            "name": "Konachan",
            "url": "https://konachan.net",
            "api": "https://konachan.net/post.json",
            "description": Translation.tr("For desktop wallpapers | Good quality"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/?json",
            "description": Translation.tr("Clean stuff | Excellent quality, no NSFW"),
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.join(" "),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5,
                        "preview_url": item.thumbnail,
                        "sample_url": item.thumbnail,
                        "file_url": item.thumbnail,
                        "file_ext": "avif",
                        "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                        "character": item.tag
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "url": "https://safebooru.donmai.us",
            "api": "https://safebooru.donmai.us/posts.json",
            "description": Translation.tr("The popular one | Best quantity, but quality can vary wildly"),
            "mapFunc": (response) => {
                if (!Array.isArray(response)) return [];
                return response.map(item => {
                    const w = item.image_width || 1200;
                    const h = item.image_height || 1200;
                    const fileUrl = item.large_file_url || item.file_url || item.preview_file_url;
                    return {
                        "id": item.id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": w / h,
                        "tags": item.tag_string || "",
                        "rating": item.rating || "s",
                        "is_nsfw": (item.rating != 's' && item.rating != 'g'),
                        "md5": item.md5 || "",
                        "preview_url": item.preview_file_url || fileUrl,
                        "sample_url": item.large_file_url || fileUrl,
                        "file_url": fileUrl,
                        "file_ext": item.file_ext || "jpg",
                        "source": getWorkingImageSource(item.source) ?? fileUrl,
                    }
                })
            },
            "tagSearchTemplate": "https://safebooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*",
            "tagMapFunc": (response) => {
                if (!Array.isArray(response)) return [];
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.post_count
                    }
                })
            }
        },
        "gelbooru": {
            "name": "Safebooru / Gelbooru",
            "url": "https://safebooru.org",
            "api": "https://safebooru.org/index.php?page=dapi&s=post&q=index&json=1",
            "description": Translation.tr("Great quantity, safe wallpapers, fast servers"),
            "mapFunc": (response) => {
                const list = Array.isArray(response) ? response : (response.post || []);
                return list.map(item => {
                    const w = item.width || 1200;
                    const h = item.height || 1200;
                    const imgUrl = item.file_url || (item.directory && item.image ? `https://safebooru.org/images/${item.directory}/${item.image}` : (item.sample_url || item.preview_url));
                    const prevUrl = item.preview_url || (item.directory && item.image ? `https://safebooru.org/thumbnails/${item.directory}/thumbnail_${item.image}` : imgUrl);
                    return {
                        "id": item.id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": w / h,
                        "tags": item.tags || "",
                        "rating": (item.rating || "s").charAt(0),
                        "is_nsfw": (item.rating !== 's' && item.rating !== 'general'),
                        "md5": item.hash || item.md5 || "",
                        "preview_url": prevUrl,
                        "sample_url": item.sample_url || imgUrl,
                        "file_url": imgUrl,
                        "file_ext": (item.image || "").split('.').pop() || "jpg",
                        "source": getWorkingImageSource(item.source) ?? imgUrl,
                    }
                })
            },
            "tagSearchTemplate": "https://safebooru.org/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%",
            "tagMapFunc": (response) => {
                const list = Array.isArray(response) ? response : (response.tag || []);
                return list.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "waifu.im": {
            "name": "waifu.im",
            "url": "https://waifu.im",
            "api": "https://api.waifu.im/images",
            "description": Translation.tr("Waifus only | Excellent quality, limited quantity"),
            "mapFunc": (response) => {
                const items = response.items || [];
                return items.map(item => {
                    const w = item.width || 1200;
                    const h = item.height || 1800;
                    const tagList = item.tags ? item.tags.map(tag => tag.name || "").join(" ") : "";
                    return {
                        "id": item.id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": w / h,
                        "tags": tagList,
                        "rating": item.isNsfw ? "e" : "s",
                        "is_nsfw": item.isNsfw || false,
                        "md5": item.id ? String(item.id) : "",
                        "preview_url": item.url,
                        "sample_url": item.url,
                        "file_url": item.url,
                        "file_ext": item.extension ? item.extension.replace(".", "") : "jpg",
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://api.waifu.im/tags",
            "tagMapFunc": (response) => {
                const items = response.versatile || response.items || [];
                return items.map(item => {return {"name": item.name || item}})
            }
        },
        "t.alcy.cc": {
            "name": "Alcy",
            "url": "https://t.alcy.cc",
            "api": "https://t.alcy.cc/",
            "description": Translation.tr("Large images | God tier quality, no NSFW."),
            "fixedTags": [
                {
                    "name": "ycy",
                    "count": "General"
                },
                {
                    "name": "moez",
                    "count": "Moe"
                },
                {
                    "name": "ysz",
                    "count": "Genshin Impact"
                },
                {
                    "name": "fj",
                    "count": "Landscape"
                },
                {
                    "name": "bd",
                    "count": "Girl on white background"
                },
                {
                    "name": "xhl",
                    "count": "Shiggy"
                },
            ],
            "manualParseFunc": (responseText) => {
                let urls = [];
                try {
                    const parsed = JSON.parse(responseText);
                    if (Array.isArray(parsed)) urls = parsed;
                } catch (e) {
                    urls = responseText.trim().split(/\r?\n/).filter(l => l.trim().length > 0);
                }
                return urls.map(line => {
                    const cleanUrl = line.trim();
                    return {
                        "id": Qt.md5(cleanUrl),
                        "width": 1200,
                        "height": 800,
                        "aspect_ratio": 1.5,
                        "tags": "alcy anime",
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": Qt.md5(cleanUrl),
                        "preview_url": cleanUrl,
                        "sample_url": cleanUrl,
                        "file_url": cleanUrl,
                        "file_ext": cleanUrl.split('.').pop() || "jpg",
                        "source": cleanUrl,
                    }
                });
            },
        },
        "wallhaven": {
            "name": "Wallhaven",
            "url": "https://wallhaven.cc",
            "api": "https://wallhaven.cc/api/v1/search",
            "description": Translation.tr("High-res anime wallpapers & art | 4K/8K"),
            "mapFunc": (response) => {
                const data = response.data || [];
                return data.map(item => {
                    const w = item.dimension_x || 1920;
                    const h = item.dimension_y || 1080;
                    const previewUrl = item.thumbs?.large || item.thumbs?.original || item.thumbs?.small || item.path;
                    return {
                        "id": item.id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": w / h,
                        "tags": item.category || "anime wallpaper",
                        "rating": item.purity === "sfw" ? "s" : "e",
                        "is_nsfw": item.purity !== "sfw",
                        "md5": item.id || "",
                        "preview_url": previewUrl,
                        "sample_url": item.path,
                        "file_url": item.path,
                        "file_ext": (item.file_type || "image/jpeg").split("/").pop() || "jpg",
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://wallhaven.cc/api/v1/search?q={{query}}*",
            "tagMapFunc": (response) => {
                const data = response.data || [];
                return data.map(item => ({ "name": item.id, "count": item.resolution }));
            }
        }
    }
    property var currentProvider: Persistent.states.booru.provider
    property var currentTags: []
    property int currentPage: 1
    property bool hasMore: true

    function getWorkingImageSource(url) {
        if (url?.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }
    
    function setProvider(provider) {
        provider = provider.toLowerCase()
        if (providerList.indexOf(provider) !== -1) {
            Persistent.states.booru.provider = provider
            root.clearResponses();
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name
                + (provider == "zerochan" ? Translation.tr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `sidebar.booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else {
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = [];
        currentPage = 1;
        hasMore = true;
    }

    function loadNextPage(limit=20) {
        if (root.runningRequests > 0 || !root.hasMore) return;
        root.makeRequest(root.currentTags, Persistent.states.booru.allowNsfw, limit, root.currentPage + 1);
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var url = baseUrl
        var tagString = tags.join(" ")
        if (!nsfw && !(["zerochan", "waifu.im", "t.alcy.cc", "wallhaven"].includes(currentProvider))) {
            if (currentProvider == "gelbooru") 
                tagString += " rating:general";
            else 
                tagString += " rating:safe";
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            params.push("c=" + encodeURIComponent(tagString))
            params.push("l=" + limit)
            params.push("s=" + "fav")
            params.push("t=" + 1)
            params.push("p=" + page)
        }
        else if (currentProvider === "wallhaven") {
            const apiKey = Config.options.sidebar.booru?.wallhaven?.apiKey || KeyringStorage.keyringData?.apiKeys?.wallhaven || "";
            if (apiKey.length > 0) {
                params.push("apikey=" + encodeURIComponent(apiKey));
            }
            if (tagString.trim().length > 0) {
                params.push("q=" + encodeURIComponent(tagString));
            }
            params.push("categories=010"); // Anime category
            params.push("purity=" + (nsfw ? "111" : "100")); // SFW vs Sketchy/NSFW
            params.push("page=" + page);
        }
        else if (currentProvider === "waifu.im") {
            var validTags = tags.filter(t => t && t.trim().length > 0);
            validTags.forEach(tag => {
                params.push("included_tags=" + encodeURIComponent(tag.toLowerCase()));
            });
            params.push("limit=" + Math.min(limit, 30));
            params.push("is_nsfw=" + (nsfw ? "true" : "false"));
            params.push("order_by=RANDOM");
        }
        else if (currentProvider === "t.alcy.cc") {
            var cat = (tags.length > 0 && tags[0].trim().length > 0) ? tags[0].trim() : "ycy";
            url += cat;
            params.push("json");
            params.push("quantity=" + limit);
        }
        else {
            if (tagString.trim().length > 0) {
                params.push("tags=" + encodeURIComponent(tagString));
            }
            params.push("limit=" + limit);
            if (currentProvider === "gelbooru") {
                params.push("pid=" + page);
            }
            else {
                params.push("page=" + page);
            }
        }
        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        if (page === 1) {
            root.currentTags = tags;
            root.currentPage = 1;
            root.hasMore = true;
        }

        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    const provider = providers[currentProvider]
                    let response;
                    if (provider.manualParseFunc) {
                        response = provider.manualParseFunc(xhr.responseText)
                    } else {
                        response = JSON.parse(xhr.responseText)
                        response = provider.mapFunc(response)
                    }
                    newResponse.images = response
                    newResponse.message = response.length > 0 ? "" : root.failMessage
                    if (response.length > 0) {
                        root.currentPage = page;
                    } else {
                        root.hasMore = false;
                    }
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                    newResponse.message = root.failMessage
                    root.hasMore = false;
                } finally {
                    root.runningRequests--;
                    root.responses = [...root.responses, newResponse]
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
                newResponse.message = root.failMessage
                root.runningRequests--;
                root.responses = [...root.responses, newResponse]
                root.hasMore = false;
            }
            root.responseFinished()
        }

        try {
            // Required for danbooru and konachan
            if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            else if (currentProvider == "zerochan") {
                const userAgent = Config.options?.sidebar?.booru?.zerochan?.username ? `Desktop sidebar booru viewer - username: ${Config.options.sidebar.booru.zerochan.username}` : defaultUserAgent
                xhr.setRequestHeader("User-Agent", userAgent)
            }
            root.runningRequests++;
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort();
        }

        var provider = providers[currentProvider]
        if (provider.fixedTags) {
            root.tagSuggestion(query, provider.fixedTags)
            return provider.fixedTags;
        } else if (!provider.tagSearchTemplate) {
            return
        }
        var url = provider.tagSearchTemplate.replace("{{query}}", encodeURIComponent(query))

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    // console.log("[Booru] Raw response: " + xhr.responseText)
                    var response = JSON.parse(xhr.responseText)
                    response = provider.tagMapFunc(response)
                    // console.log("[Booru] Mapped response: " + JSON.stringify(response))
                    root.tagSuggestion(query, response)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            // Required for danbooru and konachan
            if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }
}

