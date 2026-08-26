pragma Singleton
pragma ComponentBehavior: Bound

// From https://git.outfoxxed.me/outfoxxed/nixnew
// It does not have a license, but the author is okay with redistribution.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
	id: root;
	signal trackChanged(reverse: bool);
	property bool __reverse: false;
	property var activeTrack;

	readonly property bool hasActivePlasmaIntegration: {
		let count = Mpris.players.count;
		let list = Mpris.players.values || [];
		return list.some(p => p && p.dbusName && p.dbusName.includes('plasma-browser-integration'));
	}

	property var players: {
		let count = Mpris.players.count;
		let plasma = hasActivePlasmaIntegration;
		let list = Mpris.players.values || [];
		return list.filter(player => {
			if (!player || !player.dbusName) return false;
			if (plasma && (player.dbusName.includes('firefox') || player.dbusName.includes('chromium'))) return false;
			if (player.dbusName.includes('playerctld')) return false;
			if (player.dbusName.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')) return false;
			return true;
		});
	}

	property MprisPlayer trackedPlayer: null;
	property MprisPlayer activePlayer: {
		if (trackedPlayer && isPlayerValid(trackedPlayer)) {
			// If trackedPlayer is a native browser bus but plasma is active, switch to plasma
			if (hasActivePlasmaIntegration && (trackedPlayer.dbusName.includes('firefox') || trackedPlayer.dbusName.includes('chromium'))) {
				let plasma = root.players.find(p => p.dbusName && p.dbusName.includes('plasma-browser-integration'));
				if (plasma) return plasma;
			}
			return trackedPlayer;
		}
		// Prefer plasma if active
		let plasma = root.players.find(p => p.dbusName && p.dbusName.includes('plasma-browser-integration'));
		if (plasma) return plasma;
		// Prefer playing player
		let playing = root.players.find(p => p.isPlaying);
		if (playing) return playing;
		return root.players[0] ?? null;
	}

	function isPlayerValid(player) {
		if (!player || !player.dbusName) return false;
		return root.players.some(p => p === player);
	}

	Instantiator {
		model: root.players;

		Connections {
			required property MprisPlayer modelData;
			target: modelData;

			Component.onCompleted: {
				if (modelData.dbusName && modelData.dbusName.includes('plasma-browser-integration')) {
					root.trackedPlayer = modelData;
				} else if (root.trackedPlayer == null) {
					root.trackedPlayer = modelData;
				}
			}

			function onPlaybackStateChanged() {
				if (modelData.dbusName && modelData.dbusName.includes('plasma-browser-integration')) {
					root.trackedPlayer = modelData;
				} else if (modelData.isPlaying) {
					// Only track if not a suppressed native browser bus
					if (!hasActivePlasmaIntegration || (!modelData.dbusName.includes('firefox') && !modelData.dbusName.includes('chromium'))) {
						root.trackedPlayer = modelData;
					}
				}
			}
		}
	}

	Connections {
		target: activePlayer

		function onPostTrackChanged() {
			root.updateTrack();
		}

		function onTrackArtUrlChanged() {
			root.updateTrack();
		}

		function onTrackTitleChanged() {
			root.updateTrack();
		}
	}

	onActivePlayerChanged: this.updateTrack();

	property string fallbackArtUrl: ""

	Process {
		id: ytFallbackProcess
		property string dbusName: root.activePlayer?.dbusName ?? ""
		command: ["bash", "-c", `busctl --user get-property ${dbusName} /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player Metadata | grep -o 'https://music.youtube.com/watch[^&" ]*' | sed -n 's/.*v=\\([^&" ]*\\).*/\\1/p' | head -n 1`]
		onExited: (exitCode, exitStatus) => {
			if (exitCode === 0 && ytFallbackProcess.stdout && ytFallbackProcess.stdout.trim().length > 0) {
				let url = "https://img.youtube.com/vi/" + ytFallbackProcess.stdout.trim() + "/hqdefault.jpg";
				root.fallbackArtUrl = url;
				Qt.callLater(() => root.triggerArtDownload(url))
			} else {
				root.fallbackArtUrl = "";
			}
		}
	}

	function updateTrack() {
		let art = this.activePlayer?.trackArtUrl ?? "";
		if (!art || art.length === 0) {
			ytFallbackProcess.running = true;
		} else {
			root.fallbackArtUrl = "";
		}

		this.activeTrack = {
			uniqueId: this.activePlayer?.uniqueId ?? 0,
			artUrl: art,
			title: this.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
			artist: this.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
			album: this.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
		};

		this.trackChanged(__reverse);
		this.__reverse = false;

		// Trigger art download for tracks that already have an art URL
		if (art && art.length > 0) {
			Qt.callLater(() => root.triggerArtDownload(art))
		}
	}

	function triggerArtDownload(url) {
		if (!url || url.length === 0) {
			readyArtFilePath = ""
			return
		}
		let fname = Qt.md5(url) + ".jpg"
		let fpath = artDownloadLocation + "/" + fname

		// If it's a permanent local file outside /tmp/ (e.g. from MPD), use it immediately!
		if (url.startsWith("file://") && !url.includes("/tmp/")) {
			readyArtFilePath = url;
			return;
		}

		centralArtDownloader.targetFile = url
		centralArtDownloader.destPath = fpath
		centralArtDownloader.running = false
		Qt.callLater(() => {
			centralArtDownloader.running = true
		})
	}

	property string effectiveArtUrl: (activeTrack && activeTrack.artUrl && activeTrack.artUrl.length > 0) ? activeTrack.artUrl : fallbackArtUrl

	property string artDownloadLocation: Directories.coverArt
	property string artFileName: effectiveArtUrl ? (Qt.md5(effectiveArtUrl) + ".jpg") : ""
	property string artFilePath: `${artDownloadLocation}/${artFileName}`
	property string readyArtFilePath: ""

	Process {
		id: centralArtDownloader
		property string targetFile: root.effectiveArtUrl
		property string destPath: root.artFilePath
		command: ["bash", "-c", `
			targetFile="${targetFile}"
			destPath="${destPath}"
			if [ -z "\${targetFile}" ]; then exit 1; fi
			if [ -f "\${destPath}" ] && [ -s "\${destPath}" ] && file "\${destPath}" | grep -qiE "image|bitmap"; then exit 0; fi

			if [[ "\${targetFile}" == file://* ]]; then
				src="${(targetFile || '').replace('file://', '')}"
				last_size=-1
				stable_count=0
				for i in {1..60}; do
					if [ -f "$src" ]; then
						curr_size=$(stat -c%s "$src" 2>/dev/null || echo 0)
						if [ "$curr_size" -gt 0 ] && [ "$curr_size" -eq "$last_size" ]; then
							stable_count=$((stable_count+1))
							if [ $stable_count -ge 2 ]; then break; fi
						else
							stable_count=0
						fi
						last_size=$curr_size
					fi
					sleep 0.05
				done
				
				if [ -f "$src" ] && [ "$last_size" -gt 0 ]; then 
					cp "$src" "\${destPath}"
					if file "\${destPath}" | grep -qiE "image|bitmap"; then exit 0; else rm -f "\${destPath}"; exit 1; fi
				else
					exit 1
				fi
			else
				curl -4 -sSL "\${targetFile}" -o "\${destPath}"
				if file "\${destPath}" | grep -qiE "image|bitmap"; then exit 0; else rm -f "\${destPath}"; exit 1; fi
			fi
		`]
		onExited: (exitCode) => {
			if (exitCode === 0) {
				root.readyArtFilePath = "file://" + destPath
			} else {
				if (destPath === root.artFilePath) {
					retryTimer.targetFile = centralArtDownloader.targetFile
					retryTimer.destPath = destPath
					retryTimer.restart()
				}
			}
		}
	}

	Timer {
		id: retryTimer
		property string targetFile: ""
		property string destPath: ""
		interval: 1500
		repeat: false
		onTriggered: {
			if (targetFile && targetFile.length > 0 && destPath === root.artFilePath) {
				centralArtDownloader.running = false
				centralArtDownloader.targetFile = targetFile
				centralArtDownloader.destPath = destPath
				centralArtDownloader.running = true
			}
		}
	}

	Component.onCompleted: {
		Qt.callLater(() => root.updateTrack())
	}

	property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying;
	property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? true;
	function togglePlaying() {
		if (this.activePlayer && this.activePlayer.canTogglePlaying) {
			this.activePlayer.togglePlaying();
		} else {
			Quickshell.execDetached(["playerctl", "play-pause"]);
		}
	}

	property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? true;
	function previous() {
		this.__reverse = true;
		if (this.activePlayer && this.activePlayer.canGoPrevious) {
			this.activePlayer.previous();
		} else {
			Quickshell.execDetached(["playerctl", "previous"]);
		}
	}

	property bool canGoNext: this.activePlayer?.canGoNext ?? true;
	function next() {
		this.__reverse = false;
		if (this.activePlayer && this.activePlayer.canGoNext) {
			this.activePlayer.next();
		} else {
			Quickshell.execDetached(["playerctl", "next"]);
		}
	}

	property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl;

	property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl;
	property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None;
	function setLoopState(loopState: var) {
		if (this.loopSupported) {
			this.activePlayer.loopState = loopState;
		}
	}

	property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl;
	property bool hasShuffle: this.activePlayer?.shuffle ?? false;
	function setShuffle(shuffle: bool) {
		if (this.shuffleSupported) {
			this.activePlayer.shuffle = shuffle;
		}
	}

	function setActivePlayer(player: MprisPlayer) {
		const targetPlayer = player ?? root.players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = root.players.indexOf(targetPlayer) < root.players.indexOf(this.activePlayer);
		} else {
			// always animate forward if going to null
			this.__reverse = false;
		}

		this.trackedPlayer = targetPlayer;
	}

	IpcHandler {
		target: "mpris"

		function pauseAll(): void {
			for (let i = 0; i < root.players.length; i++) {
				if (root.players[i].canPause) root.players[i].pause();
			}
		}

		function playPause(): void { root.togglePlaying(); }
		function previous(): void { root.previous(); }
		function next(): void { root.next(); }
	}
}
