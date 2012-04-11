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

#include "z88filespec.h"

/**
  * The Z88 File Information Class Constructor.
  * @param fname is the File name.
  * @param fsize is the size of the file.
  * @param cdate is the file creation date.
  * @param mdate is the file modified date.
  */
Z88FileSpec::Z88FileSpec(const QString &fname, const QString &fsize, const QString &cdate, const QString &mdate)
    :m_filename(fname),
     m_Size(fsize),
     m_createDate(cdate),
     m_modDate(mdate)
{

}

/**
  * Get the File Name method.
  * @return the filename string.
  */
const QString &Z88FileSpec::getFilename() const
{
    return m_filename;
}

/**
  * get the FileSize method.
  * @return the size of the file in a string.
  */
const QString &Z88FileSpec::getFileSize() const
{
    return m_Size;
}

/**
  * Get the File Creation date and time.
  * @param the File Creation date and time string.
  */
const QString &Z88FileSpec::getFileCreateDate()const
{
    return m_createDate;
}

/**
  * Get the File Modification date and time.
  * @param the File Modification date and time string.
  */

const QString &Z88FileSpec::getFileModDate() const
{
    return m_modDate;
}
