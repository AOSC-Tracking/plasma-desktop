/* This file is part of the KDE Project
   Copyright (c) 2014 Vishesh Handa <me@vhanda.in>
   Copyright (c) 2020 Alexander Lohnau <alexander.lohnau@gmx.de>
   Copyright (c) 2020 Cyril Rossi <cyril.rossi@enioka.com>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License version 2 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#include "kcm.h"

#include <KPluginFactory>
#include <KAboutData>
#include <QDebug>
#include <QStandardPaths>
#include <KLocalizedString>
#include <KRunner/RunnerManager>
#include <KPluginSelector>
#include <KNS3/Button>
#include <QApplication>
#include <QDBusMessage>
#include <QDBusConnection>
#include <QDBusMetaType>
#include <QVBoxLayout>
#include <QLabel>
#include <QDialog>
#include <QPainter>
#include <QFormLayout>

#include "krunnersettings.h"
#include "krunnerdata.h"

K_PLUGIN_FACTORY(SearchConfigModuleFactory, registerPlugin<SearchConfigModule>(); registerPlugin<KRunnerData>();)


SearchConfigModule::SearchConfigModule(QWidget* parent, const QVariantList& args)
    : KCModule(parent, args)
    , m_config(KSharedConfig::openConfig("krunnerrc"))
    , m_settings(new KRunnerSettings(this))
{
    KAboutData* about = new KAboutData(QStringLiteral("kcm_search"), i18nc("kcm name for About dialog", "Configure Search Bar"),
                                       QStringLiteral("0.1"), QString(), KAboutLicense::LGPL);
    about->addAuthor(i18n("Vishesh Handa"), QString(), QStringLiteral("vhanda@kde.org"));
    setAboutData(about);
    setButtons(Apply | Default);

    if(!args.at(0).toString().isEmpty()) {
        m_pluginID = args.at(0).toString();
    }

    QVBoxLayout *layout = new QVBoxLayout(this);

    QHBoxLayout *headerLayout = new QHBoxLayout;
    layout->addLayout(headerLayout);

    QLabel *label = new QLabel(i18n("Enable or disable plugins (used in KRunner and Application Launcher)"));

    m_clearHistoryButton = new QPushButton(i18n("Clear History"));
    m_clearHistoryButton->setIcon(QIcon::fromTheme(isRightToLeft() ? QStringLiteral("edit-clear-locationbar-ltr")
                                                                   : QStringLiteral("edit-clear-locationbar-rtl")));
    connect(m_clearHistoryButton, &QPushButton::clicked, this, [this] {
        KConfigGroup generalConfig(m_config->group("General"));
        generalConfig.deleteEntry("history", KConfig::Notify);
        generalConfig.sync();
    });

    QHBoxLayout *configHeaderLayout = new QHBoxLayout;
    QVBoxLayout *configHeaderLeft = new QVBoxLayout;
    QVBoxLayout *configHeaderRight = new QVBoxLayout;

    // Options where KRunner should pop up
    m_topPositioning = new QRadioButton(i18n("Top"), this);
    connect(m_topPositioning, &QRadioButton::toggled, this, &SearchConfigModule::updateUnmanagedState);
    m_freeFloating = new QRadioButton(i18n("Center"), this);
    connect(m_freeFloating, &QRadioButton::toggled, this, &SearchConfigModule::updateUnmanagedState);

    QFormLayout *positionLayout = new QFormLayout;
    positionLayout->addRow(i18n("Position on screen:"), m_topPositioning);
    positionLayout->addRow(QString(), m_freeFloating);
    m_enableHistory = new QCheckBox(i18n("Enable"), this);
    m_enableHistory->setObjectName("kcfg_historyEnabled");
    positionLayout->addItem(new QSpacerItem(0, 0));
    positionLayout->addRow(i18n("History:"), m_enableHistory);
    connect(m_enableHistory, &QCheckBox::toggled, m_clearHistoryButton, &QPushButton::setEnabled);
    m_retainPriorSearch = new QCheckBox(i18n("Retain previous search"), this);
    m_retainPriorSearch->setObjectName("kcfg_retainPriorSearch");
    positionLayout->addRow(QString(), m_retainPriorSearch);
    configHeaderLeft->addLayout(positionLayout);

    configHeaderRight->setSizeConstraint(QLayout::SetNoConstraint);
    configHeaderRight->setAlignment(Qt::AlignBottom);
    configHeaderRight->addWidget(m_clearHistoryButton);

    configHeaderLayout->addLayout(configHeaderLeft);
    configHeaderLayout->addStretch();
    configHeaderLayout->addLayout(configHeaderRight);

    headerLayout->addWidget(label);
    headerLayout->addStretch();

    m_pluginSelector = new KPluginSelector(this);
    connect(m_pluginSelector, &KPluginSelector::changed, this, &SearchConfigModule::updateUnmanagedState);

    qDBusRegisterMetaType<QByteArrayList>();
    qDBusRegisterMetaType<QHash<QString, QByteArrayList>>();
    // This will trigger the reloadConfiguration method for the runner
    connect(m_pluginSelector, &KPluginSelector::configCommitted, this, [](const QByteArray &componentName){
        QDBusMessage message = QDBusMessage::createSignal(QStringLiteral("/krunnerrc"),
                                                          QStringLiteral("org.kde.kconfig.notify"),
                                                          QStringLiteral("ConfigChanged"));
        const QHash<QString, QByteArrayList> changes = {{QStringLiteral("Runners"), {componentName}}};
        message.setArguments({QVariant::fromValue(changes)});
        QDBusConnection::sessionBus().send(message);
    });

    layout->addLayout(configHeaderLayout);
    layout->addSpacing(12);
    layout->addWidget(m_pluginSelector);

    QHBoxLayout *downloadLayout = new QHBoxLayout;
    KNS3::Button *downloadButton = new KNS3::Button(i18n("Get New Plugins..."), QStringLiteral("krunner.knsrc"), this);
    connect(downloadButton, &KNS3::Button::dialogFinished, this, [this](const KNS3::Entry::List &changedEntries) {
       if (!changedEntries.isEmpty()) {
           m_pluginSelector->clearPlugins();
QT_WARNING_PUSH
QT_WARNING_DISABLE_CLANG("-Wdeprecated-declarations")
QT_WARNING_DISABLE_GCC("-Wdeprecated-declarations")
           m_pluginSelector->addPlugins(Plasma::RunnerManager::listRunnerInfo(),
                                        KPluginSelector::ReadConfigFile,
                                        i18n("Available Plugins"), QString(),
                                        m_config);
QT_WARNING_POP
       }
    });
    downloadLayout->addStretch();
    downloadLayout->addWidget(downloadButton);
    layout->addLayout(downloadLayout);

    connect(this, &SearchConfigModule::defaultsIndicatorsVisibleChanged, this, &SearchConfigModule::updateUnmanagedState);
    connect(this, &SearchConfigModule::defaultsIndicatorsVisibleChanged, m_pluginSelector, &KPluginSelector::setDefaultsIndicatorsVisible);
    addConfig(m_settings, this);
}

void SearchConfigModule::load()
{
    KCModule::load();

    m_topPositioning->setChecked(!m_settings->freeFloating());
    m_freeFloating->setChecked(m_settings->freeFloating());

    m_clearHistoryButton->setEnabled(m_enableHistory->isChecked());

    // Set focus on the pluginselector to pass focus to search bar.
    m_pluginSelector->setFocus(Qt::OtherFocusReason);

QT_WARNING_PUSH
QT_WARNING_DISABLE_CLANG("-Wdeprecated-declarations")
QT_WARNING_DISABLE_GCC("-Wdeprecated-declarations")
    m_pluginSelector->addPlugins(Plasma::RunnerManager::listRunnerInfo(),
                    KPluginSelector::ReadConfigFile,
                    i18n("Available Plugins"), QString(),
                    m_config);
QT_WARNING_POP
    m_pluginSelector->load();

    if(!m_pluginID.isEmpty()){
        m_pluginSelector->showConfiguration(m_pluginID);
    }
}


void SearchConfigModule::save()
{
    m_settings->setFreeFloating(m_freeFloating->isChecked());
    m_settings->save();

    KCModule::save();

    m_pluginSelector->save();

    QDBusMessage message = QDBusMessage::createSignal(QStringLiteral("/krunnerrc"),
                                                      QStringLiteral("org.kde.kconfig.notify"),
                                                      QStringLiteral("ConfigChanged"));
    const QHash<QString, QByteArrayList> changes = {{QStringLiteral("Plugins"), {}}};
    message.setArguments({QVariant::fromValue(changes)});
    QDBusConnection::sessionBus().send(message);
}

void SearchConfigModule::defaults()
{
    KCModule::defaults();

    m_topPositioning->setChecked(!m_settings->defaultFreeFloatingValue());
    m_freeFloating->setChecked(m_settings->defaultFreeFloatingValue());

    m_pluginSelector->defaults();
}

void SearchConfigModule::updateUnmanagedState()
{
    bool isNeedSave = false;
    isNeedSave |= m_pluginSelector->isSaveNeeded();
    isNeedSave |= m_topPositioning->isChecked() == m_settings->freeFloating();
    isNeedSave |= m_freeFloating->isChecked() != m_settings->freeFloating();

    unmanagedWidgetChangeState(isNeedSave);

    bool isDefault = true;
    isDefault &= m_pluginSelector->isDefault();
    isDefault &= m_topPositioning->isChecked() != m_settings->defaultFreeFloatingValue();
    isDefault &= m_freeFloating->isChecked() == m_settings->defaultFreeFloatingValue();

    setDefaultIndicatorVisible(m_topPositioning, defaultsIndicatorsVisible() && m_topPositioning->isChecked() == m_settings->defaultFreeFloatingValue());
    setDefaultIndicatorVisible(m_freeFloating, defaultsIndicatorsVisible() && m_freeFloating->isChecked() != m_settings->defaultFreeFloatingValue());

    unmanagedWidgetDefaultState(isDefault);
}

void SearchConfigModule::setDefaultIndicatorVisible(QWidget *widget, bool visible)
{
    widget->setProperty("_kde_highlight_neutral", visible);
    widget->update();
}


#include "kcm.moc"
