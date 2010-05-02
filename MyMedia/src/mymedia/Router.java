/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;

import java.io.IOException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.mortbay.jetty.Request;
import org.mortbay.jetty.handler.AbstractHandler;

/**
 *
 * @author btaylor
 */
public class Router extends AbstractHandler {
    private class Route {
        String prefix;
        Responder responder;

        Route(String prefix, Responder responder) {
            this.prefix = prefix;
            this.responder = responder;
        }

        String getPrefix() {
            return prefix;
        }

        Responder getResponder() {
            return responder;
        }
    }

    ArrayList<Route> routes = new ArrayList<Route>();

    public void addRoute(String prefix, PyResponderIfc responder) {
        routes.add(new Route(prefix, new Responder(responder)));
    }

    public void handle(String target, HttpServletRequest req,
            HttpServletResponse resp, int dispatch) throws IOException, ServletException {
        
        System.out.println("Handling request for " + target);
        
        for(Route r : routes) {
            if(target.startsWith(r.getPrefix())) {
                System.out.println("matched route with prefix " + r.getPrefix());
                r.getResponder().handle(target, req, resp, dispatch);
                ((Request)req).setHandled(true);
                return;
            }
        }

        resp.setContentType("text/html");
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write("No route found for " + target);
        ((Request)req).setHandled(true);
    }


}
