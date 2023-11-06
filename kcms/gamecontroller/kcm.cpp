/*
    SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
    SPDX-FileCopyrightText: 2023 Jeremy Whiting <jpwhiting@kde.org>
    SPDX-FileCopyrightText: 2023 Niccolò Venerandi <niccolo@venerandi.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "kcm.h"

#include <KPluginFactory>
#include <SDL.h>

#include "axesmodel.h"
#include "buttonmodel.h"
#include "devicemodel.h"

K_PLUGIN_CLASS_WITH_JSON(KCMGameController, "kcm_gamecontroller.json")

KCMGameController::KCMGameController(QObject *parent, const KPluginMetaData &metaData)
    : KQuickManagedConfigModule(parent, metaData)
{
    SDL_Init(SDL_INIT_GAMECONTROLLER);

    setButtons(Help);

    constexpr const char *uri{"org.kde.plasma.gamecontroller.kcm"};

    qmlRegisterType<DeviceModel>(uri, 1, 0, "DeviceModel");
    qmlRegisterType<AxesModel>(uri, 1, 0, "AxesModel");
    qmlRegisterType<ButtonModel>(uri, 1, 0, "ButtonModel");
}

KCMGameController::~KCMGameController()
{
    SDL_Quit();
}

#include "kcm.moc"
