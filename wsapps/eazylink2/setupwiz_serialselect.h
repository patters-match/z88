#ifndef SETUPWIZ_SERIALSELECT_H
#define SETUPWIZ_SERIALSELECT_H

#include <QWizardPage>
#include "serialportsavail.h"

namespace Ui {
class SetupWiz_SerialSelect;
}

class SetupWizard;
class CommThread;

class SetupWiz_SerialSelect : public QWizardPage
{
    Q_OBJECT
    
public:
    explicit SetupWiz_SerialSelect(SetupWizard *setupWiz, QWidget *parent);
    ~SetupWiz_SerialSelect();
    
    void initializePage();
    void cleanupPage();
    bool validatePage();

    bool isComplete() const;

private slots:
    void RefreshComsList();
    void CustomButtonClicked(int which);

    void openTest_Start(int portIdx);
    void openTest_result(int portIdx, bool success);

protected:
    bool StartZ88Scan(const QStringList &portList, bool EzLink = false);

private:

    SetupWizard *m_setupWizard;

    CommThread *m_cthread;

    QAbstractButton *m_serTested;

    Ui::SetupWiz_SerialSelect *ui;

};

#endif // SETUPWIZ_SERIALSELECT_H
