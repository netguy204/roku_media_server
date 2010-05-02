/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;

import java.io.IOException;
import javax.servlet.http.HttpServletResponse;

/**
 *
 * @author btaylor
 */
public abstract class PyResponderIfc {
    public abstract void GET(RequestArguments args, HttpServletResponse response) throws IOException;
    public void POST(RequestArguments args, HttpServletResponse response) throws IOException
    {
        throw new IOException("Not implemented");
    }
}
