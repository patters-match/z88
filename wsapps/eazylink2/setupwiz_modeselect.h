#ifndef SETUPWIZ_MODESELECT_H
#define SETUPWIZ_MODESELECT_H

#include <QWizardPage>

namespace Ui {
class SetupWiz_ModeSelect;
}

class SetupWiz_ModeSelect : public QWizardPage
{
    Q_OBJECT
    
public:
    explicit SetupWiz_ModeSelect(QWidget *parent = 0);
    ~SetupWiz_ModeSelect();
    
private:
    Ui::SetupWiz_ModeSelect *ui;
};

#endif // SETUPWIZ_MODESELECT_H
