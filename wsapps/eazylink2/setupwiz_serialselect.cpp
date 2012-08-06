#include <QDebug>
 #include <QCheckBox>
#include "setupwiz_serialselect.h"
#include "ui_setupwiz_serialselect.h"
#include "setupwizard.h"
#include "prefrences_dlg.h"
#include "commthread.h"

static const QString FIND_Z88_BTN_TXT = "Find Z88";
static const QString ST_SCAN_BTN_TXT = "Start Scan";
static const QString AB_SCAN_BTN_TXT = "Abort Scan";
static const QString DET_HELP_BTN_TXT = "Detailed Help";
static const QString REG_HELP_BTN_TXT = "Summary Help";

SetupWiz_SerialSelect::SetupWiz_SerialSelect(SetupWizard *setupWiz, QWidget *parent) :
    QWizardPage(parent),
    m_setupWizard(setupWiz),
    ui(new Ui::SetupWiz_SerialSelect)
{
    ui->setupUi(this);

    m_cthread = setupWiz->get_prefsDialog()->get_ComThread();

    setTitle("Eazylink2 - (v." + QCoreApplication::applicationVersion() + ") Setup Wizard.");
    setSubTitle("Serial Port Selection:");

    connect(ui->RefreshBtn,   SIGNAL(clicked()), this, SLOT(RefreshComsList()));

    connect(setupWiz, SIGNAL(customButtonClicked(int)), this, SLOT(CustomButtonClicked(int)));

    /**
      * Com Thread Test port-open results
      */
    connect(m_cthread, SIGNAL(openTest_Start(int)), this, SLOT(openTest_Start(int)));
    connect(m_cthread, SIGNAL(openTest_result(int, bool)), this, SLOT(openTest_result(int,bool)));

    /**
      * Load the Available Serial ports
      */
    setupWiz->get_prefsDialog()->RefreshComsList(ui->SerialPortList);

    /**
      * Display the Current Default Selection
      */
    QString portname;
    QString shortname;

    if(setupWiz->get_prefsDialog()->getSerialPort_Names(portname, shortname)){
        setupWiz->get_prefsDialog()->select_SerDevice(shortname, ui->SerialPortList);
    }

    /**
      * Create a Dummy flag used to display help if user Scanned the Raw mode
      */
    m_serTested = new QCheckBox;
    m_serTested->setCheckable(true);
    m_serTested->setChecked(false);

    registerField("SerPortName", ui->SerialPortList);
    registerField("rawTested", m_serTested);

}

SetupWiz_SerialSelect::~SetupWiz_SerialSelect()
{
    delete ui;
}

/**
  * Event that gets called when the user hits 'next' from the prev page.
  */
void SetupWiz_SerialSelect::initializePage()
{
    ui->HelpText->clear();
    ui->HelpText->setVisible(false);

    /**
      * Add and enable the Custom "Start scan" button
      */
    setButtonText(QWizard::CustomButton2, FIND_Z88_BTN_TXT);
    wizard()->setOption(QWizard::HaveCustomButton2);

    QString textmsg = "Select the Serial Port connected to the Z88.\n"
                      "If you are unsure, click \'Find Z88\' below, to"
                      " search for the\n Z88 connection.\n";

    ui->SerSelText->setText(textmsg);
}

/**
  * Event that gets called when user hits 'back'
  */
void SetupWiz_SerialSelect::cleanupPage()
{
    /**
      * Make the custome scan button invisible.
      */
    wizard()->setOption(QWizard::HaveCustomButton1, false);
    wizard()->setOption(QWizard::HaveCustomButton2, false);
    m_cthread->AbortCmd("");
}

/**
  * Event that gets called before moving to the next page
  */
bool SetupWiz_SerialSelect::validatePage()
{
    wizard()->setOption(QWizard::HaveCustomButton1, false);
    wizard()->setOption(QWizard::HaveCustomButton2, false);
    m_cthread->AbortCmd("");

    m_setupWizard->setPort(ui->SerialPortList->currentText());

    return true;
}

/**
  * An overloaded functon to enable / disable the Continue button.
  */
bool SetupWiz_SerialSelect::isComplete() const
{
    if(buttonText(QWizard::CustomButton2) == AB_SCAN_BTN_TXT){
        return false;
    }

    return true;
}

/**
  * Refresh the avail comm list, and default to the current port.
  */
void SetupWiz_SerialSelect::RefreshComsList()
{
    m_setupWizard->get_prefsDialog()->RefreshComsList(ui->SerialPortList);
}

/**
  * Clicked on start Serial Scan.
  * @param which is the Button pressed
  */
void SetupWiz_SerialSelect::CustomButtonClicked(int which)
{
    QString msg;

    /**
      * Detailed Help / Summary Help Toggle
      */
    if(which ==  QWizard::CustomButton1){

        if(buttonText(QWizard::CustomButton1) == DET_HELP_BTN_TXT){
            setButtonText(QWizard::CustomButton1, REG_HELP_BTN_TXT);

            QTextStream omsg(&msg);

            omsg << "Detailed Scan Instructions:" << endl;
            omsg << "---------------------------" << endl;
            omsg << "The Z88 Serial Settings must be configured correctly, before the "
                    "scan or the Eazylink2 software will operate correctly. "
                    "The Following steps will guide you through setting up the Z88, "
                    "and identifying the serial port it's connected to on the desktop." << endl << endl;

            omsg << "On the Z88, perform the following steps:" << endl;

            omsg << "1) Open Z88 Settings Panel (Press []S)" << endl;
            omsg << "    Verify the Settings match the following:" << endl;

            omsg << "    Transmit baud rate 9600" << endl;
            omsg << "    Receive  baud rate 9600" << endl;
            omsg << "    Parity None" << endl;
            omsg << "    Xon/Xoff Yes" << endl << endl;

            omsg << "If any of your settings are different, use the arrow keys to move to the"
                    " desired field, then press <>J until the the value is correct." << endl;
            omsg << "Press the \'ENTER\' key to save your changes, \'ESC\' to abandon changes." << endl << endl;

            omsg << "2) Open the Z88 Terminal (Press []V)" << endl << endl;

            omsg << "Watch the Z88 Terminal screen after you start the scan. "
                    "When the port is found, you will see the name"
                    " displayed on the terminal. Please select the port from the list of available "
                    "serial ports above." << endl << endl;

            omsg << "3) Click \'Start Scan\' Button Below, to begin the scan." << endl << endl;

            ui->HelpText->setVisible(true);
            ui->HelpText->setText(msg);
            return;
        }

        which = QWizard::CustomButton2;
        setButtonText(QWizard::CustomButton2, FIND_Z88_BTN_TXT);
        /* Drop through */
    }

    /**
      * Scan for the z88 Selected
      */
    if(which == QWizard::CustomButton2){

        /**
          * Start the Actual Scan
          */
        if(buttonText(QWizard::CustomButton2) == ST_SCAN_BTN_TXT){

            setButtonText(QWizard::CustomButton2, AB_SCAN_BTN_TXT);
            wizard()->setOption(QWizard::HaveCustomButton1, false);

            /**
              * Allow Final page to know that we tested the serial port.
              */
            m_serTested->setChecked(true);

            emit completeChanged();

            QStringList portList;

            /**
              * Get the List of fully qualified Device names
              */
            m_setupWizard->get_prefsDialog()->RefreshComsList(portList);

            /**
              * Scan for EzLink Mode Z88
              */
            StartZ88Scan(portList, field("modeEzlink").toBool());

            return;
        }

        /**
          * Abort Request
          */
        if(buttonText(QWizard::CustomButton2) == AB_SCAN_BTN_TXT){
            m_cthread->AbortCmd("Aborting Serial Port Scan...");
            ui->HelpText->setVisible(true);
            ui->HelpText->setText("Aborting Scan...");
            return;
        }

        /**
          * Set start scan button text
          */
        setButtonText(QWizard::CustomButton2, ST_SCAN_BTN_TXT);

        /**
         * User has Specified Ezlink is on Z88
         */
        if(field("modeEzlink").toBool()){

            msg = "Instructions to find the Z88:\n"
                  "-----------------------------\n"
                  "  1) Connect Z88 to Serial Port on Desktop.\n"
                  "  2) Launch the Eazylink Pull-down on the Z88.\n"
                  "  3) Click \'Start Scan\' button below.\n"
                  "  4) Wait for Z88 to be identified.";
        }
        else{
            /**
              * The Imp-Export Protocol, so Perform a Raw test.
              */
            msg = "Instructions to find the Z88:\n"
                  "-----------------------------\n"
                  "  1) Connect Z88 to Serial Port on Desktop.\n"
                  "  2) Launch the Terminal on the Z88.\n"
                  "  3) Click \'Start Scan\' button below.\n"
                  "  4) Watch the Z88 Screen to get port name.\n";

            /**
              * Add the detailed help Button
              */
            wizard()->setOption(QWizard::HaveCustomButton1);
            setButtonText(QWizard::CustomButton1, DET_HELP_BTN_TXT);

        }

        ui->HelpText->setVisible(true);
        ui->HelpText->setText(msg);
    }
}

/**
  * Start scan fro serial port
  * @param portIdx is the index into the list of available ports, to test.
  */
void SetupWiz_SerialSelect::openTest_Start(int portIdx)
{
    ui->HelpText->setVisible(true);
    ui->HelpText->setText("Scanning Serial port->[" + ui->SerialPortList->itemText(portIdx) +"]...");
}

/**
  * Open Port Test result Call-back
  * @param portIdx is the index of the found port.
  * @param success is true, if the Z88 was found
  */
void SetupWiz_SerialSelect::openTest_result(int portIdx, bool success)
{

    setButtonText(QWizard::CustomButton2, ST_SCAN_BTN_TXT);
    emit completeChanged();

    if(success){
        QString msg;
        QTextStream omsg(&msg);

        omsg << "Success!" << endl;
        omsg << "Found the Z88 connected to serial port: ";
        omsg << ui->SerialPortList->itemText(portIdx) << ".";

        ui->HelpText->setVisible(true);
        ui->HelpText->setText(msg);

        /**
          * Set the Combo box item to the found port
          */
        ui->SerialPortList->setCurrentIndex(portIdx);
        return;
    }

    /**
      * Failures
      */
    switch(portIdx){
        case -2:   // User pressed abort.
            ui->HelpText->setText("Scan Aborted.");
            return;
        case -3:  // Scan Complete in Raw Id mode.
            ui->HelpText->setText("The Serial Port Scan is Complete...\r\n"
                                  "Check the Z88 Screen. If the port was found,"
                                  " the screen will show the Serial Port's name. "
                                  "Please select this port from the list above. "
                                  "If you don't see any text on the Z88 Terminal, please check"
                                  " the serial connection, and verify port settings again.\r\n");
            return;
        break;
    }

    ui->HelpText->setText("Z88 Scan Failed!\n"
                          "Please make sure the Z88 is connected & running Eazylink.\n"
                          "If you keep getting this message, please click \'Go Back\',\n"
                          "select Imp-Export mode, click \'Find Z88\',\n"
                          "and follow the search instructions.\n");

    ui->HelpText->setVisible(true);
}

/**
  * Start scanning for the Z88 Serial port.
  * @param portList is the List of fully qualified Serial port names to try.
  * @param EzLInk set this to true to search using the Eazylink Protocol. False, performs ascii Search.
  * @return true if the Com thread was Idle.
  */
bool SetupWiz_SerialSelect::StartZ88Scan(const QStringList &portList, bool EzLink)
{
    return m_cthread->scanForZ88(portList, EzLink);
}



