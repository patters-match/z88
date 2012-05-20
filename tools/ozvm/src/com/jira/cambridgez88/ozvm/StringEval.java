/*
 * StringEval.java
 * This file is part of OZvm.
 * 
 * OZvm is free software; you can redistribute it and/or modify it under the terms of the 
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with OZvm;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * @author <A HREF="mailto:gstrube@gmail.com">Gunther Strube</A>
 *
 */
package com.jira.cambridgez88.ozvm;

/**
 * String evaluation utility.
 */
public class StringEval {

    private static boolean isBinaryDigits(final String strSequence) {
        for (int d = 0, n = strSequence.length(); d < n; d++) {
            if (strSequence.charAt(d) != '0' & strSequence.charAt(d) != '1') {
                if (d != n - 1) // a digit was found in the 'middle' that wasn't a '0' or '1'
                {
                    return false;
                } else // the last binary digit may be a 'b' specifier..
                if (strSequence.charAt(n - 1) != 'b') {
                    return false;
                }
            }
        }

        return true;
    }

    private static boolean isHexDigits(final String strSequence) {
        String strSeq = strSequence.toLowerCase();

        for (int d = 0, n = strSeq.length(); d < n; d++) {
            if (Character.isDigit(strSeq.charAt(d)) == false) {
                if ("abcdef".indexOf(strSeq.charAt(d)) < 0) {
                    // a non-hex digit was found 
                    if (d != n - 1) // a digit was found in the 'middle' that wasn't 
                    // in the '0' - '9' range
                    {
                        return false;
                    } else // the last binary digit may be a 'h' specifier..
                    if (strSeq.charAt(n - 1) != 'h') {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    private static boolean isDecimalDigits(final String strSequence) {
        for (int d = 0, n = strSequence.length(); d < n; d++) {
            if (Character.isDigit(strSequence.charAt(d)) == false) {
                if (d != n - 1) // a digit was found in the 'middle' that wasn't 
                // in the '0' - '9' range
                {
                    return false;
                } else // the last binary digit may be a 'd' specifier..
                if (strSequence.charAt(n - 1) != 'd') {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Coerce string to 16bit integer.<br> The string is scanned to determine
     * the number format, but might be pre-determined with a trailing type
     * specifier; 'd' for decimal, 'h' for hexadecimal or 'b' for binary. When
     * not specifying a type, ambiguity may happen where it cannot be determined
     * whether a string is a decimal, hexadecimal or a binary. In those cases
     * hexadecimal is used as default.
     *
     * @param strNumber
     * @return converted integer, or -1 if there was a syntax error in the
     * number format or range
     */
    public static int toInteger(String strNumber) {
        boolean binSequence = isBinaryDigits(strNumber);
        boolean hexSequence = isHexDigits(strNumber);
        boolean decSequence = isDecimalDigits(strNumber);

        if ((binSequence == true & strNumber.endsWith("b") == true)
                | (binSequence == true & strNumber.length() > 4)) {
            // definitely a binary number:
            // more than 4 digits, recognised as only '0' and '1' digits or 
            // optionally specified with a trailing 'b'         
            if (strNumber.endsWith("b") == false) {
                return Integer.parseInt(strNumber, 2) & 0xFFFF;
            } else {
                return Integer.parseInt(strNumber.substring(0, strNumber.length() - 1), 2) & 0xFFFF;
            }
        }

        if (hexSequence == true & strNumber.endsWith("h") == true) {
            // definitely a hexadecimal number
            return Integer.parseInt(strNumber.substring(0, strNumber.length() - 1), 16) & 0xFFFF;
        }

        if (decSequence == true & strNumber.endsWith("d") == true) {
            // definitely a decimal number
            return Integer.parseInt(strNumber.substring(0, strNumber.length() - 1), 10) & 0xFFFF;
        }

        if (hexSequence == true & strNumber.length() <= 4) {
            // decimal number will be interpreted as a hexadecimal number (default)
            return Integer.parseInt(strNumber, 16) & 0xFFFF;
        }

        if (decSequence == true & strNumber.length() <= 5) {
            // a decimal number, likely in the 64K range
            return Integer.parseInt(strNumber, 10) & 0xFFFF;
        }

        return -1; // syntax error...
    }
}
