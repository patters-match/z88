#include <QTextStream>
#include <QDebug>
#include "setupwiz_finalpage.h"
#include "ui_setupwiz_finalpage.h"
#include "setupwizard.h"
#include "prefrences_dlg.h"


/**
  * The Final Page of the Setup Wizard.
  * @param setupWiz is the Root Setup Wizard.
  */
SetupWiz_FinalPage::SetupWiz_FinalPage(SetupWizard *setupWiz, QWidget *parent) :
    QWizardPage(parent),
    m_setupWizard(setupWiz),
    ui(new Ui::SetupWiz_FinalPage)
{
    ui->setupUi(this);
}

SetupWiz_FinalPage::~SetupWiz_FinalPage()
{
    delete ui;
}

/**
  * Callback event that gets called if user hits 'back'
  */
void SetupWiz_FinalPage::cleanupPage()
{
    /**
      * Make the custome scan button invisible.
      */
    wizard()->setOption(QWizard::HaveCustomButton2, true);
}

/**
  * Callback event that happens when user hits 'next' and enters this page
  */
void SetupWiz_FinalPage::initializePage()
{
    QString msg;
    QTextStream omsg(&msg);

#ifndef Q_OS_MAC
    static const QString btn_name("Finish");
#else
    static const QString btn_name("Done");
#endif

    if(field("modeEzlink").toBool()){
        omsg << "You have successfully configured Eazylink2 to optimally communicate with the Z88 "
                "using the Eazylink Pull-down." << endl;

    }
    else{
        omsg << "You have successfully configured Eazylink2 to communicate with the Z88 using the Imp-Export "
                "Z88 Pull-down." << endl;

        /**
          * Check to see if the User Used the Scan for Z88 Option.
          * Then Remind them to close the Terminal.
          */
        if(field("rawTested").toBool()){

            omsg << endl
                 << "***NOTE: Make sure you exit the Terminal on the Z88 "
                    "before you try using Imp-Export." << endl << endl;

            omsg << "(To Exit Z88 Terminal: Press <Shift-ENTER>)." << endl;
        }
    }

    omsg << endl <<  endl
         << "Click \'" << btn_name << "\' to save settings and start using Eazylink2." << endl;

    ui->FinalMsg->setText(msg);
}

/**
  * Save the Setting into the Prefs panel.
  */
bool SetupWiz_FinalPage::validatePage()
{
    /**
      * Setup the Preferences based on the selected port, and the Type of protocol.
      */
     m_setupWizard->get_prefsDialog()->WriteWizardCfg(m_setupWizard->getPort(),
                                                      field("modeEzlink").toBool());

    return true;
}


