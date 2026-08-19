/*
 * SPDX-FileCopyrightText: 2026 AOSC OS Maintainers
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.timezoneselector as TimeZone

Kirigami.FormLayout {
    id: root

    property string selectedTimeZone: ""

    readonly property var geographicRegions: [
        "Africa",
        "America",
        "Antarctica",
        "Arctic",
        "Asia",
        "Atlantic",
        "Australia",
        "Europe",
        "Indian",
        "Pacific",
    ]
    readonly property var availableTimeZones: TimeZone.TimeZoneUtils.availableTimeZoneIds()
    readonly property var areasByRegion: {
        const result = {
            "UTC": [],
        };

        availableTimeZones.forEach(value => {
            const timeZoneId = String(value);
            const [region, area] = root.split(timeZoneId);
            if (!root.geographicRegions.includes(region) || !area) {
                return;
            }

            if (!result[region]) {
                result[region] = [];
            }
            if (!result[region].includes(area)) {
                result[region].push(area);
            }
        });

        Object.values(result).forEach(areas => areas.sort());
        return result;
    }
    readonly property var regionsModel: Object.keys(areasByRegion).sort()

    function understandable(id: string): string {
        return id.split("/").join(", ").split("_").join(" ");
    }

    function technical(id: string): string {
        return id.split(", ").join("/").split(" ").join("_");
    }

    function split(id: string): list<string> {
        const separator = id.indexOf("/");
        if (separator < 0) {
            return [root.understandable(id), ""];
        }
        return [root.understandable(id.slice(0, separator)), root.understandable(id.slice(separator + 1))];
    }

    function synchronizeSelection(): void {
        const [region, area] = root.split(root.selectedTimeZone);
        regionComboBox.currentIndex = Math.max(regionComboBox.model.indexOf(region), 0);
        areaComboBox.model = root.areasByRegion[region] ?? [];
        areaComboBox.currentIndex = areaComboBox.model.indexOf(area);
    }

    Component.onCompleted: root.synchronizeSelection()
    onSelectedTimeZoneChanged: root.synchronizeSelection()

    QQC2.ComboBox {
        id: regionComboBox

        readonly property string chooseText: i18ndc("plasmashellprivateplugin", "Placeholder for empty time zone combobox selector", "Choose…")

        Kirigami.FormData.label: i18ndc("plasmashellprivateplugin", "@label:listbox In the context of time zone selection", "Region:")
        Layout.fillWidth: true
        model: [chooseText, ...root.regionsModel]

        Accessible.name: i18nd("plasmashellprivateplugin", "Timezone region selector")

        onActivated: {
            if (currentText === chooseText) {
                return;
            }

            const areas = root.areasByRegion[currentText] ?? [];
            areaComboBox.model = areas;
            if (areas.length === 0) {
                areaComboBox.currentIndex = -1;
                root.selectedTimeZone = root.technical(currentText);
            } else if (currentText !== root.split(root.selectedTimeZone)[0]) {
                areaComboBox.currentIndex = -1;
            }
        }
    }

    QQC2.ComboBox {
        id: areaComboBox

        Kirigami.FormData.label: i18ndc("plasmashellprivateplugin", "@label:listbox In the context of time zone selection", "Time zone:")
        Layout.fillWidth: true
        model: []
        visible: model.length > 0

        Accessible.name: i18nd("plasmashellprivateplugin", "Timezone location selector")

        displayText: currentIndex < 0 ? regionComboBox.chooseText : currentText

        onActivated: {
            root.selectedTimeZone = root.technical(regionComboBox.currentText) + "/" + root.technical(currentText);
        }
    }
}
