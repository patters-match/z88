/*********************************************************************************************

 EazyLink2 - Fast Client/Server Z88 File Management
 (C) Gunther Strube (gstrube@gmail.com) 2011
  & Oscar Ernohazy 2012

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

#ifndef Z88FILESPEC_H
#define Z88FILESPEC_H

#include <QString>

/**
  * The Z88 File attribute Container class.
  * Stores information about files on the Z88
  */
class Z88FileSpec
{
public:
    Z88FileSpec(const QString &fname, const QString &fsize = "", const QString &cdate = "", const QString &mdate = "");

    const QString &getFilename() const;
    const QString &getFileSize() const;
    const QString &getFileCreateDate() const;
    const QString &getFileModDate() const;

protected:
    /**
      * The Filename
      */
    QString m_filename;

    /**
      * The Size of the File.
      */
    QString m_Size;

    /**
      * The Creation date of the file.
      */
    QString m_createDate;

    /**
      * The Modified date of the file.
      */
    QString m_modDate;
};

#endif // Z88FILESPEC_H
