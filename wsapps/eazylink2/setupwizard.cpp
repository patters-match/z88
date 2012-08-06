#include <QDebug>
#include "setupwizard.h"

SetupWizard::SetupWizard(Prefrences_dlg *prefs, QWidget *parent) :
    QWizard(parent),
    m_pref_dlg(prefs),
    m_serSelectPage(NULL)
{
    /**
      * Create a Mac style Wizard.
      */
    setWizardStyle(QWizard::MacStyle);

    setOption(QWizard::NoBackButtonOnStartPage );

    setButtonText(QWizard::CustomButton1, "Find Z88");

    /**
      * Add the Intro Page
      */
    addPage(new SetupWiz_Intro(this));

    /**
      * Add the Mode Selection Page
      */
    addPage(new SetupWiz_ModeSelect(this));

    /**
      * Add the Serial Select Page
      */
    addPage(m_serSelectPage = new SetupWiz_SerialSelect(this, this));

    /**
      * Add the Final Summary Page
      */
    addPage(new SetupWiz_FinalPage(this, this));

    /**
      * Set up Signals
      */
   // connect(this, SIGNAL(customButtonClicked(int)), this, SLOT(CustomButtonClicked(int)));
}

void SetupWizard::accept()
{
    QDialog::accept();

}

void SetupWizard::setPort(const QString &shortname)
{
    m_portname = shortname;
}

const QString &SetupWizard::getPort() const
{
    return m_portname;
}

void SetupWizard::CustomButtonClicked(int which)
{
    QString msg;

    /**
      * Scan for the z88 Selected
      */
    if(which == QWizard::CustomButton1){
        /**
         * User has Specified Ezlink is on Z88
         */
        if(field("modeEzlink").toBool()){


            qDebug() << " Give Ezlink help here";
        }
        else{
            /**
              * The Imp-Export Protocol, so Perform a Raw test.
              */
            qDebug() << " give imp-exp help";

        }

    }
}
