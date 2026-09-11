pragma Singleton
import Quickshell

Singleton {
    id: root
    /**
     * @param { string } summary 
     * @returns { string }
     */
    function findSuitableMaterialSymbol(summary = "") {
        const defaultType = 'chat';
        if (summary.length === 0) return defaultType;

        const keywordsToTypes = {
            'reboot': 'restart_alt',
            'record': 'screen_record',
            'battery': 'power',
            'power': 'power',
            'screenshot': 'screenshot_monitor',
            'welcome': 'waving_hand',
            'time': 'schedule',
            'pomodoro': 'timer',
            'break': 'free_breakfast',
            'coffee': 'coffee',
            'installed': 'download',
            'configuration reloaded': 'reset_wrench',
            'unable': 'question_mark',
            "couldn't": 'question_mark',
            'config': 'reset_wrench',
            'update': 'update',
            'ai response': 'neurology',
            'control': 'settings',
            'upsca': 'compare',
            'music': 'queue_music',
            'install': 'deployed_code_update',
            'input': 'keyboard_alt',
            'preedit': 'keyboard_alt',
            'startswith:file': 'folder_copy', // Declarative startsWith check
        };

        const lowerSummary = summary.toLowerCase();

        for (const [keyword, type] of Object.entries(keywordsToTypes)) {
            if (keyword.startsWith('startswith:')) {
                const startsWithKeyword = keyword.replace('startswith:', '');
                if (lowerSummary.startsWith(startsWithKeyword)) {
                    return type;
                }
            } else if (lowerSummary.includes(keyword)) {
                return type;
            }
        }

        return defaultType;
    }

    /**
     * @param { number | string | Date } timestamp 
     * @returns { string }
     */
    function getFriendlyNotifTimeString(timestamp) {
        if (!timestamp) return '';
        const messageTime = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - messageTime.getTime();

        // Less than 1 minute
        if (diffMs < 60000)
            return 'Now';

        // Same day - show relative time
        if (messageTime.toDateString() === now.toDateString()) {
            const diffMinutes = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);

            if (diffHours > 0) {
                return `${diffHours}h`;
            } else {
                return `${diffMinutes}m`;
            }
        }

        // Yesterday
        if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
            return 'Yesterday';

        // Older dates
        return Qt.formatDateTime(messageTime, "MMMM dd");
    }

    function unescapeHtml(text) {
        if (!text) return "";
        return text
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&apos;/g, "'")
            .replace(/&nbsp;/g, " ")
            .replace(/&#x([0-9a-fA-F]+);/g, (_, code) => String.fromCharCode(parseInt(code, 16)))
            .replace(/&#([0-9]+);/g, (_, code) => String.fromCharCode(parseInt(code, 10)));
    }

    function cleanNotificationText(text) {
        if (!text) return "";
        let t = text;
        // 1. Convert line break tags to newline (handles both literal and escaped forms)
        t = t.replace(/(?:&lt;|<)\s*br\s*\/?\s*(?:&gt;|>)/gi, "\n");
        t = t.replace(/(?:&lt;|<)\s*\/?(?:p|div)\s*(?:&gt;|>)/gi, "\n");
        // 2. Unescape HTML entities
        t = unescapeHtml(t);
        // 3. Strip any remaining HTML tags
        t = t.replace(/<[^>]+>/g, "");
        // 4. Normalize excessive newlines
        t = t.replace(/\n{3,}/g, "\n\n");
        return t.trim();
    }

    function processNotificationBody(body, appName) {
        if (!body) return "";
        let processedBody = body;
        
        // Clean Chromium-based browsers notifications - remove first line
        if (appName) {
            const lowerApp = appName.toLowerCase();
            const chromiumBrowsers = [
                "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
            ];

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = processedBody.split('\n\n');
                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n');
                }
            }
        }

        // Clean all raw code / HTML entities / tags (especially from KDE Connect, WhatsApp, Discord)
        processedBody = cleanNotificationText(processedBody);
        
        return processedBody;
    }
}
