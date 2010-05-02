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
public interface PyResponderIfc {
    public void GET(RequestArguments args, HttpServletResponse response) throws IOException;
}
