/*
    SPDX-FileCopyrightText: 2019 Roman Gilg <subdiff@gmail.com>
    SPDX-FileCopyrightText: 2012 Dan Vratil <dvratil@redhat.com>
    SPDX-FileCopyrightText: 2024 Joshua Goins <joshua.gons@kdab.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Shapes

import org.kde.kirigami as Kirigami
import org.kde.plasma.tablet.kcm
import org.kde.kcmutils
import org.kde.kquickcontrols

Item {
    id: outputAreaView
    
    required property var device
    required property int mode

    readonly property bool stretchToFill: mode === 0
    readonly property bool fitAspectRatio: mode === 1
    readonly property bool mapToPortion: mode === 2

    function setOutputAreaMode(mode): void {
        if (mode === 0) {
            // If fit to screen, use the whole size of the display
            outputAreaItem.x = 0
            outputAreaItem.y = 0
            outputAreaItem.width = Qt.binding(() => outputItem.outputWidth);
            outputAreaItem.height = Qt.binding(() => outputItem.outputHeight);
        } else {
            let outputArea = Qt.rect(0, 0, 1, 1);
            if (mode === 1) {
                outputArea = Qt.rect(0, 0, 1, outputItem.aspectRatio / tabletItem.aspectRatio);
            }

            outputAreaItem.x = Qt.binding(() => outputArea.x * outputItem.outputWidth);
            outputAreaItem.y = Qt.binding(() => outputArea.y * outputItem.outputHeight);
            outputAreaItem.width = Qt.binding(() => tabletSizeHandle.x);
            outputAreaItem.height = Qt.binding(() => tabletSizeHandle.y);
            tabletSizeHandle.x = Qt.binding(() => outputArea.width * outputItem.outputWidth);
            tabletSizeHandle.y = Qt.binding(() => outputArea.height * outputItem.outputHeight);

            if (mode === 2) {
                keepAspectRatio.checked = outputAreaItem.aspectRatio === (form.device.size.width / form.device.size.height)
            }
        }
    }

    function setOutputArea(outputArea): void {
        outputAreaItem.x = Qt.binding(() => outputArea.x * outputItem.outputWidth);
        outputAreaItem.y = Qt.binding(() => outputArea.y * outputItem.outputHeight);
        outputAreaItem.width = Qt.binding(() => tabletSizeHandle.x);
        outputAreaItem.height = Qt.binding(() => tabletSizeHandle.y);
        tabletSizeHandle.x = Qt.binding(() => outputArea.width * outputItem.outputWidth);
        tabletSizeHandle.y = Qt.binding(() => outputArea.height * outputItem.outputHeight);
        keepAspectRatio.checked = outputAreaItem.aspectRatio === (form.device.size.width / form.device.size.height)
    }



    readonly property rect outputAreaSetting: Qt.rect(outputAreaItem.x / outputItem.outputWidth,
                                                      outputAreaItem.y / outputItem.outputHeight,
                                                      outputAreaItem.width / outputItem.outputWidth,
                                                      outputAreaItem.height / outputItem.outputHeight)

    property bool changed: false

    onOutputAreaSettingChanged: {
        if (outputAreaView.device && changed) {
            outputAreaView.device.outputArea = outputAreaSetting;
        }
    }

    enabled: outputAreaView.device
    implicitHeight: outputItem.height + tabletItem.height + Kirigami.Units.largeSpacing + (keepAspectRatio.visible ? keepAspectRatio.implicitHeight + keepAspectRatio.anchors.topMargin : 0)

    Output {
        id: outputItem

        // Resolution of the selected display
        screenSize: outputsModel.data(outputsModel.index(outputsCombo.currentIndex, 0), Qt.UserRole + 2)

        width: parent.width
        height: implicitHeight

        Rectangle {
            id: outputAreaItem

            color: Kirigami.Theme.activeBackgroundColor
            opacity: 0.8
            readonly property real aspectRatio: outputAreaView.stretchToFill ? outputItem.aspectRatio : outputAreaView.device.size.width / outputAreaView.device.size.height
            width: tabletSizeHandle.x
            height: tabletSizeHandle.y

            ColumnLayout {
                anchors.centerIn: parent
                visible: outputAreaView.mapToPortion

                Kirigami.Icon {
                    source: "transform-move-symbolic"

                    Layout.alignment: Qt.AlignHCenter
                }

                QQC2.Label {
                    text: i18ndc("kcm_tablet", "tablet area position - size", "%1,%2 - %3×%4", String(Math.floor(outputAreaView.outputAreaSetting.x * outputItem.screenSize.width))
                        , String(Math.floor(outputAreaView.outputAreaSetting.y * outputItem.screenSize.height))
                        , String(Math.floor(outputAreaView.outputAreaSetting.width * outputItem.screenSize.width))
                        , String(Math.floor(outputAreaView.outputAreaSetting.height * outputItem.screenSize.height)))
                    textFormat: Text.PlainText

                    Layout.fillWidth: true
                }
            }

            border {
                width: 1
                color: Kirigami.Theme.highlightColor
            }

            DragHandler {
                cursorShape: Qt.ClosedHandCursor
                target: parent
                enabled: outputAreaView.mapToPortion
                onActiveChanged: { outputAreaView.changed = true }

                xAxis.minimum: 0
                xAxis.maximum: outputItem.outputWidth - outputAreaItem.width

                yAxis.minimum: 0
                yAxis.maximum: outputItem.outputHeight - outputAreaItem.height
            }

            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
            }

            QQC2.Button {
                id: tabletSizeHandle
                x: outputItem.width
                y: outputItem.width / parent.aspectRatio
                visible: outputAreaView.mapToPortion
                icon.name: "transform-scale-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18nd("kcm_tablet", "Resize the tablet area")
                QQC2.ToolTip {
                    text: tabletSizeHandle.text
                    visible: parent.hovered
                    delay: Kirigami.Units.toolTipDelay
                }

                DragHandler {
                    cursorShape: Qt.SizeFDiagCursor
                    target: parent
                    onActiveChanged: { outputAreaView.changed = true }

                    xAxis.minimum: 10
                    xAxis.maximum: outputItem.outputWidth

                    yAxis.minimum: keepAspectRatio.checked ? (outputAreaItem.width * tabletItem.inverseAspectRatio) : 10
                    yAxis.maximum: keepAspectRatio.checked ? (outputAreaItem.width * tabletItem.inverseAspectRatio) : outputItem.outputHeight
                }
            }
        }
    }

    Tablet {
        id: tabletItem

        anchors {
            top: outputItem.bottom
            topMargin: Kirigami.Units.largeSpacing
            horizontalCenter: parent.horizontalCenter
        }

        readonly property size outputSize: outputAreaView.device.size
        readonly property real aspectRatio: outputSize.width / outputSize.height
        readonly property real inverseAspectRatio: outputSize.height / outputSize.width

        property var mapped: mapToItem(outputAreaView, tabletItem.internalRect.x, tabletItem.internalRect.y)
        property var mappedSize: mapToItem(outputAreaView, tabletItem.internalRect.width, tabletItem.internalRect.height)

        outputWidth: parent.width * 0.7
        outputHeight: width / aspectRatio
    }

    QQC2.CheckBox {
        id: keepAspectRatio

        anchors {
            top: tabletItem.bottom
            topMargin: Kirigami.Units.largeSpacing
            horizontalCenter: parent.horizontalCenter
        }

        text: i18ndc("kcm_tablet", "@option:check", "Lock aspect ratio")
        visible: outputAreaView.mapToPortion
        checked: true
        onToggled: outputAreaView.resetOutputArea(outputAreaView.mode)
    }

    Shape {
        ShapePath {
            id: topLeftPath

            strokeWidth: 1
            strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.5)

            startX: outputAreaItem.parent.x + outputAreaItem.x
            startY: outputAreaItem.parent.y + outputAreaItem.y

            PathLine {
                x: tabletItem.mapped.x + tabletItem.x
                y: tabletItem.mapped.y + tabletItem.y
            }
        }

        ShapePath {
            id: topRightPath

            strokeWidth: 1
            strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.5)

            startX: outputAreaItem.parent.x + outputAreaItem.x + outputAreaItem.width
            startY: outputAreaItem.parent.y + outputAreaItem.y

            PathLine {
                x: tabletItem.mapped.x + tabletItem.mappedSize.x
                y: tabletItem.mapped.y + tabletItem.y
            }
        }

        ShapePath {
            id: bottomLeftPath

            strokeWidth: 1
            strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.5)

            startX: outputAreaItem.parent.x + outputAreaItem.x
            startY: outputAreaItem.parent.y + outputAreaItem.y + outputAreaItem.height

            PathLine {
                x: tabletItem.mapped.x + tabletItem.x
                y: tabletItem.mapped.y + tabletItem.mappedSize.y
            }
        }

        ShapePath {
            id: bottomRightPath

            strokeWidth: 1
            strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.5)

            startX: outputAreaItem.parent.x + outputAreaItem.x + outputAreaItem.width
            startY: outputAreaItem.parent.y + outputAreaItem.y + outputAreaItem.height

            PathLine {
                x: tabletItem.mapped.x + tabletItem.mappedSize.x
                y: tabletItem.mapped.y  + tabletItem.mappedSize.y
            }
        }
    }
}
