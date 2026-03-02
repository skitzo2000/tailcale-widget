import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configPage

    width: parent.width
    height: parent.height

    // Auto-bound to config.xml's serverProfiles entry
    property alias cfg_serverProfiles: internal.profilesJson

    QtObject {
        id: internal
        property string profilesJson: "[]"
        property var profiles: []
        property int selectedIndex: 0
    }

    ListModel {
        id: profileListModel
    }

    Component.onCompleted: loadProfiles()

    function loadProfiles() {
        try {
            internal.profiles = JSON.parse(internal.profilesJson);
        } catch (e) {
            internal.profiles = [{"name": "Tailscale", "loginServerUrl": "", "authKey": ""}];
        }
        if (internal.profiles.length === 0) {
            internal.profiles = [{"name": "Tailscale", "loginServerUrl": "", "authKey": ""}];
        }
        profileListModel.clear();
        for (var i = 0; i < internal.profiles.length; i++) {
            profileListModel.append(internal.profiles[i]);
        }
        if (internal.selectedIndex >= internal.profiles.length) {
            internal.selectedIndex = 0;
        }
    }

    function saveProfiles() {
        var arr = [];
        for (var i = 0; i < profileListModel.count; i++) {
            var item = profileListModel.get(i);
            arr.push({
                name: item.name,
                loginServerUrl: item.loginServerUrl,
                authKey: item.authKey
            });
        }
        internal.profilesJson = JSON.stringify(arr);
    }

    function selectProfile(index) {
        if (index < 0 || index >= profileListModel.count) {
            return;
        }
        internal.selectedIndex = index;
        var profile = profileListModel.get(index);
        nameField.text = profile.name;
        loginServerField.text = profile.loginServerUrl;
        authKeyField.text = profile.authKey;
    }

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // Left side: profile list + buttons
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true

            QQC2.Label {
                text: i18n("Server Profiles")
                font.bold: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: profileListView
                    model: profileListModel
                    currentIndex: internal.selectedIndex
                    clip: true

                    delegate: QQC2.ItemDelegate {
                        width: profileListView.width
                        text: model.name
                        highlighted: index === internal.selectedIndex

                        onClicked: {
                            selectProfile(index);
                        }
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < count) {
                            selectProfile(currentIndex);
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                QQC2.Button {
                    id: addButton
                    icon.name: "list-add"
                    text: i18n("Add")

                    onClicked: {
                        var newProfile = {
                            name: i18n("New Profile"),
                            loginServerUrl: "",
                            authKey: ""
                        };
                        profileListModel.append(newProfile);
                        var newIndex = profileListModel.count - 1;
                        selectProfile(newIndex);
                        profileListView.currentIndex = newIndex;
                        saveProfiles();
                    }
                }

                QQC2.Button {
                    id: removeButton
                    icon.name: "list-remove"
                    text: i18n("Remove")
                    enabled: internal.selectedIndex > 0

                    onClicked: {
                        if (internal.selectedIndex <= 0) {
                            return;
                        }
                        profileListModel.remove(internal.selectedIndex);
                        var newIndex = Math.min(internal.selectedIndex, profileListModel.count - 1);
                        selectProfile(newIndex);
                        profileListView.currentIndex = newIndex;
                        saveProfiles();
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        // Right side: edit form for selected profile
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop

            QQC2.TextField {
                id: nameField
                Kirigami.FormData.label: i18n("Name:")
                Layout.fillWidth: true

                onTextEdited: {
                    if (internal.selectedIndex >= 0 && internal.selectedIndex < profileListModel.count) {
                        profileListModel.setProperty(internal.selectedIndex, "name", text);
                        saveProfiles();
                    }
                }
            }

            QQC2.TextField {
                id: loginServerField
                Kirigami.FormData.label: i18n("Login Server URL:")
                Layout.fillWidth: true
                placeholderText: i18n("Leave empty for official Tailscale")

                onTextEdited: {
                    if (internal.selectedIndex >= 0 && internal.selectedIndex < profileListModel.count) {
                        profileListModel.setProperty(internal.selectedIndex, "loginServerUrl", text);
                        saveProfiles();
                    }
                }
            }

            QQC2.TextField {
                id: authKeyField
                Kirigami.FormData.label: i18n("Auth Key:")
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: i18n("Optional pre-authentication key")

                onTextEdited: {
                    if (internal.selectedIndex >= 0 && internal.selectedIndex < profileListModel.count) {
                        profileListModel.setProperty(internal.selectedIndex, "authKey", text);
                        saveProfiles();
                    }
                }
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: internal.selectedIndex === 0
                type: Kirigami.MessageType.Information
                text: i18n("This is the built-in Tailscale profile and cannot be removed.")
            }
        }
    }

    // Populate the edit fields once the model is ready
    Connections {
        target: profileListModel
        function onCountChanged() {
            if (profileListModel.count > 0 && internal.selectedIndex >= 0) {
                selectProfile(internal.selectedIndex);
            }
        }
    }
}
