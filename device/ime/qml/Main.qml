import QtQuick
import QtQuick.Window
import Remarkable.ChineseToolkit.Ime 1.0

Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    color: "#f7f7f4"
    title: "reMarkable Chinese IME"

    property string outputText: ""
    property var keyboardRows: [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    function selectNextSchema() {
        if (!ime.ready || ime.schemas.length === 0)
            return

        var currentIndex = -1
        for (var i = 0; i < ime.schemas.length; ++i) {
            if (ime.schemas[i].id === ime.currentSchema) {
                currentIndex = i
                break
            }
        }

        var nextIndex = (currentIndex + 1) % ime.schemas.length
        ime.selectSchema(ime.schemas[nextIndex].id)
    }

    RimeEngine {
        id: ime
        onCommitted: function(text) {
            root.outputText += text
        }
    }

    Component.onCompleted: ime.initialize()

    Text {
        id: title
        x: 48
        y: 36
        text: "reMarkable Chinese IME"
        color: "#111111"
        font.pixelSize: 34
        font.bold: true
    }

    Rectangle {
        id: schemaButton
        width: 360
        height: 60
        anchors.right: parent.right
        anchors.rightMargin: 48
        y: 30
        color: schemaMouse.pressed ? "#111111" : "#ecece7"
        border.color: "#222222"
        border.width: 2
        radius: 6

        Text {
            anchors.centerIn: parent
            text: ime.currentSchema.length > 0
                  ? "輸入方案：" + ime.currentSchema
                  : "未選擇輸入方案"
            color: schemaMouse.pressed ? "#ffffff" : "#222222"
            font.pixelSize: 21
        }

        MouseArea {
            id: schemaMouse
            anchors.fill: parent
            onClicked: root.selectNextSchema()
        }
    }

    Rectangle {
        id: outputPanel
        x: 48
        y: 100
        width: parent.width - 96
        height: Math.max(260, parent.height * 0.27)
        color: "#ffffff"
        border.color: "#222222"
        border.width: 2
        radius: 8

        Text {
            anchors.fill: parent
            anchors.margins: 28
            text: root.outputText.length > 0 ? root.outputText : "輸入結果會顯示喺呢度"
            color: root.outputText.length > 0 ? "#111111" : "#777777"
            font.pixelSize: 34
            wrapMode: Text.Wrap
        }

        Rectangle {
            width: 128
            height: 60
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            color: clearMouse.pressed ? "#111111" : "#eeeeea"
            border.color: "#222222"
            radius: 6

            Text {
                anchors.centerIn: parent
                text: "清除"
                color: clearMouse.pressed ? "#ffffff" : "#111111"
                font.pixelSize: 24
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                onClicked: {
                    root.outputText = ""
                    ime.clearComposition()
                }
            }
        }
    }

    Rectangle {
        id: compositionPanel
        x: 48
        y: outputPanel.y + outputPanel.height + 28
        width: parent.width - 96
        height: 86
        color: "#ecece7"
        border.color: "#333333"
        radius: 6

        Text {
            anchors.fill: parent
            anchors.margins: 20
            verticalAlignment: Text.AlignVCenter
            text: ime.preedit.length > 0 ? ime.preedit : "開始輸入..."
            color: ime.preedit.length > 0 ? "#111111" : "#777777"
            font.pixelSize: 30
        }
    }

    Row {
        id: candidateRow
        x: 48
        y: compositionPanel.y + compositionPanel.height + 18
        width: parent.width - 96
        height: 92
        spacing: 10

        Repeater {
            model: ime.candidates

            Rectangle {
                required property var modelData
                required property int index

                width: Math.max(126, candidateText.implicitWidth + 46)
                height: candidateRow.height
                color: candidateMouse.pressed ? "#111111" : "#ffffff"
                border.color: "#222222"
                border.width: 2
                radius: 6

                Text {
                    id: candidateText
                    anchors.centerIn: parent
                    text: (index + 1) + "  " + modelData.text
                    color: candidateMouse.pressed ? "#ffffff" : "#111111"
                    font.pixelSize: 30
                }

                MouseArea {
                    id: candidateMouse
                    anchors.fill: parent
                    onClicked: ime.selectCandidate(index)
                }
            }
        }
    }

    Column {
        id: keyboard
        x: 48
        y: candidateRow.y + candidateRow.height + 28
        width: parent.width - 96
        spacing: 14

        Repeater {
            model: root.keyboardRows

            Row {
                required property var modelData
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: modelData

                    Rectangle {
                        required property string modelData
                        width: Math.min(116, (keyboard.width - 100) / 10)
                        height: 94
                        color: keyMouse.pressed ? "#111111" : "#ffffff"
                        border.color: "#222222"
                        border.width: 2
                        radius: 6

                        Text {
                            anchors.centerIn: parent
                            text: modelData.toUpperCase()
                            color: keyMouse.pressed ? "#ffffff" : "#111111"
                            font.pixelSize: 30
                        }

                        MouseArea {
                            id: keyMouse
                            anchors.fill: parent
                            onClicked: ime.processKey(modelData)
                        }
                    }
                }
            }
        }

        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: [
                    { label: "上一頁", key: "pageUp", width: 160 },
                    { label: "空白／選字", key: "space", width: 420 },
                    { label: "下一頁", key: "pageDown", width: 160 },
                    { label: "刪除", key: "backspace", width: 160 },
                    { label: "Enter", key: "enter", width: 160 }
                ]

                Rectangle {
                    required property var modelData
                    width: modelData.width
                    height: 94
                    color: actionMouse.pressed ? "#111111" : "#ddddda"
                    border.color: "#222222"
                    border.width: 2
                    radius: 6

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: actionMouse.pressed ? "#ffffff" : "#111111"
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        onClicked: ime.processKey(modelData.key)
                    }
                }
            }
        }
    }

    Text {
        x: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: parent.width - 96
        text: ime.error.length > 0
              ? ime.error
              : "Standalone prototype · 未接入 Xochitl · 請勿安裝到 3.28 Beta"
        color: ime.error.length > 0 ? "#8a1c1c" : "#555555"
        font.pixelSize: 21
        wrapMode: Text.Wrap
    }
}
