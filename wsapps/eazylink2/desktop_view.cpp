/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) & Oscar Ernohazy 2012

 EazyLink2 is free software; you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software Foundation;
 either version 2, or (at your option) any later version.
 EazyLink2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with EazyLink2;
 see the file COPYING. If not, write to the
 Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

**********************************************************************************************/

#include<QDebug>
#include<QEvent>
#include <QFileSystemWatcher>
#include <QInputDialog>

#include "mainwindow.h"
#include "desktop_view.h"
#include "z88_devview.h"

/**
  * DeskTop Selection Constructor
  * @param fspec is the Fully qualified file path and name.
  * @param type is the type of entry. ie Dir or File.
  */
DeskTop_Selection::DeskTop_Selection(const QString &fspec, const QString &fname, entryType type) :
  m_fspec(fspec),
  m_fname(fname),
  m_type(type)
{
}

/**
  * Destop View Contstructor.
  * @parm parent is the Owner Qwidget
  */
Desktop_View::Desktop_View(CommThread &cthread, Prefrences_dlg *pref_dlg, MainWindow *parent) :
    QTreeView(parent),
    m_cthread(cthread),
    m_recurse(false),
    m_mainWindow(parent),
    m_pref_dlg(pref_dlg),
    m_qmenu(new QMenu(parent)),
    m_actionChgRoot(NULL)
{

    m_DeskFileSystem = new QFileSystemModel();

    setModel(m_DeskFileSystem);

    /**
      * Set the Initial View drive and Path
      */
    QString rootPath;
    QString initDir;

    m_pref_dlg->getInitDeskView(rootPath, initDir);

    setInitViewPath(rootPath, initDir);

    m_DeskFileSystem->setResolveSymlinks(true);

    connect(this, SIGNAL(clicked(const QModelIndex &)), this, SLOT(ItemSelectionChanged(const QModelIndex &)));

    connect(m_DeskFileSystem, SIGNAL(directoryLoaded(QString)), this, SLOT(DirLoaded(QString)));

    connect(m_qmenu,SIGNAL(triggered(QAction *)), this, SLOT(ActionsMenuSel(QAction *)));

    connect(this, SIGNAL(doubleClicked(QModelIndex)), this, SLOT(ItemDoubleClicked(QModelIndex)));

    installEventFilter(this);

    m_actionMkdir = m_qmenu->addAction("MakeDir");

    /**
      * Add the Select Drive Menu If more than One Root Path Is available (Windows).
      */
    if(QDir::drives().count() > 1){
        m_actionChgRoot = m_qmenu->addAction("Select Drive");
    }
    else{
        /**
          * If Only 1 Drive is root, add the Switch to menu if the current Displayed
          * Path is not already the Root.
          */
        QString rootPth = QDir::drives().first().path();
        if(m_DeskFileSystem->rootPath() != rootPth){
            m_actionChgRoot = m_qmenu->addAction("Switch to " + rootPth);
        }
    }
    m_actionSetInitDir = m_qmenu->addAction("Startup Dir");
    m_actionRename = m_qmenu->addAction("Rename");
    m_actionDelete = m_qmenu->addAction("Delete");

}

/**
  * Get a List of the selected file(s)
  * @return the list of filenames.
  */
QList<DeskTop_Selection> *Desktop_View::getSelection(bool recurse, bool cont)
{
    if(!recurse && m_recurse){
        return NULL;
    }

    /**
      * If Continuing a readlist, then use the initially selected list.
      * Otherwise get the current selection
      */
    if(!cont){
        m_ModelSelections = selectedIndexes();
    }

    const QModelIndexList &Selections(m_ModelSelections);

    m_Selections.clear();

    if(!Selections.isEmpty()){

        m_recurse = recurse;

        for(int count=0; count < Selections.count(); count++){
            const QModelIndex &idx(Selections[count]);

            /* only want column 0 */
            if(idx.column()) continue;

            DeskTop_Selection::entryType type = (m_DeskFileSystem->isDir(idx)) ?
                        DeskTop_Selection::type_Dir : DeskTop_Selection::type_File;

            if(recurse && type == DeskTop_Selection::type_Dir){
                if(!getSubdirFiles(idx)){
                    return NULL; // More to grab
                }
            }
            else{
                m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx), m_DeskFileSystem->fileName(idx), type));
            }
        }
    }
    else{
        m_Selections.append(DeskTop_Selection(m_DeskFileSystem->rootPath(), m_DeskFileSystem->rootPath(), DeskTop_Selection::type_Dir));
    }

    m_recurse = false;
    return &m_Selections;
}

/**
  * Build a directory tree below the Currently selected Directory.
  * @param z88Selections is the list of Source files and directories to be created.
  * @return true on success
  */
bool Desktop_View::mkDirectoryTree(const QList<Z88_Selection> &z88Selections)
{
    bool rc = false;

    if(!z88Selections.isEmpty()){
        /**
          * The root of the Desktop destination tree
          */
        QModelIndex desk_root;

        const QModelIndexList &deskSelections(selectedIndexes());

        if(deskSelections.isEmpty()){
            desk_root = m_DeskFileSystem->index(m_DeskFileSystem->rootPath(),0);
        }
        else{
            desk_root = deskSelections[0];
        }

        QListIterator<Z88_Selection> i(z88Selections);

        while(i.hasNext()){
            if(i.peekNext().getType() == Z88_DevView::type_Dir){
                rc = mkSubdir(i, desk_root);
                continue;
            }
            i.next();
        }
    }
    return rc;
}

/**
  * Make A Subdirectory on the host filesystem.
  * @param i is an interrator into the List of subdirectory names.
  * @param dst_root is the Base directory to in which to create directories.
  * @return false.
  */
bool Desktop_View::mkSubdir(QListIterator<Z88_Selection> &i, QModelIndex dst_root)
{
    QString curdir;
    bool rc = false;

    const Z88_Selection &z88sel(i.next());
    QString curpath(z88sel.getFspec());

    /**
     * Sanity Check
     */
    if(z88sel.getType() == Z88_DevView::type_Dir){

        QStringList pth;

        pth = curpath.split(QChar('/'),QString::SkipEmptyParts);

        if(pth.isEmpty()){
            return false;
        }

        curdir = pth[pth.count()-1];

        /**
          * Add a subdirectory to the Desktop Filesystem
          */
        dst_root = m_DeskFileSystem->mkdir(dst_root, curdir);

        while(i.hasNext()){
            if(i.peekNext().getType() == Z88_DevView::type_Dir){
                if(i.peekNext().getFspec().contains(curpath)){
                    mkSubdir(i, dst_root);
                    continue;
                }
                break;
            }
            i.next();
        }
    }
    return rc;
}

/**
  * Build the Subdirectory names to the list of selections,
  * @param desk_selections the list of directories to process.
  */
void Desktop_View::prependSubdirNames(QList<DeskTop_Selection> &desk_selections)
{
    QMutableListIterator<DeskTop_Selection> i(desk_selections);

    while(i.hasNext()){
        if(i.peekNext().getType() == DeskTop_Selection::type_Dir){
            prependSubdirNames(i);
            continue;
        }
        i.next();
    }
}

/**
  * Recurse the subdirctory and build the relative path names.
  * @param i is the strating iterator od the list to recurse.
  */
void Desktop_View::prependSubdirNames(QMutableListIterator<DeskTop_Selection> &i)
{
    const DeskTop_Selection &desksel(i.next());
    QString curdir = desksel.getFname() + '/';

    QString curpath(desksel.getFspec());


    while(i.hasNext()){
       // qDebug() << "cur path=" << curpath << " curdir = " << curdir << "peek fspec=" << i.peekNext().getFspec() << "type = "<< i.peekNext().getType() ;

        if(i.peekNext().getType() == DeskTop_Selection::type_Dir){
            QString subdir(i.peekNext().getFspec() + '/');
            if(subdir.contains(curpath+'/')){
                i.peekNext().setSubdir(curdir);
                prependSubdirNames(i);
                continue;
            }

            break;
        }
        if(i.peekNext().getFspec().contains(curpath)){
            i.peekNext().setSubdir(curdir);
        }
        else{
            break;
        }
        i.next();
    }
}

/**
  * Recurse and read Subdirectories already loaded from the disk.
  * @param idx is the selected directory to recurse.
  * @return false if the directory is still being read, true on success.
  */
bool Desktop_View::getSubdirFiles(const QModelIndex &idx)
{
    if(m_DeskFileSystem->isDir(idx)){
        if(m_DeskFileSystem->canFetchMore(idx)){
            m_DeskFileSystem->fetchMore(idx);
            return false;
        }
        m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx),
                                              m_DeskFileSystem->fileName(idx),
                                              DeskTop_Selection::type_Dir));
    }
    for(int x=0; x < m_DeskFileSystem->rowCount(idx); x++){
        if(m_DeskFileSystem->isDir(idx.child(x,0))){
            if(!getSubdirFiles(idx.child(x,0))){
                return false;
            }
        }
        else{
            m_Selections.append(DeskTop_Selection(m_DeskFileSystem->filePath(idx.child(x,0)),
                                                  m_DeskFileSystem->fileName(idx.child(x,0)),
                                                  DeskTop_Selection::type_File));
        }
    }
    return true;
}

/**
  * Delete a subdirectory and it contents, user interractive handler.
  * @param i is the iterator to the list of files to be deleted.
  * @param ret is the user return code.
  */
bool Desktop_View::delSubdirFiles(QListIterator<DeskTop_Selection> &i, int &ret)
{
    return false;
    while(i.hasNext()){

        QString srcfspec(i.next().getFspec());
        QString msg = "Delete:" + srcfspec;

        if(ret != QMessageBox::YesToAll){
            QMessageBox msgBox;
            msgBox.setWindowTitle("Eazylink2");
            msgBox.setIcon(QMessageBox::Question);
            msgBox.setText(msg);
            msgBox.setInformativeText("Delete Dir and all its files?");
            msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::YesToAll | QMessageBox::No | QMessageBox::NoToAll | QMessageBox::Cancel);
            msgBox.setDefaultButton(QMessageBox::No);
            ret = msgBox.exec();
        }

        if(i.hasNext()){
            if(i.peekNext().getType() == DeskTop_Selection::type_Dir){
                delSubdirFiles(i, ret);
                if(ret == QMessageBox::Cancel){
                    return false;
                }
                continue;
            }
            delFile(i, ret);
            continue;
        }

        i.next();
    }
    return false;
}

/**
  * The User Delete file list, Command Handler.
  * @param i is an iterator to the list of files and dirs.
  * @param ret is the User selected menu return code.
  * @return true if deleted, false in cancel or done.
  */
bool Desktop_View::delFile(QListIterator<DeskTop_Selection> &i, int &ret)
{
    QString srcfspec(i.peekNext().getFspec());
    QString msg = "Delete:" + srcfspec;

    if(ret != QMessageBox::YesToAll){
        QMessageBox msgBox;
        msgBox.setWindowTitle("Eazylink2");
        msgBox.setIcon(QMessageBox::Question);
        msgBox.setText(msg);
        msgBox.setInformativeText("Permanently erase desktop file?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::YesToAll | QMessageBox::No | QMessageBox::Cancel);
        msgBox.setDefaultButton(QMessageBox::No);
        ret = msgBox.exec();
    }

    switch(ret){
        case QMessageBox::YesToAll:
        case QMessageBox::Yes:
            return true;
        case QMessageBox::No:
            break;
        case QMessageBox::Cancel:
            return false;
    }
    return false;
}

/**
  * Items selected have changed, call-back handler.
  * @param idx is the index of the selected item
  */
void Desktop_View::ItemSelectionChanged(const QModelIndex &idx)
{
    const QModelIndexList &Selections(selectedIndexes());
    if(Selections.isEmpty()){
        m_mainWindow->setDesktopDirLabel(m_DeskFileSystem->rootPath());
    }
    else{
        m_mainWindow->setDesktopDirLabel(m_DeskFileSystem->filePath(idx));
    }
    emit ItemSelectionChanged(Selections.count() / 3);
}

/**
  * The Directory Load Thread, task handler. Continues to
  * Recurse a directory tree.
  * @param path is the current path to recurse.
  */
void Desktop_View::DirLoaded(const QString &path)
{
    if(m_recurse){

        QModelIndex midx = m_DeskFileSystem->index(path,0);

        for(int x=0; x < m_DeskFileSystem->rowCount(midx); x++){
            if(m_DeskFileSystem->isDir(midx.child(x,0)) &&
                    m_DeskFileSystem->canFetchMore(midx.child(x,0))){
                m_DeskFileSystem->fetchMore(midx.child(x,0));
                return;
            }
        }
        m_cthread.dirLoadComplete();
    }
}

/**
  * The Context menu Handler (right Click).
  * @param act is the action that was performed.
  */
void Desktop_View::ActionsMenuSel(QAction *act)
{
    QList<DeskTop_Selection> *selections;

    /**
      * Make directory
      */
    if(act == m_actionMkdir){
        mkDir();
        return;
    }

    /**
      * Rename Item(s) selected.
      */
    if(act == m_actionRename){
        renameSelections();
        return;
    }

    /**
      * Delete item(s) selected.
      */
    if(act == m_actionDelete){
        selections = getSelection(true);
        if(selections){
            deleteSelections();
        }
        return;
    }

    /**
      * Set the Initial Dir to Display
      */
    if(act == m_actionSetInitDir){
        selectInitDir();
        return;
    }

    /**
      * Change root or drive
      */
    if(act == m_actionChgRoot){
#ifdef Q_OS_WIN32
        selectDrive();
#else
        setInitViewPath("/", "/");
#endif
        return;
    }
}

void Desktop_View::ItemDoubleClicked(const QModelIndex &index)
{
    if(!m_DeskFileSystem->isDir(index)){
        emit Trigger_Transfer();
    }
}

/**
  * Directory read aborted handler.
  */
void Desktop_View::DirLoadAborted()
{
    m_recurse = false;
}

/**
  * Rename the Selected Items
  */
bool Desktop_View::renameSelections()
{
    QList<DeskTop_Selection> *selections;
    selections = getSelection(false);

    if(!selections){
        return false;
    }

    QListIterator<DeskTop_Selection> i(*selections);

    while(i.hasNext()){
        bool ok;
        const QString &ftype((i.peekNext().getType() == DeskTop_Selection::type_Dir) ?
                    "Rename Dir" : "Rename File");

        const QString &srcname(i.peekNext().getFname());
        QString srcfspec(i.peekNext().getFspec());
        QString newname = QInputDialog::getText(this,
                                                ftype,
                                                srcfspec,
                                                QLineEdit::Normal,
                                                srcname,
                                                &ok);

        if(ok && !newname.isEmpty() && newname != srcname){
            int idx = srcfspec.lastIndexOf(srcname);
            if(idx > -1){
                QFile hostFile(srcfspec);
                srcfspec.remove(idx, srcname.size());
                newname.prepend(srcfspec);
                hostFile.rename(newname);
            }
        }
        i.next();
    }

    return true;
}

/**
  * Remove a Directory and all of its contents
  * @param dirName the name of the directory to remove
  * @return true on success
  */
static bool removeDir(const QString &dirName)
{
    bool result = true;
    QDir dir(dirName);

    if (dir.exists(dirName)) {
        Q_FOREACH(QFileInfo info, dir.entryInfoList(QDir::NoDotAndDotDot |
                                                    QDir::System  |
                                                    QDir::Hidden  |
                                                    QDir::AllDirs |
                                                    QDir::Files,
                                                    QDir::DirsFirst)) {
            if (info.isDir()) {
                result = removeDir(info.absoluteFilePath());
            }
            else {
                result = QFile::remove(info.absoluteFilePath());
            }

            if (!result) {
                return result;
            }
        }
        result = dir.rmdir(dirName);
    }

    return result;
}

/**
  * Delete the Subdirectory and all its contents
  * @param idx is the selected subdirectory item
  * @param ret is the result code from user prompts
  */
void Desktop_View::deleteSubdirFiles(const QModelIndex &idx, int &ret)
{
    QString srcfspec(m_DeskFileSystem->filePath(idx));
    QString msg = "Delete:" + srcfspec;

    if(ret != QMessageBox::YesToAll){
        QMessageBox msgBox;
        msgBox.setWindowTitle("Eazylink2");
        msgBox.setIcon(QMessageBox::Question);
        msgBox.setText(msg);
        msgBox.setInformativeText("Delete Directory and its contents?");

        msgBox.setStandardButtons(QMessageBox::Yes |
                                  QMessageBox::YesToAll |
                                  QMessageBox::No |
                                  QMessageBox::NoToAll |
                                  QMessageBox::Cancel);

        msgBox.setDefaultButton(QMessageBox::NoToAll);
        ret = msgBox.exec();
    }

    switch(ret){
        case QMessageBox::YesToAll:
        case QMessageBox::Yes:
        {
            if(!removeDir(srcfspec)){
                msg = "Failed to remove " + srcfspec;
                QMessageBox::critical(this,
                                      tr("Eazylink2"),
                                      msg,
                                      QMessageBox::Ok);
            }
            return;
        }
        case QMessageBox::No:
            break;
        case QMessageBox::NoToAll:
            ret = 0;
        case QMessageBox::Cancel:
            return;
    }

    /**
      * Recurse the children
      */
    for(int x = 0; x < m_DeskFileSystem->rowCount(idx); x++){
        if(m_DeskFileSystem->isDir(idx.child(x,0))){
            deleteSubdirFiles(idx.child(x,0), ret);
        }
        else{
            deleteFile(idx.child(x,0), ret);
        }

        if(ret == QMessageBox::NoToAll || ret == QMessageBox::Cancel){
            return;
        }
    }
}

void Desktop_View::deleteFile(const QModelIndex &idx, int &ret)
{
    QString srcfspec(m_DeskFileSystem->filePath(idx));
    QString msg = "Delete:" + srcfspec;

    if(ret != QMessageBox::YesToAll){
        QMessageBox msgBox;
        msgBox.setWindowTitle("Eazylink2");
        msgBox.setIcon(QMessageBox::Question);
        msgBox.setText(msg);
        msgBox.setInformativeText("Delete file in this directory?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::YesToAll | QMessageBox::No | QMessageBox::NoToAll | QMessageBox::Cancel);
        msgBox.setDefaultButton(QMessageBox::No);
        ret = msgBox.exec();
    }

    switch(ret){
        case QMessageBox::YesToAll:
        case QMessageBox::Yes:
        {
            m_DeskFileSystem->remove(idx);
            return;
        }
        case QMessageBox::No:
            break;
        case QMessageBox::NoToAll:
            ret = 0;
        case QMessageBox::Cancel:
            return;
    }
}

void Desktop_View::setInitViewPath(const QString &rootPath, const QString &directory)
{
    m_DeskFileSystem->setRootPath(rootPath);

    setRootIndex(m_DeskFileSystem->index(rootPath));

    setCurrentIndex(m_DeskFileSystem->index(directory));
    setExpanded(currentIndex(),true);

    m_mainWindow->setDesktopDirLabel(directory);
}

/**
  * Delete all the currently selected Items from Disk.
  */
bool Desktop_View::deleteSelections()
{
    const QModelIndexList &Selections(selectedIndexes());

    if(!Selections.isEmpty()){

        QListIterator<QModelIndex> i(Selections);
        int ret = 0;

        while(i.hasNext()){
            const QModelIndex &idx(i.peekNext());

            /* only want column 0 */
            if(idx.column()) {
                i.next();
                continue;
            }

            if(m_DeskFileSystem->isDir(idx)){
                deleteSubdirFiles(idx, ret);
                if(ret == QMessageBox::Cancel){
                    return false;
                }
            }
            else{
                deleteFile(idx, ret);
                if(ret == QMessageBox::Cancel){
                    return false;
                }
            }
            i.next();
        }
    }

    return true;
}

void Desktop_View::selectInitDir()
{
    bool ok;
    const QModelIndexList &Selections(selectedIndexes());

    QStringList stlist;

    if(!Selections.isEmpty()){
        const QModelIndex &idx(Selections.first());
        stlist.append(m_DeskFileSystem->filePath(idx));
    }

    Q_FOREACH(QFileInfo root, QDir::drives()) {
        stlist.append(root.path());
    }

    QString item = QInputDialog::getItem(this, "Eazylink2",
                                          tr("Select Startup Dir:"), stlist, 0, false, &ok);
    if (ok && !item.isEmpty()){
        m_pref_dlg->setInitDeskView(m_DeskFileSystem->rootPath(), item);
    }
}

/**
  * Select a Drive to Display in the Desktop View.
  */
void Desktop_View::selectDrive()
{
    QStringList stlist;
    bool ok;

    /* Create a String list of theavailable drives */
    Q_FOREACH(QFileInfo root, QDir::drives()) {
        stlist.append(root.path());
    }

    QString rootPath = QInputDialog::getItem(this, "Eazylink2",
                                          tr("Select Drive:"), stlist, 0, false, &ok);
    if (ok && !rootPath.isEmpty()){
        setInitViewPath(rootPath, rootPath);
    }
}

/**
  * Make Directory on the Desktop File system.
  * @return true on success.
  */
bool Desktop_View::mkDir()
{
    const QModelIndexList &Selections(selectedIndexes());

    if(Selections.count() <= 3){
        bool ok;
        QString location;

        QModelIndex idx;

        if(Selections.isEmpty()){
            idx = rootIndex();
            if(!idx.isValid()){
                return false;
            }
        }
        else{
            idx = Selections.first();
        }

        if(m_DeskFileSystem->isDir(idx)){
            location = m_DeskFileSystem->filePath(idx);
            location += QDir::separator();
        }
        else{
            location = m_DeskFileSystem->filePath(idx).remove(m_DeskFileSystem->fileName(idx));
            /**
              * If in the root
              */
            if(location.isEmpty()){
                location = m_DeskFileSystem->rootPath();
            }
        }

        QString newdir = QInputDialog::getText(this,
                                               "Make Directory",
                                               QString("In " + location),
                                               QLineEdit::Normal,
                                               "",
                                               &ok);

        if(ok && !newdir.isEmpty()){
            location += newdir;
            if(!m_DeskFileSystem->mkdir(idx, location).isValid()){
                QString msg = "Failed to create Dir:" + location;
                QMessageBox::critical(this,
                                      tr("Eazylink2"),
                                      msg,
                                      QMessageBox::Ok);
            }
        }
        return true;
    }
    return false;
}

/**
  * GUI Event handler,
  * @param obj is the object that had the change.
  * @param ev is the event that occured.
  * @return false.
  */
bool Desktop_View::eventFilter(QObject *, QEvent *ev)
{
    /**
      * Handle Right Click Context Menu
      */
    if(ev->type() == QEvent::ContextMenu){
        const QModelIndexList &Selections(selectedIndexes());
        int sel_count = Selections.count() / 3; /* 3 items per entry */

        if(sel_count){
            m_actionMkdir->setEnabled(sel_count < 2);
            m_actionRename->setEnabled(true);
            m_actionDelete->setEnabled(true);
            if(sel_count == 1){
                m_actionSetInitDir->setEnabled(m_DeskFileSystem->isDir(Selections.first()));
            }
            else{
                m_actionSetInitDir->setEnabled(false);
            }
        }
        else{
            m_actionMkdir->setEnabled(true);
            m_actionRename->setEnabled(false);
            m_actionDelete->setEnabled(false);
            m_actionSetInitDir->setEnabled(true);
        }

        m_qmenu->exec(QCursor::pos());


    }

    /**
      * Handle Enable / Disable transfer menu
      */
    if(ev->type() == QEvent::KeyRelease || ev->type() == QEvent::Leave){
        const QModelIndexList &Selections(selectedIndexes());
        emit ItemSelectionChanged(Selections.count() / 3);
        if(Selections.isEmpty()){
            m_mainWindow->setDesktopDirLabel(m_DeskFileSystem->rootPath());
        }
    }
    return false;
}
