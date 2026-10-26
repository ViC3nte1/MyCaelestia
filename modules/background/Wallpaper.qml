pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property CachingImage current
    property bool completed
    property string animDir: ""
    property string prevSource: ""
    property bool initDone: false

    onSourceChanged: {
        if (!initDone) return;
        handleSourceChange();
    }

    Component.onCompleted: {
        initDone = true;
        if (source)
            Qt.callLater(() => {
                handleSourceChange();
                completed = true;
            });
    }

    function handleSourceChange() {
        if (!source) {
            current = null;
            return;
        }

        animDir = "";
        if (prevSource && source !== prevSource) {
            var list = Wallpapers.list;
            var prevIdx = -1, currIdx = -1;
            for (var i = 0; i < list.length; i++) {
                if (list[i].path === prevSource) prevIdx = i;
                if (list[i].path === source) currIdx = i;
            }
            if (prevIdx >= 0 && currIdx >= 0 && list.length > 1) {
                if ((prevIdx + 1) % list.length === currIdx)
                    animDir = "left";
                else if ((prevIdx - 1 + list.length) % list.length === currIdx)
                    animDir = "right";
            }
        }
        prevSource = source;

        current = imgComp.createObject(this, { path: source });
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    Component {
        id: imgComp

        CachingImage {
            id: img

            anchors.fill: parent

            x: root.animDir === "left" ? parent.width : (root.animDir === "right" ? -parent.width : 0)
            opacity: 0

            onStatusChanged: {
                if (status === Image.Ready) {
                    animX.start();
                    animOpacity.start();
                }
            }

            Anim on x {
                id: animX

                type: Anim.DefaultEffects
                running: false
                to: 0
            }

            Anim on opacity {
                id: animOpacity

                type: Anim.DefaultEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== img && root.current?.status === Image.Ready
                interval: Math.max(animX.duration, animOpacity.duration)
                onTriggered: img.destroy()
            }
        }
    }
}
