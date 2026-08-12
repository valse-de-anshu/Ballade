import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: 12

        ContentSection {
            icon: "imagesmode"
            shape: MaterialShape.Shape.Pill 
            title: Translation.tr("Extra Custom Images")
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: Config.options.background.widgets.customImages
                    delegate: GroupedList {
                        Layout.fillWidth: true
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            ConfigTextField {
                                Layout.fillWidth: true
                                title: Translation.tr("Image Path")
                                text: modelData.path ?? ""
                                onTextChanged: {
                                    var arr = Config.options.background.widgets.customImages
                                    arr[index].path = text
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                            RippleButton {
                                implicitWidth: 32; implicitHeight: 32
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colErrorContainer
                                colBackgroundHover: Appearance.colors.colError
                                colRipple: Appearance.colors.colOnError
                                MaterialSymbol { anchors.centerIn: parent; iconSize: 18; text: "delete"; color: Appearance.colors.colOnErrorContainer }
                                downAction: () => {
                                    var arr = Config.options.background.widgets.customImages
                                    arr.splice(index, 1)
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }
                    }
                }

                RippleButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 40; implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimary
                    colRipple: Appearance.colors.colOnPrimary
                    MaterialSymbol { anchors.centerIn: parent; iconSize: 24; text: "add"; color: Appearance.colors.colOnPrimaryContainer }
                    downAction: () => {
                        var arr = Config.options.background.widgets.customImages
                        arr.push({ enable: true, placementStrategy: "free", x: 400, y: 100, path: "", shape: "Cookie4Sided", size: 200 })
                        Config.options.background.widgets.customImages = arr
                    }
                }
            }
        }

        ContentSection {
            icon: "person"
            shape: MaterialShape.Shape.Pill 
            title: Translation.tr("User Card")
            GroupedList {
                ConfigTextField {
                    Layout.fillWidth: true
                    title: Translation.tr("Custom Text")
                    text: Config.options.background.widgets.userCard.customText
                    placeholderText: Translation.tr("Leave empty for weather (max 40 chars)")
                    maximumLength: 40
                    onTextChanged: {
                        Config.options.background.widgets.userCard.customText = text
                    }
                }
            }
        }
    }
}
