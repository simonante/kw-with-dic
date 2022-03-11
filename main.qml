import QtQuick 2.11
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 1.0
import io.singleton 1.0

Window {
    id: root
    visible: true
    title: qsTr("edit")
    width: screen.width
    height: screen.height

    property int rotation: 90
    property string doc: "scratch"
    property int mode: 1
    property bool ctrlPressed: false
    property bool isOmni1: false
    property bool isOmni2: false
    property string omniQuery1: ""
    property string omniQuery2: ""
    property string currentFile: "scratch.md"
//    property string folder: "file://%1/edit/".arg(home_dir)

    FolderListModel {
        id: folderModel1
        folder: "file:///home/root/edit/"
        nameFilters: ["*.md"]
    }
    
    FolderListModel {
        id: folderModel2
        folder: "file:///home/root/dic/"
        nameFilters: ["*.md"]
    }

    function toggleMode() { // temp: esc to save file; no need for md view
        if (mode == 0) {
            mode = 1
        } else {
            doc = query.text;
            mode = 0
        }
        saveFile()
    }

    function doLoad(name) {
        var xhr = new XMLHttpRequest
//        xhr.open("GET", folder + name)
        xhr.open("GET", "file:///home/root/edit/" + name)
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var response = xhr.responseText
                isOmni1 = false
                isOmni2 = false
                mode = 1 // first edit mode?
                currentFile = name
                doc = response

            }
        }
        xhr.send()
    }

    function saveFile() {
        console.log("Save " + currentFile)
        var fileUrl = "file:///home/root/edit/" + currentFile
        console.log(fileUrl)
        var request = new XMLHttpRequest()
        request.open("PUT", fileUrl, false)
        request.send(doc)
        console.log("save -> " + request.status + " " + request.statusText)
        return request.status
    }

    function initFile(name) {
        console.log("Init " + name)
        var fileUrl = "file:///home/root/edit/" + name + ".md"
        var request = new XMLHttpRequest()
        request.open("PUT", fileUrl, false)
        request.send("# " + name)
        console.log("save -> " + request.status + " " + request.statusText)
        return request.status
    }

    function handleKeyDown(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = true
        } else if (event.key === Qt.Key_K && ctrlPressed) {
            isOmni1 = !isOmni1
            event.accepted = true
        } else if (event.key === Qt.Key_Q && ctrlPressed) {
            Qt.quit()
        }
        saveFile()
    }
    
    function handleKeyDown(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = true
        } else if (event.key === Qt.Key_D && ctrlPressed) {
            isOmni2 = !isOmni2
            event.accepted = true
        } else if (event.key === Qt.Key_Q && ctrlPressed) {
            Qt.quit()
        }
        saveFile()
    }
    
    function handleKeyUp(event) {
        if (event.key === Qt.Key_Control) {
            ctrlPressed = false
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (isOmni1) {
                isOmni1 = false
            if (isOmni2) {
                isOmni2 = false
            } else {

                toggleMode()
            }
        }

        if (mode == 1)
            switch (event.key) {
            case Qt.Key_Home:
                Qt.quit()
                break
            case Qt.Key_G: // G contra right arrow
                if (ctrlPressed) // ctrl
                    root.rotation = (root.rotation + 90) % 360
                break
            case Qt.Key_H: // H contra left arrow
                if (ctrlPressed) // ctrl
                    root.rotation = (root.rotation - 90) % 360
                break
            }
    }

    Component.onCompleted: {
        doLoad(currentFile)
    }

    Rectangle {
        rotation: root.rotation
        id: body
        width: root.rotation % 180 ? root.height * 0.74 : root.width * 0.74 //this works in portrait
        height: root.rotation % 180 ? root.width : root.height // root.height affects portrait
        anchors.centerIn: parent // ?
        color: "white"
        border.color: "black"
        border.width: 0
        EditUtils {
            id: utils
        }

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: query.paintedWidth
            contentHeight: query.paintedHeight
            bottomMargin: parent.height /2
            clip: true

            function ensureVisible(r)
            {
                if (contentX >= r.x)
                    contentX = r.x;
                else if (contentX+width <= r.x+r.width)
                    contentX = r.x+r.width-width;
                if (contentY >= r.y)
                    contentY = r.y;
                else if (contentY+height <= r.y+r.height)
                    contentY = r.y+r.height-height;
            }

            function scrollUpSmall() {
                contentY -= 400;
            }
            function scrollDownSmall() {
                contentY += 400;
            }

            function scrollUpBig() {
                contentY -= 45000;
                saveFile()
            }
            function scrollDownBig() {
                contentY += 45000;
                saveFile()
            }

            TextEdit {
                id: query
//                width: body.width
//                height: body.height
//                width:1404;
                width: root.rotation % 180 ? root.height * 0.74 : root.width * 0.74
                Keys.enabled: true
                wrapMode: TextEdit.Wrap
                textMargin: 12
                textFormat: mode == 0 ? TextEdit.PlainText : TextEdit.PlainText
                font.family: mode == 0 ? "Noto Mono" : "Noto Mono"
                text: mode == 0 ? doc : doc
                focus: !isOmni1
                Component {
                    id: curDelegate
                    Rectangle { width:8; height: 20; visible: query.cursorVisible; color: "black";}
                }
                cursorDelegate: curDelegate
                readOnly: mode == 0 ? false : false
                font.pointSize: mode == 0 ? 7.5 : 7.5

                onLinkActivated: {
                    console.log("Link activated: " + link)
                    doLoad(link)
                }

                Keys.onPressed: {
                    if (mode == 1 && (event.key == Qt.Key_Down)) {
                        flick.scrollDownSmall();
                    }
                    if (mode == 1 && (event.key == Qt.Key_Up)) {
                        flick.scrollUpSmall();
                    }                
                    if (mode == 1 && (event.key == Qt.Key_S && ctrlPressed)) {
                        flick.scrollDownBig();
                    }
                    if (mode == 1 && (event.key == Qt.Key_W && ctrlPressed)) {
                        flick.scrollUpBig();
                    }

                    handleKeyDown(event);
                }

                Keys.onReleased: {
                    handleKeyUp(event)
                    handleKey(event)
                }
            }
        }

        Rectangle {
            id: quick1
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: "white"
            visible: isOmni1 ? true : false
//            visible: isOmni2 ? false : true
            radius: 20

            TextEdit {
                id: omniQueryTextEdit1
                text: omniQuery1
                textFormat: TextEdit.PlainText
                x: 40
                width: parent.width
                color: "white"
                font.pointSize: 7.7
                font.family: "Noto Mono"
                focus: isOmni1
                Keys.enabled: true
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Return) {
                        saveFile()
                        if (!omniList1.currentItem) {
                            initFile(omniQuery1)
                            doLoad(omniQuery1 + ".md")
                        } else {
                            doLoad(omniList1.currentItem.text)
                        }
                        isOmni1 = true // isOmni1 = false
                        isOmni2 = false
                        event.accepted = true
                        return
                    }

                    handleKeyDown(event)
                }
                Keys.onReleased: {
                    handleKeyUp(event)
                    handleKey(event)
                    omniQuery1 = omniQueryTextEdit1.text
                    folderModel1.nameFilters = [omniQuery1 + "*"]
                }

                Keys.forwardTo: omniList1
            }
            ListView {
                id: omniList1
                anchors.top: omniQueryTextEdit1.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 68
                anchors.rightMargin: 40
                anchors.right: parent.right
                highlightResizeDuration: 0
                highlight: Rectangle {
                    color: "black"
                    radius: 2
                    width: 600
                }
                Component {
                    id: fileDelegate1
                    Text {
                        width: parent.width
                        text: fileName
                        font.pointSize: 7.5
                        font.family: "Noto Mono"
                        color: ListView.isCurrentItem ? "white" : "black"
                    }
                }

                model: folderModel1
                delegate: fileDelegate1
            }
        }
        
        Rectangle {
            id: quick2
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: "white"
            visible: isOmni2 ? true : false
//            visible: isOmni1 ? false : true
            radius: 20

            TextEdit {
                id: omniQueryTextEdit2
                text: omniQuery2
                textFormat: TextEdit.PlainText
                x: 40
                width: parent.width
                color: "white"
                font.pointSize: 7.7
                font.family: "Noto Mono"
                focus: isOmni2
                Keys.enabled: true
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Return) {
                        saveFile()
                        if (!omniList2.currentItem) {
                            initFile(omniQuery2)
                            doLoad(omniQuery2 + ".md")
                        } else {
                            doLoad(omniList2.currentItem.text)
                        }
                        isOmni2 = true // isOmni2 = false
                        isOmni1 = false
                        event.accepted = true
                        return
                    }

                    handleKeyDown(event)
                }
                Keys.onReleased: {
                    handleKeyUp(event)
                    handleKey(event)
                    omniQuery2 = omniQueryTextEdit2.text
                    folderModel2.nameFilters = [omniQuery2 + "*"]
                }

                Keys.forwardTo: omniList2
            }
            ListView {
                id: omniList2
                anchors.top: omniQueryTextEdit2.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 68
                anchors.rightMargin: 40
                anchors.right: parent.right
                highlightResizeDuration: 0
                highlight: Rectangle {
                    color: "black"
                    radius: 2
                    width: 600
                }
                Component {
                    id: fileDelegate2
                    Text {
                        width: parent.width
                        text: fileName
                        font.pointSize: 7.5
                        font.family: "Noto Mono"
                        color: ListView.isCurrentItem ? "white" : "black"
                    }
                }

                model: folderModel2
                delegate: fileDelegate2
            }
        }
    }
}
