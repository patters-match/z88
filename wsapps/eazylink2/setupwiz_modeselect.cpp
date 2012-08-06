#include <QDebug>
#include "setupwiz_modeselect.h"
#include "ui_setupwiz_modeselect.h"

SetupWiz_ModeSelect::SetupWiz_ModeSelect(QWidget *parent) :
    QWizardPage(parent),
    ui(new Ui::SetupWiz_ModeSelect)
{
    ui->setupUi(this);

    setTitle("Eazylink2 - (v." + QCoreApplication::applicationVersion() + ") Setup Wizard.");
    setSubTitle("Operation Mode:");

    static const QString textmsg = "The Eazylink2 Client supports two Z88 Pull-downs:\n"
                                   "The Full featured Eazylink, and the basic Imp-Export.\n\n";

    ui->OpModeText->setText(textmsg);

    registerField("modeEzlink", ui->ezlink_btn);
    registerField("modeImpExp", ui->impexp_btn);
}

SetupWiz_ModeSelect::~SetupWiz_ModeSelect()
{
    delete ui;
}
