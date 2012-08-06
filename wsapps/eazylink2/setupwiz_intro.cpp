#include "setupwizard.h"
#include "setupwiz_intro.h"
#include "ui_setupwiz_intro.h"

SetupWiz_Intro::SetupWiz_Intro(QWidget *parent) :
    QWizardPage(parent),
    ui(new Ui::SetupWiz_Intro),
    m_scene(this)
{

    ui->setupUi(this);


    /**
      * Add the Picture of Z88 linked to Host
      */
    m_scene.addPixmap(QPixmap(":/images/z88Intro"));

    setTitle("Eazylink2 - (v." + QCoreApplication::applicationVersion() + ") Setup Wizard.");
    setSubTitle("Introduction:");


    static const QString Welcome_msg = "Welcome to the Eazylink2 Client Setup Wizard. The next\n"
                                       "few pages will guide you through configuring the client\n"
                                       "so it can start communicating with the Z88. Please make \n"
                                       "sure the Z88 has fresh batteries, and is connected to an\n"
                                       "available serial port on your host computer.\n";

    ui->IntroPic->setScene(&m_scene);
    ui->IntroText->setText(Welcome_msg);

}

SetupWiz_Intro::~SetupWiz_Intro()
{
    delete ui;
}

