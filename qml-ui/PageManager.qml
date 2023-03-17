import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Stack {
    id: root

    property var currentPage: ""
    property var pageCache: ({})
    function cachePage(page) {
//        zynthian.currentTaskMessage = "Loading " + page + " page"

        var pageResolvedUrl = Qt.resolvedUrl("./pages/" + applicationWindow().pageScreenMapping[page])
        console.log("Caching page :", pageResolvedUrl)

        var component = Qt.createComponent(pageResolvedUrl);
        var obj = component.createObject(applicationWindow(), {"width": root.width, "height": root.height, visible: false})
        if (component.errorString() != "") {
            console.log("Error caching page", pageResolvedUrl, ":", component.errorString());
        } else {
            console.log("Page cached :", pageResolvedUrl)
        }

        return obj
    }
    function getPage(page) {
        var pageResolvedUrl = Qt.resolvedUrl("./pages/" + applicationWindow().pageScreenMapping[page])

        if (root.pageCache[page] != null) {
            console.log("Page cache found for page :", pageResolvedUrl)
            return root.pageCache[page]
        } else {
            return pageResolvedUrl
        }

    }

    Component.onCompleted: {
        root.pageCache["main"] = cachePage("main")
        root.pageCache["control"] = cachePage("control")
        root.pageCache["layers_for_channel"] = cachePage("layers_for_channel")
        root.pageCache["playgrid"] = cachePage("playgrid")
        root.pageCache["midi_key_range"] = cachePage("midi_key_range")
        root.pageCache["sound_categories"] = cachePage("sound_categories")
        root.pageCache["engine"] = cachePage("engine")
        root.pageCache["song_manager"] = cachePage("song_manager")
        root.pageCache["channel_wave_editor"] = cachePage("channel_wave_editor")
        root.pageCache["sketchpad"] = cachePage("sketchpad")

        root.initialItem = root.pageCache["sketchpad"]
        root.initialItem.visible = true
    }

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    Connections {
        target: zynthian
        onCurrent_screen_idChanged: handlePageChange(zynthian.current_screen_id)
        onCurrent_modal_screen_idChanged: handlePageChange(zynthian.current_screen_id)

        function handlePageChange(page) {
            if (page != "" && root.currentPage != page) {
                root.currentPage = page
                console.log("Changing page to", page)
                if (root.depth <= 0) {
                    root.push(root.getPage(page))
                } else {
                    root.currentItem.visible = false
                    root.replace(root.getPage(page))
                }
                root.currentItem.visible = true
            }
        }
    }
}
