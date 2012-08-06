#ifndef SETUPWIZARD_H
#define SETUPWIZARD_H

#include <QWizard>

#include "setupwiz_intro.h"
#include "setupwiz_modeselect.h"
#include "setupwiz_serialselect.h"
#include "setupwiz_finalpage.h"

class Prefrences_dlg;

class SetupWizard : public QWizard
{
    Q_OBJECT
public:
    explicit SetupWizard(Prefrences_dlg *prefs, QWidget *parent = 0);
    
    void accept();

    enum { Page_Intro,
           Page_ModeSel,
           Page_SerialSel,
           Page_EzLinkTest,
           Page_TerminalTest
         };

    Prefrences_dlg *get_prefsDialog() const {return m_pref_dlg;}

    void setPort(const QString &shortname);
    const QString &getPort()const;

signals:
    
public slots:
    void CustomButtonClicked(int which);

protected:
    Prefrences_dlg *m_pref_dlg;

    SetupWiz_SerialSelect *m_serSelectPage;

    QString m_portname;
};

#endif // SETUPWIZARD_H
