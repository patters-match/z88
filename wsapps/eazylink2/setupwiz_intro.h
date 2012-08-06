#ifndef SETUPWIZ_INTRO_H
#define SETUPWIZ_INTRO_H

#include <QGraphicsPixmapItem>
#include <QGraphicsScene>
#include <QWizardPage>

namespace Ui {
class SetupWiz_Intro;
}

class SetupWiz_Intro : public QWizardPage
{
    Q_OBJECT
    
public:
    explicit SetupWiz_Intro(QWidget *parent = 0);
    ~SetupWiz_Intro();
    
private:
    Ui::SetupWiz_Intro *ui;

    QGraphicsScene m_scene;

};

#endif // SETUPWIZ_INTRO_H
