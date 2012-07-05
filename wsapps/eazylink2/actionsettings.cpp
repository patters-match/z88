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

    const char *DEFAULT_FILESPEC_ARGS = "%F";
    const char *DEFAULT_Z88_DESTSPEC  = "%P/%F";
    const char *DEFAULT_FULLFSPEC     = "%P/%F";

    /**
      * The Current Action Profile Bd version.
      * increment this Any time the Format Changes.
      * That forces a Defualt Refresh.
      */
    extern const int Action_db_version = 3;
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

/**
  * Load the Action List Rules into the Table.
  * @param index is the Index into the List of File Actions to Load.
  * @return the count of entries in the table that was loaded.
  */
int ActionSettings::load_Action_RuleList(int index)
{

    m_ft_items.clear();

    if(index > m_Actions.count()){
        return 0;
    }

    const FileAction fa = m_Actions[index];

    /**
      * Append the Description list of Action rules
      */
    QListIterator<ActionRule> i(fa.getAvail_Rules());

    while(i.hasNext()){
        m_ft_items.append((i.next()));
    }

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

/**
  * Get All the Action rules for a Specified File Action.
  * @param fa is the File Action to read rules from.
  * @param ruleList is the Returned list of Action Rules.
  * @return the count of rules.
  */
int ActionSettings::load_Action_RuleList(const FileAction &fa, StringLList_t &ruleList)
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

/**
  * Reload the Displayed Rules for the Currently selected Action
  * @return the count of rules.
  */
int ActionSettings::reLoadActionRulesList()
{
    return load_Action_RuleList(ui->Ui::ActionSettings::ActionList->currentIndex());
}

/**
  * Save the Action Rules list for the specified Action Index.
  * @param index is the index of the Action in the list of Actions.
  * @return the count of rules saved.
  */
int ActionSettings::save_ActionList(int index)
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");
    if(index < m_Actions.count()){
        const FileAction fa = m_Actions[index];
        return save_ActionList(settings, fa);
    }
    return 0;
}

/**
  * Save the Rules of the Currently selected Action.
  * @return the count of rules saved.
  */
int ActionSettings::save_ActionList()
{
    QSettings settings(QSettings::UserScope, "z88", "EazyLink2");
    const FileAction fa = m_Actions[ui->Ui::ActionSettings::ActionList->currentIndex()];

    return save_ActionList(settings, fa);
}

/**
  * Save the Rules of the Currently selected Action.
  * @param settings is an opened Config Setting.
  * @return the count of rules saved.
  */
int ActionSettings::save_ActionList(QSettings &settings)
{
    const FileAction fa = m_Actions[ui->Ui::ActionSettings::ActionList->currentIndex()];
    return save_ActionList(settings, fa);
}

/**
  * Save the Rules of the Specified File Action.
  * @param settings is an open cfg.
  * @param fa is the file action to save rules.
  * @return the count of rules saved.
  */
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

/**
  * Add an Action to the Action Combo Box,
  * @param fa the file action to append.
  */
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
         load_Action_RuleList(0);
    }
}

/**
  * Find an Action for the Specified FileName.
  * @param ActionKey is the Sting of the Action Key Happening.
  * @param Fspec is the filename to perform matches.
  * @return the Index of the selected actions, from the avail list.
  */
int ActionSettings::findAction(const QString &ActionKey, const QString Fspec)
{
    QString CmdLine;
    return findAction(ActionKey, Fspec, CmdLine);
}

/**
  * Find an Action for the Specified FileName.
  * @param ActionKey is the Sting of the Action Key Happening.
  * @param Fspec is the filename to perform matches.
  * @param CmdLine is the Returned Modified Fspec based on the Action rules Args.
  * @return the Index of the selected actions, from the avail list.
  */
int ActionSettings::findAction(const QString &ActionKey, const QString Fspec, QString &CmdLine)
{
    FileAction *fa = getFileAction(ActionKey);

    if(fa){
        /* A list of rules. each rule is a list of columns. */
        StringLList_t ruleList;

        int cnt = load_Action_RuleList(*fa, ruleList);

        for(int idx = 0; idx < cnt; idx++){
            if(isMatch(Fspec, ruleList[idx])){
                expandCmdline(ruleList[idx][ft_args], Fspec, CmdLine);
                return fa->get_indexOf(ruleList[idx][ft_action]);
            }
        }
    }

    return -1;
}

/**
  * Search for a Matching Rule for the Specified Filename.
  * @param ActionKey is the Rule Class KEY used to store the rules in the Database.
  * @param Fspec is the Filename to qualify.
  * @param CmdLine is the Resulting command line if there was a matching rule.
  * @return the Action rule object that was matched.
  */
const ActionRule *ActionSettings::findActionRule(const QString &ActionKey, const QString Fspec, QString &CmdLine)
{

    FileAction *fa = getFileAction(ActionKey);

    if(fa){
        /* A list of rules. each rule is a list of columns. */
        StringLList_t ruleList;

        int cnt = load_Action_RuleList(*fa, ruleList);

        for(int idx = 0; idx < cnt; idx++){
            if(isMatch(Fspec, ruleList[idx])){
                expandCmdline(ruleList[idx][ft_args], Fspec, CmdLine);
                return fa->get_ActionRule(ruleList[idx][ft_action]);
            }
        }
    }
    return NULL;
}

/**
  * Get the File Action object for the Specified Action String
  * @param ActionStr is the Description of the Action to find.
  * @return the FileAction Object that matches the search, or NULL
  */
FileAction *ActionSettings::getFileAction(const QString &ActionStr)
{
    for(int idx=0; idx < m_Actions.count(); idx++){
        if(m_Actions[idx].get_KeyName() == ActionStr){
            return &(m_Actions[idx]);
        }
    }
    return NULL;
}

/**
  * Compare a Filename with a Row From the Action Rule Set.
  * @param fspec is the Filename to match,
  * @param ActionRule is a String list of the columns of a rule row.
  * @return true if there is a rule match.
  */
bool ActionSettings::isMatch(const QString &fspec, const QStringList &ActionRule)
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
    if(ActionRule[ft_filename] != "*"){
        matchname = ActionRule[ft_filename];
    }
    else
        wcard = true;

    /**
      * Match Extension
      */
    if(ActionRule[ft_extension] != "*"){
        matchname += "." + ActionRule[ft_extension];
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

/**
  * Expand the Command Line Args for the Specified Filename.
  * @param cmdline is the input command line to expand.
  * @param fspec is the Filename used for substitutions into the result cmd line.
  * @param result is the Resulting expanded Commandline.
  * @return the Expanded command line.
  */
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

/**
  * The USer Selected a Different Item
  */
void ActionSettings::ft_itemSelectionChanged()
{
    int currow = ui->Ui::ActionSettings::MimeTable->currentRow();
    int rows = ui->Ui::ActionSettings::MimeTable->rowCount();

    ui->Ui::ActionSettings::FT_DnButton->setEnabled((currow + 1) < rows);
    ui->Ui::ActionSettings::FT_UpButton->setEnabled((currow - 1) >= 0);
    ui->Ui::ActionSettings::FT_DelButton->setEnabled(rows > 0);
}

/**
  * Delete the Selected Rule
  */
void ActionSettings::ft_deleteItem()
{
    m_TableChanged = true;
    ui->Ui::ActionSettings::MimeTable->removeRow(ui->Ui::ActionSettings::MimeTable->currentRow());
    ft_itemSelectionChanged();

}

/**
  * Move the Selected Rule Up one Slot.
  */
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

/**
  * Move the selected Rule Down one Slot.
  */
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

/**
  * Prompt the User for adding a New Rule Item.
  * @param fname is the default File name of the Filter to show.
  * @param ext is the default extension to match.
  * @return 1 on success.
  */
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

        const FileAction fa = m_Actions[ui->Ui::ActionSettings::ActionList->currentIndex()];
        const ActionRule *arule = fa.get_ActionRule(action_str);

        if(!arule){
            qDebug() << "Action Rules are Messed.";
            exit(-1);
        }

        /**
          * If open With:...
          */
        QString exec_name;
        QString exec_args(arule->m_defaultArgs); // Default args are just the file filename & path

        if(arule->m_RuleID == ActionRule::OPEN_WITH_EXT_APP){

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
        /* If non selected, prepend the rule */
        if(currow < 0){
            currow = 0;
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

/**
  * The Action Combo Box Item Selection Changed.
  */
void ActionSettings::action_itemSlectionChanged(const QString &)
{
    if(m_TableChanged){
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

    load_Action_RuleList(m_lastActionSel);
}

/**
  * Signal that gets called when a Cell is Edited.
  */
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

/**
  * Set the default Action Rules
  */
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
}

/**
  * File Action Contructor
  * @param KeyName is the Key used to Save the Option Array.
  * @param descStr is the Human Readable derscription of the Action
  */
FileAction::FileAction(const QString &KeyName, const QString &descStr, const ActionRuleList_t &avail_actions, const StringLList_t &defaults) :
    m_KeyName(KeyName),
    m_descStr(descStr),
    m_AvailRules(avail_actions),
    m_defaultFilters(defaults)
{


}

FileAction::~FileAction()
{

}

/**
  * Get the index of an Action Rule String
  * @param RuleStr is the Description of a Rule.
  * @return the Index into the list of Available rules.
  */
int FileAction::get_indexOf(const QString &RuleStr)const
{
    for(int idx = 0; idx < m_AvailRules.count(); idx++){
        if(m_AvailRules[idx] == RuleStr){
            return idx;
        }
    }
    return -1;
}

/**
  * Get the Action Rule for the Action rule description.
  * @param RuleStr is the Rule Description string to match
  * @return the ActoinRule Class object that matches the description
  */
const ActionRule *FileAction::get_ActionRule(const QString &RuleStr)const
{
    int idx = get_indexOf(RuleStr);

    if(idx < 0){
        return NULL;
    }

    return &(m_AvailRules[idx]);
}

/**
  * Action Rule Constructor
  * @param desc is a description String.
  * @param def_args is a string of the default command args.
  * @param flags describe the Rule's role.
  */
ActionRule::ActionRule(const QString &desc, const QString &def_args, Rule_IDs flags) :
    QString(desc),
    m_defaultArgs(def_args),
    m_RuleID(flags)
{

}

/**
  * Action Rule Constructor
  * @param desc is a description String.
  * @param def_args is a string of the default command args.
  * @param flags describe the Rule's role.
  */
ActionRule::ActionRule(const char *desc, const char*def_args, Rule_IDs flags) :
    QString(desc),
    m_defaultArgs(def_args),
    m_RuleID(flags)
{

}


