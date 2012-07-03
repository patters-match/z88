#ifndef ACTIONSETTINGS_H
#define ACTIONSETTINGS_H

#include <QFrame>
#include<QSettings>

namespace Ui {
class ActionSettings;
}

namespace Action_Settings{

    extern const int Action_db_version;

    extern const char *ActKey_DBLCLK_HOSTFILE;// = "DBLCLKDSK";
    extern const char *ActKey_DBLCLK_Z88FILE; // = "DBLCLKZ88";
    extern const char *ActKey_RX_FROMZ88;     // = "RXFROMZ88";
    extern const char *ActKey_TX_TOZ88;       // = "TXTOZ88";

    extern const int OPEN_WITH_ID;

    extern const char *DEFAULT_FILESPEC_ARGS;
    extern const char *DEFAULT_Z88_DESTSPEC;//  = "%F";


}

typedef QList<QStringList> StringLList_t;

static const StringLList_t empty_list;

/**
  * Container to Handle a File Action.
  */
class FileAction {

public:
    explicit FileAction(const QString &KeyName, const QString &descStr, const QStringList &avail_actions, const StringLList_t &defaults = empty_list);
    ~FileAction();

    const QString &get_KeyName()const {return m_KeyName;}
    const QString &get_descStr()const {return m_descStr;}
    const QStringList &getAvail_Actions() const {return m_AvailActions;}
    const StringLList_t &getDefaults() const{return m_defaultActions;}

    int get_indexOf(const QString & ActionStr);
protected:

    QString m_KeyName;
    QString m_descStr;

    QStringList m_AvailActions;

    StringLList_t m_defaultActions;
};

typedef QList<FileAction> FileActionList_T;


class ActionSettings : public QFrame
{
    Q_OBJECT
    
public:
    explicit ActionSettings(QWidget *parent = NULL);
    ~ActionSettings();

    enum ft_columns{
        ft_filename,
        ft_extension,
        ft_action,
        ft_args,
        ft_columns
    };

    enum DblClk_Actions{
        Do_Nothing = 1001,
        Transfer,
        OpenFile
    };

    enum ActionKeys{
        Action_DBL_CLICK_DESK,
        Action_DBL_CLICK_Z88,
        Action_RX_FROM_Z88,
        Action_TX_TO_Z88
    };

    int load_ActionList(int index);
    int load_ActionList(const FileAction &fa, StringLList_t &ruleList);
    int reLoadActionList();


    int save_ActionList();
    int save_ActionList(int index);
    int save_ActionList(QSettings &settings);
    int save_ActionList(QSettings &settings, const FileAction &fa);

    void Append_FileAction(const FileAction & fa);

    int findAction(const QString &ActionKey, const QString Fspec);

    int findAction(const QString &ActionKey, const QString Fspec, QString &CmdLine);

private slots:
    void ft_itemSelectionChanged();
    void ft_deleteItem();
    void ft_itemUp();
    void ft_itemDn();
    int ft_addItem(const QString &fname = "*", const QString &ext = "*");

    void action_itemSlectionChanged(const QString &);
    void cellDataCHanged(int , int );
    void cellDblClicked(int row, int col);


private:
    void set_Defaults(const StringLList_t &defaults);

    FileAction *getFileAction(const QString &ActionStr);

    bool isMatch(const QString &fspec, const QStringList &Col_data);

    QString &expandCmdline(const QString &cmdline, const QString &fspec, QString &result);

    Ui::ActionSettings *ui;

    QStringList m_ft_items;

    FileActionList_T m_Actions;

    bool m_TableChanged;

    int m_lastActionSel;

};

#endif // ACTIONSETTINGS_H
