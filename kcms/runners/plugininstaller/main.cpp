/*
    SPDX-FileCopyrightText: 2020 Alexander Lohnau <alexander.lohnau@gmx.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <QDebug>
#include <QUrl>
#include <QApplication>
#include <KLocalizedString>
#include <QCommandLineParser>
#include <KMessageBox>
#include <QMimeDatabase>
#include <QFileInfo>

#include "PackageKitJob.h"
#include "ScriptJob.h"

void fail(const QString &str)
{
    if (!str.isEmpty()) {
        KMessageBox::error(nullptr, str, i18nc("@info", "KRunner plugin installation failed"));
    }
    qApp->exit(1);
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps, true);

    QCommandLineParser parser;
    parser.addPositionalArgument(QStringLiteral("command"), i18nc("@info:shell", "Command to execute: install or uninstall."));
    parser.addPositionalArgument(QStringLiteral("path"), i18nc("@info:shell", "Path to archive."));
    parser.process(app);

    const QStringList args = parser.positionalArguments();
    if (args.isEmpty()) {
        qWarning() << "Command is required";
        return 1;
    }
    if (args.size() == 1) {
        qWarning() << "Path to archive is required";
        return 1;
    }

    const QString cmd = args[0];
    const QString file = args[1];
    const QStringList binaryPackages = {QStringLiteral("application/vnd.debian.binary-package"),
                                        QStringLiteral("application/x-rpm"),
                                        QStringLiteral("application/x-xz"),
                                        QStringLiteral("application/zstd")};
    Operation operation;
    if (cmd == QLatin1String("install")) {
        operation = Operation::Install;
    } else if (cmd == QLatin1String("uninstall")) {
        operation = Operation::Uninstall;
    } else {
        qWarning() << "Unsupported command" << cmd;
        return 1;
    }

    AbstractJob *job;
    const QString mimeType = QMimeDatabase().mimeTypeForFile(QFileInfo(file)).name();
    if (binaryPackages.contains(mimeType)) {
        job = new PackageKitJob();
    } else {
        job = new ScriptJob();
    }

    QObject::connect(job, &AbstractJob::finished, qApp,  [job]() {
        delete job;
        qApp->exit();
    }, Qt::QueuedConnection);
    QObject::connect(job, &AbstractJob::error, qApp, [job](const QString &error) {
        delete job;
        fail(error);
    }, Qt::QueuedConnection);

    job->executeOperation(file, operation);

    return app.exec();
}
