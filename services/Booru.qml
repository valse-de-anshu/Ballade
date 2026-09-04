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
                const items = response.items || []
                return items.map(item => {
                    const thumb = item.thumbnail || item.small || item.large || "";
                    const full = item.full || item.large || item.medium || thumb;
                    const w = item.width || 1200;
                    const h = item.height || 1600;
                    return {
                        "id": item.id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": (w && h) ? (w / h) : 1.0,
                        "tags": Array.isArray(item.tags) ? item.tags.join(" ") : (item.tags || ""),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5 || String(item.id),
                        "preview_url": thumb,
                        "sample_url": item.medium || thumb,
                        "file_url": full,
                        "file_ext": thumb.toLowerCase().endsWith(".avif") ? "avif" : "jpg",
                        "source": getWorkingImageSource(item.source) ?? full,
                        "character": item.tag || ""
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
                        "dominant_color": item.dominantColor || "",
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
        },
        "pixiv": {
            "name": "Pixiv",
            "url": "https://www.pixiv.net",
            "api": "https://www.pixiv.net/ranking.php?format=json",
            "description": Translation.tr("Illustrations & daily rankings | Top tier Japanese art"),
            "mapFunc": (response) => {
                const items = response.body?.illustManga?.data || response.contents || [];
                return items.map(item => {
                    const rawUrl = item.url || "";
                    const proxiedThumb = rawUrl.replace("https://i.pximg.net/", "https://i.pixiv.re/");
                    const proxiedSample = rawUrl
                        .replace("/c/250x250_80_a2/img-master/", "/img-master/")
                        .replace("/c/480x960/img-master/", "/img-master/")
                        .replace("square1200.jpg", "master1200.jpg")
                        .replace("https://i.pximg.net/", "https://i.pixiv.re/");
                    const illustId = item.id || item.illust_id || "";
                    const w = item.width || 1200;
                    const h = item.height || 1200;
                    return {
                        "id": illustId,
                        "width": w,
                        "height": h,
                        "aspect_ratio": (w && h) ? (w / h) : 1.0,
                        "tags": Array.isArray(item.tags) ? item.tags.join(" ") : (item.tags || ""),
                        "rating": (item.xRestrict !== 0 || item.illust_content_type?.sexual || item.is_masked) ? "e" : "s",
                        "is_nsfw": Boolean(item.xRestrict !== 0 || item.illust_content_type?.sexual || item.is_masked),
                        "md5": String(illustId),
                        "preview_url": proxiedThumb,
                        "sample_url": proxiedSample,
                        "file_url": proxiedSample,
                        "file_ext": "jpg",
                        "source": `https://www.pixiv.net/en/artworks/${illustId}`,
                        "author": item.userName || item.user_name || "",
                        "title": item.title || "",
                    }
                })
            },
            "tagSearchTemplate": "https://www.pixiv.net/ajax/search/artworks/{{query}}?word={{query}}",
            "tagMapFunc": (response) => {
                const tags = response.body?.relatedTags || [];
                return tags.map(tag => ({ "name": tag, "count": "Pixiv" }));
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
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name)
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
        if (!nsfw && !(["zerochan", "waifu.im", "t.alcy.cc", "wallhaven", "pixiv"].includes(currentProvider))) {
            if (currentProvider == "gelbooru") 
                tagString += " rating:general";
            else 
                tagString += " rating:safe";
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            if (tagString.trim().length > 0) {
                return `https://www.zerochan.net/${encodeURIComponent(tagString.trim())}?json&s=fav&m=0&t=1&l=${limit}&p=${page}`;
            } else {
                return `https://www.zerochan.net/?json&s=fav&m=0&t=1&l=${limit}&p=${page}`;
            }
        }
        else if (currentProvider === "pixiv") {
            if (tagString.trim().length > 0) {
                return `https://www.pixiv.net/ajax/search/artworks/${encodeURIComponent(tagString.trim())}?word=${encodeURIComponent(tagString.trim())}&p=${page}${nsfw ? "&mode=r18" : ""}`;
            } else if (nsfw) {
                return `https://www.pixiv.net/ajax/search/artworks/R-18?word=R-18&p=${page}`;
            } else {
                return `https://www.pixiv.net/ranking.php?format=json&p=${page}&mode=daily`;
            }
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
            let explicitNsfw = false;
            let explicitSfw = false;
            validTags.forEach(tag => {
                const lower = tag.toLowerCase();
                if (lower === "nsfw" || lower === "lewd" || lower === "hentai" || lower === "ero") {
                    explicitNsfw = true;
                } else if (lower === "sfw" || lower === "safe") {
                    explicitSfw = true;
                } else {
                    params.push("includedTags=" + encodeURIComponent(lower));
                }
            });
            params.push("pageSize=" + Math.min(limit, 30));
            if (explicitNsfw) {
                params.push("isNsfw=True");
            } else if (explicitSfw || !nsfw) {
                params.push("isNsfw=False");
            } else {
                params.push("isNsfw=All");
            }
            params.push("orderBy=Favorites");
            params.push("page=" + page);
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

    function makeZerochanRequest(tags, limit, page, newResponse) {
        // User requested to mix results from:
        // 1. https://www.zerochan.net/?s=fav&m=0&t=1 (last week popular)
        // 2. https://www.zerochan.net/?s=fav&m=0&t=2 (last 3 months popular)
        // 3. https://www.zerochan.net/?s=fav&m=0&t=0 (all time popular)
        const tValues = [1, 2, 0];
        let results = [[], [], []];
        let completed = 0;
        let isDone = false;
        const tagStr = tags.join(" ").trim();
        const userAgent = Config.options?.sidebar?.booru?.zerochan?.username ? `Desktop sidebar booru viewer - username: ${Config.options.sidebar.booru.zerochan.username}` : defaultUserAgent;

        root.runningRequests++;

        function finishMix() {
            if (isDone) return;
            isDone = true;

            // Mix results in round-robin order and deduplicate by item id
            let mixed = [];
            let seenIds = {};
            let maxLen = Math.max(results[0].length, results[1].length, results[2].length);
            for (let i = 0; i < maxLen; i++) {
                for (let col = 0; col < 3; col++) {
                    if (i < results[col].length) {
                        let item = results[col][i];
                        if (item && item.id && !seenIds[item.id]) {
                            seenIds[item.id] = true;
                            mixed.push(item);
                        }
                    }
                }
            }

            newResponse.images = mixed;
            newResponse.message = mixed.length > 0 ? "" : root.failMessage;
            if (mixed.length > 0) {
                root.currentPage = page;
            } else {
                root.hasMore = false;
            }
            root.runningRequests--;
            root.responses = [...root.responses, newResponse];
            root.responseFinished();
        }

        tValues.forEach((tVal, idx) => {
            let url = "";
            if (tagStr.length > 0) {
                // Zerochan tag search puts tags directly in the path: /{tag}?json
                url = "https://www.zerochan.net/" + encodeURIComponent(tagStr) + "?json&s=fav&m=0&t=" + tVal + "&p=" + page + "&l=" + limit;
            } else {
                // Global feed without tags:
                // t=1 (last week) and t=2 (last 3 months) work with ?s=fav&m=0&t=...
                // t=0 (all-time) times out/500s on Zerochan without a filter, so d=huge is used to retrieve top all-time wallpapers reliably
                if (tVal === 0) {
                    url = "https://www.zerochan.net/?json&s=fav&d=huge&p=" + page + "&l=" + limit;
                } else {
                    url = "https://www.zerochan.net/?json&s=fav&m=0&t=" + tVal + "&p=" + page + "&l=" + limit;
                }
            }
            console.log("[Booru] Zerochan fetching section " + idx + " (t=" + tVal + "): " + url);

            let xhr = new XMLHttpRequest();
            xhr.open("GET", url);
            xhr.timeout = 7000;
            xhr.ontimeout = function() {
                console.log("[Booru] Zerochan section " + idx + " timed out");
                completed++;
                if (completed === tValues.length) finishMix();
            };
            try {
                xhr.setRequestHeader("User-Agent", userAgent);
            } catch (e) {}

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            let parsed = JSON.parse(xhr.responseText);
                            results[idx] = providers["zerochan"].mapFunc(parsed);
                        } catch (e) {
                            console.log("[Booru] Zerochan section " + idx + " parse error: " + e);
                        }
                    } else {
                        console.log("[Booru] Zerochan section " + idx + " failed with status: " + xhr.status);
                    }
                    completed++;
                    if (completed === tValues.length) {
                        finishMix();
                    }
                }
            };
            xhr.send();
        });
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        if (page === 1) {
            root.currentTags = tags;
            root.currentPage = 1;
            root.hasMore = true;
        }

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        if (currentProvider === "zerochan") {
            makeZerochanRequest(tags, limit, page, newResponse);
            return;
        }

        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

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
            // Required for konachan and pixiv
            if (["konachan", "pixiv"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
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
            // Required for konachan
            if (["konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }
}

