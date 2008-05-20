package com.jhe.hexed;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

/**
 * Created by IntelliJ IDEA.
 * User: laullon
 * Date: 09-abr-2003
 * Time: 12:47:18
 */
public class JHexEditorASCII extends JComponent implements MouseListener,KeyListener
{
    private JHexEditor he;

    public JHexEditorASCII(JHexEditor he)
    {
        this.he=he;
        addMouseListener(this);
        addKeyListener(this);
        addFocusListener(he);
    }

    public Dimension getPreferredSize()
    {
        return getMinimumSize();
    }

    public Dimension getMinimumSize()
    {
        Dimension d=new Dimension();
        FontMetrics fn=getFontMetrics(he.font);
        int h=fn.getHeight();
        int nl=he.getLineas();
        d.setSize((fn.stringWidth(" ")+1)*(16)+(he.border*2)+1,h*nl+(he.border*2)+1);
        return d;
    }

    public void paint(Graphics g)
    {
        Dimension d=getMinimumSize();
        g.setColor(Color.white);
        g.fillRect(0,0,d.width,d.height);
        g.setColor(Color.black);

        g.setFont(he.font);

        //datos ascii
        int ini=he.getInicio()*16;
        int fin=ini+(he.getLineas()*16);
        if(fin>he.buff.length) fin=he.buff.length;

        int x=0;
        int y=0;
        for(int n=ini;n<fin;n++)
        {
            if(n==he.cursor)
            {
                g.setColor(Color.blue);
                if(hasFocus()) he.fondo(g,x,y,1); else he.cuadro(g,x,y,1);
                if(hasFocus()) g.setColor(Color.white); else g.setColor(Color.black);
            } else
            {
                g.setColor(Color.black);
            }

            String s=""+new Character((char)he.buff[n]);
            if((he.buff[n]<20)||(he.buff[n]>126)) s=""+(char)16;
            he.printString(g,s,(x++),y);
            if(x==16)
            {
                x=0;
                y++;
            }
        }

    }

    // calcular la posicion del raton
    public int calcularPosicionRaton(int x,int y)
    {
        FontMetrics fn=getFontMetrics(he.font);
        x=x/(fn.stringWidth(" ")+1);
        y=y/fn.getHeight();
        return x+((y+he.getInicio())*16);
    }

    // mouselistener
    public void mouseClicked(MouseEvent e)
    {
        he.cursor=calcularPosicionRaton(e.getX(),e.getY());
        this.requestFocus();
        he.repaint();
    }

    public void mousePressed(MouseEvent e)
    {
    }

    public void mouseReleased(MouseEvent e)
    {
    }

    public void mouseEntered(MouseEvent e)
    {
    }

    public void mouseExited(MouseEvent e)
    {
    }

    //KeyListener
    public void keyTyped(KeyEvent e)
    {
        he.buff[he.cursor]=(byte)e.getKeyChar();

        if(he.cursor!=(he.buff.length-1)) he.cursor++;
        he.repaint();
    }

    public void keyPressed(KeyEvent e)
    {
        he.keyPressed(e);
    }

    public void keyReleased(KeyEvent e)
    {
    }

    public boolean isFocusTraversable()
    {
        return true;
    }
}
