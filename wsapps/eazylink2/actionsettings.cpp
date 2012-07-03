#include "actionsettings.h"
#include "ui_actionsettings.h"

#include <QTableWidget>
#include <QInputDialog>
#include <QFileDialog>
#include <QMessageBox>
#include <QDateTime>

#include<QDebug>

namespace Action_Settings{
    const char *ActKey_DBLCLK_HOSTFILE = "DBLCLKDSK";
    const char *ActKey_DBLCLK_Z88FILE = "DBLCLKZ88";
    const char *ActKey_RX_FROMZ88 = "RXFROMZ88";
    const char *ActKey_TX_TOZ88 ="TXTOZ88";
    const int OPEN_WITH_ID = 1; // Id for external launch

    const char *DEFAULT_FILESPEC_ARGS = "%F";
    const char *DEFAULT_Z88_DESTSPEC  = "%P/%F";
    const char *DEFAULT_FULLFSPEC     = "%P/%F";


    /**
      * The Current Action Profile Bd version.
      * increment this Any time the Format Changes.
      * That forces a Defualt Refresh.
      */
    extern const int Action_db_version = 2;
}

ActionSettings::ActionSettings(QWidget *parent) :
    QFrame(parent),
    ui(new Ui::ActionSettings),
    m_TableChanged(false),
    m_lastActionSel(-1)
{
    ui->setupUi(this);

    connect(ui->Ui::ActionSettings::ActionList,
            SIGNAL(currentIndexChanged(QString)),
            this,
            SLOT(action_itemSlectionChanged(const QString &)));

    connect(ui->Ui::ActionSettings::MimeTable,
            SIGNAL(cellChanged(int,int)),
            this,
            SLOT(cellDataCHanged(int,int)));

    connect(ui->Ui::ActionSettings::MimeTable,
            SIGNAL(cellDoubleClicked(int,int)),
            this,
            SLOT(cellDblClicked(int,int)));

    connect(ui->Ui::ActionSettings::MimeTable,
            SIGNAL(itemSelectionChanged()),
            this,
            SLOT(ft_itemSelectionChanged()));

    connect(ui->Ui::ActionSettings::FT_DelButton,
            SIGNAL(clicked()),
            this,
            SLOT(ft_deleteItem()));

    connect(ui->Ui::ActionSettings::FT_UpButton,
            SIGNAL(clicked()),
            this,
            SLOT(ft_itemUp()));

    connect(ui->Ui::ActionSettings::FT_DnButton,
            SIGNAL(clicked()),
            this,
            SLOT(ft_itemDn()));

    connect(ui->Ui::ActionSettings::FT_AddButton,
            SIGNAL(clicked()),
            this,
            SLOT(ft_addItem()));

    ui->Ui::ActionSettings::MimeTable->setSelectionMode(QAbstractItemView::SingleSelection);
    ui->Ui::ActionSettings::MimeTable->setColumnWidth(ft_filename, 125);
    ui->Ui::ActionSettings::MimeTable->setColumnWidth(ft_extension, 40);
    ui->Ui::ActionSettings::MimeTable->setColumnWidth(ft_action, 150);
    ui->Ui::ActionSettings::MimeTable->setColumnWidth(ft_args, 225);

}

ActionSettings::~ActionSettings()
{
    delete ui;
}

int ActionSettings::load_ActionList(int index)
{

    m_ft_items.clear();

    if(index > m_Actions.count()){
        return 0;
    }

    const FileAction fa = m_Actions[index];
    m_ft_items.append(fa.getAvail_Actions());

    /**
      * Clear all the User Entries
      */
    while(ui->Ui::ActionSettings::MimeTable->rowCount()){
          ui->Ui::ActionSettings::MimeTable->removeRow(0);
    }

    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

    int size = settings.beginReadArray(fa.get_KeyName());
    for (int i = 0; i < size; ++i) {
         settings.setArrayIndex(i);
         ui->Ui::ActionSettings::MimeTable->insertRow(i);
         ui->Ui::ActionSettings::MimeTable->setItem(i, ft_filename, new QTableWidgetItem(settings.value("ft_filename").toString()));
         ui->Ui::ActionSettings::MimeTable->setItem(i, ft_extension, new QTableWidgetItem( settings.value("ft_extension").toString()  ));

         /**
           * Add Action Col as write-protected
           */
         QTableWidgetItem *item = new QTableWidgetItem( settings.value("ft_action").toString() );
         item->setFlags(Qt::ItemIsSelectable|Qt::ItemIsEnabled);

         ui->Ui::ActionSettings::MimeTable->setItem(i, ft_action, item);
         ui->Ui::ActionSettings::MimeTable->setItem(i, ft_args, new QTableWidgetItem( settings.value("ft_args").toString()  ));
    }

    m_TableChanged = false;
    return size;
}

int ActionSettings::load_ActionList(const FileAction &fa, StringLList_t &ruleList)
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

    int size = settings.beginReadArray(fa.get_KeyName());

    for (int i = 0; i < size; ++i) {
        QStringList col_data;
        settings.setArrayIndex(i); // set the row in the database
        col_data.append(settings.value("ft_filename").toString());
        col_data.append(settings.value("ft_extension").toString());
        col_data.append(settings.value("ft_action").toString());
        col_data.append(settings.value("ft_args").toString());

        ruleList.append(col_data);
    }

    return size;
}

int ActionSettings::reLoadActionList()
{
    return load_ActionList(ui->Ui::ActionSettings::ActionList->currentIndex());
}

int ActionSettings::save_ActionList(int index)
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");
    if(index < m_Actions.count()){
        const FileAction fa = m_Actions[index];//ui->Ui::ActionSettings::ActionList->currentIndex()];
        return save_ActionList(settings, fa);
    }
    return 0;
}

int ActionSettings::save_ActionList()
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");
    const FileAction fa = m_Actions[ui->Ui::ActionSettings::ActionList->currentIndex()];

    return save_ActionList(settings, fa);
}

int ActionSettings::save_ActionList(QSettings &settings)
{
    const FileAction fa = m_Actions[ui->Ui::ActionSettings::ActionList->currentIndex()];
    return save_ActionList(settings, fa);
}

int ActionSettings::save_ActionList(QSettings &settings, const FileAction &fa )
{
    /**
      * Key-Name is currently selected Action
      */
    QString ArrayKey(fa.get_KeyName());

    int cnt = ui->Ui::ActionSettings::MimeTable->rowCount();

    /**
      * Write the Entire Table
      */
    settings.beginWriteArray(ArrayKey, cnt);

    for(int idx = 0; idx < cnt; idx++){
        settings.setArrayIndex(idx);
        settings.setValue("ft_filename", ui->Ui::ActionSettings::MimeTable->item(idx, ft_filename)->text());
        settings.setValue("ft_extension",ui->Ui::ActionSettings::MimeTable->item(idx, ft_extension)->text());
        settings.setValue("ft_action",   ui->Ui::ActionSettings::MimeTable->item(idx, ft_action)->text());
        settings.setValue("ft_args",     ui->Ui::ActionSettings::MimeTable->item(idx, ft_args)->text());
    }
    settings.endArray();

    m_TableChanged = false;

    return cnt;
}

void ActionSettings::Append_FileAction(const FileAction &fa)
{
    m_Actions.append(fa);
    ui->Ui::ActionSettings::ActionList->addItem(fa.get_descStr());

    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");

     /**
       * Create a Default set Semaphore
       */
    bool isDefSet = (settings.value(fa.get_KeyName() + "_DEFSET").toInt() == Action_Settings::Action_db_version);

    /**
      * Save the Default Values Only Once
      * or if the Version Format changed
      */
    if(!isDefSet) {
         qDebug() << "Resetting [" << fa.get_descStr() << "] Actions to defaults.";

         set_Defaults(fa.getDefaults());
         settings.setValue(fa.get_KeyName() + "_DEFSET" , Action_Settings::Action_db_version);
         save_ActionList(settings, fa);
         load_ActionList(0);
    }
}

int ActionSettings::findAction(const QString &ActionKey, const QString Fspec)
{
    QString CmdLine;
    return findAction(ActionKey, Fspec, CmdLine);
}

/**
  * Find an Action for the Specified FileName.
  * @param ActionKey is the Sting of the Action Key Happening.
  * @param Fspec is the filename to perform matches.
  * @return the Index of the selected actions, from the avail list.
  */
int ActionSettings::findAction(const QString &ActionKey, const QString Fspec, QString &CmdLine)
{
    FileAction *fa = getFileAction(ActionKey);

    if(fa){
        /* A list of rules. each rule is a list of columns. */
        StringLList_t ruleList;

        int cnt = load_ActionList(*fa, ruleList);

        for(int idx = 0; idx < cnt; idx++){
            if(isMatch(Fspec, ruleList[idx])){
                expandCmdline(ruleList[idx][ft_args], Fspec, CmdLine);
                return fa->get_indexOf(ruleList[idx][ft_action]);
            }
        }
    }

    return -1;
}

FileAction *ActionSettings::getFileAction(const QString &ActionStr)
{
    for(int idx=0; idx < m_Actions.count(); idx++){
        if(m_Actions[idx].get_KeyName() == ActionStr){
            return &(m_Actions[idx]);
        }
    }
    return NULL;
}

bool ActionSettings::isMatch(const QString &fspec, const QStringList &Col_data)
{
    bool wcard = false;

    QString fname;
    QString matchname;

    /**
     * Stip leading path
     */
    int idx = fspec.lastIndexOf('/');

    if(idx >=0){
        fname = fspec.mid(idx + 1);
    }
    else{
        fname = fspec;
    }

    /**
      * Match Filename
      */
    if(Col_data[ft_filename] != "*"){
        matchname = Col_data[ft_filename];
    }
    else
        wcard = true;

    /**
      * Match Extension
      */
    if(Col_data[ft_extension] != "*"){
        matchname += "." + Col_data[ft_extension];
    }
    else
        wcard = true;

    /**
      * Complete *.* Wildcard match true
      */
    if(matchname.isEmpty() && wcard) {
        return true;
    }

    if(!fname.compare(matchname, Qt::CaseInsensitive)){
            // "Exact match found";
        return true;
    }

    /**
      * A Wildcard match
      */
    if(wcard){
        if(matchname.length() <= fname.length()){
            if(fname.right(matchname.length()).contains(matchname, Qt::CaseInsensitive)){
                return true;
            }
        }
    }

    return false;
}

QString & ActionSettings::expandCmdline(const QString &cmdline, const QString &fspec, QString &result)
{
    QStringList argv;

    argv = cmdline.split(" ");

    result.clear();

    for(int idx=0; idx < argv.count(); idx++){

        if(!result.isEmpty()){
            result += " ";
        }

        QString fs;
        QString arg = argv[idx];

        int i = fspec.lastIndexOf('/');

        if(i >= 0){
            fs = fspec.mid(0, i);
        }
        else
            fs = fspec;

        /**
          * Expand %P is Path & Filename
          */
        arg.replace("%P", fs);

        /**
          * %F is the Filename without the Path
          */

        if(i >=0){
            fs = fspec.mid(i + 1);
        }
        else{
            fs = fspec;
        }

        arg.replace("%F", fs);

        QDateTime dateTime = QDateTime::currentDateTime();

        arg.replace("%T", dateTime.toString("hhmmss"));
        arg.replace("%D", dateTime.toString("yyMMdd"));
        arg.replace("%S", dateTime.toString("ss"));
        arg.replace("%M", dateTime.toString("MM"));
        arg.replace("%m", dateTime.toString("mm"));

        result += arg;
    }
    return result;
}

void ActionSettings::ft_itemSelectionChanged()
{
    int currow = ui->Ui::ActionSettings::MimeTable->currentRow();
    int rows = ui->Ui::ActionSettings::MimeTable->rowCount();

    ui->Ui::ActionSettings::FT_DnButton->setEnabled((currow + 1) < rows);
    ui->Ui::ActionSettings::FT_UpButton->setEnabled((currow - 1) >= 0);
    ui->Ui::ActionSettings::FT_DelButton->setEnabled(rows > 0);
}

void ActionSettings::ft_deleteItem()
{
    m_TableChanged = true;
    ui->Ui::ActionSettings::MimeTable->removeRow(ui->Ui::ActionSettings::MimeTable->currentRow());
    ft_itemSelectionChanged();

}

void ActionSettings::ft_itemUp()
{
    int currow = ui->Ui::ActionSettings::MimeTable->currentRow();
    int curcol = ui->Ui::ActionSettings::MimeTable->currentColumn();

    ui->Ui::ActionSettings::MimeTable->insertRow(currow - 1);

    QTableWidgetItem *item;
    for(int idx = 0; idx < ft_columns; idx++){
        item = ui->Ui::ActionSettings::MimeTable->takeItem(currow + 1, idx);
        ui->Ui::ActionSettings::MimeTable->setItem(currow - 1, idx, item);
    }

    ui->Ui::ActionSettings::MimeTable->removeRow(currow + 1);

    ui->Ui::ActionSettings::MimeTable->setCurrentCell(currow - 1, curcol);

    m_TableChanged = true;
}

void ActionSettings::ft_itemDn()
{
    int currow = ui->Ui::ActionSettings::MimeTable->currentRow();
    int curcol = ui->Ui::ActionSettings::MimeTable->currentColumn();

    ui->Ui::ActionSettings::MimeTable->insertRow(currow + 2);

    QTableWidgetItem *item;
    for(int idx = 0; idx < ft_columns; idx++){
        item = ui->Ui::ActionSettings::MimeTable->takeItem(currow, idx);
        ui->Ui::ActionSettings::MimeTable->setItem(currow + 2, idx, item);
    }

    ui->Ui::ActionSettings::MimeTable->removeRow(currow);

    ui->Ui::ActionSettings::MimeTable->setCurrentCell(currow + 1, curcol);

    m_TableChanged = true;
}

int ActionSettings::ft_addItem(const QString &fname, const QString &ext)
{
    QString newname;
    QString new_ext;

    bool ok = false;

    newname = QInputDialog::getText(this,
                                    "File Action Type",
                                    "Enter Filename:",
                                    QLineEdit::Normal,
                                    QString(fname),
                                    &ok);

    if(!ok || newname.isEmpty()){
        return 0;
    }

    new_ext = QInputDialog::getText(this,
                                    "File Action Extension",
                                    "Enter Extension:",
                                    QLineEdit::Normal,
                                    QString(ext),
                                    &ok);

    if(!ok || new_ext.isEmpty()){
        return 0;
    }

    QString action_str = QInputDialog::getItem(this, "Select an Action",
                                          tr("Select Action to Perform:"), m_ft_items, 0, false, &ok);

    if (ok && !action_str.isEmpty()){
        /**
          * If open With:...
          */
        QString exec_name;
        QString exec_args(Action_Settings::DEFAULT_FULLFSPEC); // Default args are just the file filename & path

        if(action_str == m_ft_items[Action_Settings::OPEN_WITH_ID]){

            QFileDialog dialog(this);
            dialog.setFileMode(QFileDialog::ExistingFile);
            dialog.setViewMode(QFileDialog::List);
            dialog.setFilter(QDir::Files | QDir::Dirs | QDir::Executable);

            QStringList src_fileNames;


            if(dialog.exec()){
                 src_fileNames = dialog.selectedFiles();
                 exec_name = src_fileNames.first();
                 QFileInfo qf(src_fileNames.first());

                 if(qf.isBundle() ||(qf.isFile() &&  qf.isExecutable())){

                    // * this is an executable.
                 }
                 else{
                     return 0;
                 }
            }
            else{
                return 0;
            }

        }
        int currow = ui->Ui::ActionSettings::MimeTable->currentRow();

        if(currow < 0){
            currow = ui->Ui::ActionSettings::MimeTable->rowCount();
        }

        m_TableChanged = true;

        ui->Ui::ActionSettings::MimeTable->insertRow(currow);

        ui->Ui::ActionSettings::MimeTable->setItem(currow, ft_filename, new QTableWidgetItem(newname, Transfer));
        ui->Ui::ActionSettings::MimeTable->setItem(currow, ft_extension, new QTableWidgetItem(new_ext));


        QTableWidgetItem *itm = new QTableWidgetItem(action_str);
        itm->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);

        ui->Ui::ActionSettings::MimeTable->setItem(currow, ft_action, itm);

        if(! exec_name.isEmpty()){
            exec_args = " " + exec_args;
        }

        ui->Ui::ActionSettings::MimeTable->setItem(currow, ft_args, new QTableWidgetItem(exec_name + exec_args));

        ui->Ui::ActionSettings::MimeTable->setCurrentCell(currow, 0);

        return 1;
    }
    return 0;
}

void ActionSettings::action_itemSlectionChanged(const QString &)
{
    if(m_TableChanged){
  //      qDebug() << "Changed from idx " << m_lastActionSel << " from :" << ui->Ui::ActionSettings::ActionList->itemText(m_lastActionSel);

        QMessageBox msgBox;
        QString msg = "Actions for ";
        msg += ui->Ui::ActionSettings::ActionList->itemText(m_lastActionSel);
        msg += " Have Changed.";


        msgBox.setText(msg);
        msgBox.setIcon(QMessageBox::Question);
        msgBox.setInformativeText("Do you want to save your changes ?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
        msgBox.setDefaultButton(QMessageBox::No);

        if(msgBox.exec() == QMessageBox::Yes){
            save_ActionList(m_lastActionSel);
        }
    }

    m_lastActionSel = ui->Ui::ActionSettings::ActionList->currentIndex();

    load_ActionList(m_lastActionSel);
}

void ActionSettings::cellDataCHanged(int, int)
{
    m_TableChanged = true;
}

/**
  * Edit and Replace a cell Contents.
  * @param row is the currently selected row
  * @param col is the currently selected col.
  */
void ActionSettings::cellDblClicked(int row, int col)
{
    if(col == ft_action){
        int rc = ft_addItem(ui->Ui::ActionSettings::MimeTable->item(row, ft_filename)->text(),
                            ui->Ui::ActionSettings::MimeTable->item(row, ft_extension)->text());

        /**
          * IF rc true, then remove the old entry.
          */
        if(rc){
            ui->Ui::ActionSettings::MimeTable->removeRow(row + 1);
        }
    }
}

void ActionSettings::set_Defaults(const StringLList_t &defaults)
{

    /**
      * Clear all the User Entries
      */
    while(ui->Ui::ActionSettings::MimeTable->rowCount()){
          ui->Ui::ActionSettings::MimeTable->removeRow(0);
    }


    for(int c_row = 0; c_row < defaults.count(); c_row++){
        const QStringList &cols_data(defaults[c_row]);

        ui->Ui::ActionSettings::MimeTable->insertRow(c_row);

        for(int c_col = 0; c_col < ActionSettings::ft_columns; c_col++){
            if(c_col < cols_data.count()){
                ui->Ui::ActionSettings::MimeTable->setItem(c_row, c_col, new QTableWidgetItem(cols_data[c_col], Transfer));
            }
            else{
                ui->Ui::ActionSettings::MimeTable->setItem(c_row, c_col, new QTableWidgetItem(""));
            }
        }

    }
    //ui->Ui::ActionSettings::MimeTable->insertRow(currow);
    //ui->Ui::ActionSettings::MimeTable->setItem(currow, ft_filename, new QTableWidgetItem(newname, Transfer));

}

/**
  * File Action Contructor
  * @param KeyName is the Key used to Save the Option Array.
  * @param descStr is the Human Readable derscription of the Action
  */
FileAction::FileAction(const QString &KeyName, const QString &descStr, const QStringList &avail_actions, const StringLList_t &defaults) :
    m_KeyName(KeyName),
    m_descStr(descStr),
    m_AvailActions(avail_actions),
    m_defaultActions(defaults)
{


}

FileAction::~FileAction()
{

}

/**
  * Get the index of an Action String
  */
int FileAction::get_indexOf(const QString &ActionStr)
{
    for(int idx = 0; idx < m_AvailActions.count(); idx++){
        if(m_AvailActions[idx] == ActionStr){
            return idx;
        }
    }
    return -1;
}

#if 0
FileAction::FileAction(const QString &KeyName, const QString &descStr, const QStringList &avail_actions)
{
    StringLList_t defaults;
    FileAction(KeyName, descStr, avail_actions, defaults);
}
#endif

