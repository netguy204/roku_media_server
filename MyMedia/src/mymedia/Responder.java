/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.mortbay.jetty.handler.AbstractHandler;

/**
 *
 * @author btaylor
 */
public class Responder extends AbstractHandler {

    private PyResponderIfc pyresponder;
    
    public Responder(PyResponderIfc pyresponder) {
        this.pyresponder = pyresponder;
    }


    public void handle(String target, HttpServletRequest req,
            HttpServletResponse resp, int dispatch) throws IOException, ServletException {
        resp.setContentType("text/html");
        resp.setStatus(HttpServletResponse.SC_OK);
        pyresponder.GET(new RequestArguments(req, target), resp);
    }
}
