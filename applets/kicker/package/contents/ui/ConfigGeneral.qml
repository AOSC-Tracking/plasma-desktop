/***************************************************************************
 *   Copyright (C) 2014 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

GroupBox {
    id: configGeneral

    width: childrenRect.width
    height: childrenRect.height

    flat: true

    property alias cfg_useCustomButtonImage: useCustomButtonImage.checked
    property alias cfg_customButtonImage: customButtonImage.text

    property alias cfg_appNameFormat: appNameFormat.currentIndex
    property alias cfg_limitDepth: limitDepth.checked

    property alias cfg_useExtraRunners: useExtraRunners.checked
    property alias cfg_alignResultsToBottom: alignResultsToBottom.checked

    ColumnLayout {
        GroupBox {
            title: i18n("Icon")

            flat: true

            RowLayout {
                CheckBox {
                    id: useCustomButtonImage

                    text: i18n("Use custom image:")
                }

                TextField {
                    id: customButtonImage

                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: i18n("Behavior")

            flat: true

            ColumnLayout {
                RowLayout {
                    Label {
                        text: i18n("Show applications as:")
                    }

                    ComboBox {
                        id: appNameFormat

                        Layout.fillWidth: true

                        model: [i18n("Name only"), i18n("Description only"), i18n("Name (Description)"), i18n("Description (Name)")]
                    }
                }


                RowLayout {
                    CheckBox {
                        id: limitDepth

                        text: i18n("Flatten menu to a single level")
                    }

                    Label {
                        color: "red"

                        text: "← WIP/TODO"
                    }
                }
            }
        }

        GroupBox {
            title: i18n("Search")

            flat: true

            ColumnLayout {
                CheckBox {
                    id: useExtraRunners

                    text: i18n("Search to bookmarks, files and emails")
                }

                CheckBox {
                    id: alignResultsToBottom

                    text: i18n("Align search results to bottom")
                }
            }
        }
    }
}
