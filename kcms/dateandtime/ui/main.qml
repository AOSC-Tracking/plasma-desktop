/*
 *   SPDX-FileCopyrightText: 2024 Niccolò Venerandi <niccolo@venerandi.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick

ListTimezoneSelector {

    selectedTimeZone: DTime.selectedTimeZone

    Connections {
        target: DTime
        onSelectedTimeZoneChanged: {
            selectedTimeZone = DTime.selectedTimeZone
        }
    }

    onSelectedTimeZoneChanged: {
        DTime.selectedTimeZone = selectedTimeZone
    }
}
