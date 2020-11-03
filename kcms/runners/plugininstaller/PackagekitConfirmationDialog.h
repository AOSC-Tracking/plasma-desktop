/*
    SPDX-FileCopyrightText: 2020 Alexander Lohnau <alexander.lohnau@gmx.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <QDialog>
#include <QVBoxLayout>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QLabel>
#include <QIcon>

#include <KLocalizedString>
#include <KIO/OpenFileManagerWindowJob>

class PackagekitConfirmationDialog : public QDialog {
public:
    PackagekitConfirmationDialog(const QString &packagePath, QWidget *parent = nullptr) : QDialog(parent)
    {
        setWindowTitle(i18nc("@title:window", "Confirm Installation"));
        setWindowIcon(QIcon::fromTheme(QStringLiteral("dialog-information")));
        QVBoxLayout *layout = new QVBoxLayout(this);
        QString msg = xi18nc("@info", "You are about to install a binary package. You should only install these from a trusted author/packager.");
        QLabel *msgLabel = new QLabel(msg, this);
        msgLabel->setWordWrap(true);
        msgLabel->setMaximumWidth(500);
        layout->addWidget(msgLabel);

        auto *buttonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
        buttonBox->button(QDialogButtonBox::Ok)->setIcon(QIcon::fromTheme("emblem-warning"));
        buttonBox->button(QDialogButtonBox::Ok)->setText(i18nc("@action:button", "Accept Risk And Continue"));
        connect(buttonBox, &QDialogButtonBox::accepted, this, [this](){ done(1); });
        connect(buttonBox, &QDialogButtonBox::rejected, this, [this](){ done(0); });

        QPushButton *highlightFileButton = new QPushButton(QIcon::fromTheme("document-open-folder"), i18nc("@action:button", "View File"), this);
        connect(highlightFileButton, &QPushButton::clicked, this, [packagePath]() {
            KIO::highlightInFileManager({QUrl::fromLocalFile(packagePath)});
        });
        buttonBox->addButton(highlightFileButton, QDialogButtonBox::HelpRole);
        buttonBox->button(QDialogButtonBox::Cancel)->setFocus();
        layout->addWidget(buttonBox);
    }
};
