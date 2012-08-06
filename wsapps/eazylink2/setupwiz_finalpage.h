#ifndef SETUPWIZ_FINALPAGE_H
#define SETUPWIZ_FINALPAGE_H

#include <QWizardPage>

namespace Ui {
class SetupWiz_FinalPage;
}

class SetupWizard;

class SetupWiz_FinalPage : public QWizardPage
{
    Q_OBJECT
    
public:
    explicit SetupWiz_FinalPage(SetupWizard *setupWiz, QWidget *parent = 0);
    ~SetupWiz_FinalPage();
    
    void cleanupPage();

    void initializePage();
    bool validatePage();


private:
    SetupWizard *m_setupWizard;

    Ui::SetupWiz_FinalPage *ui;
};

#endif // SETUPWIZ_FINALPAGE_H
