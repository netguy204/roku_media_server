/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;

import java.util.Map;
import javax.servlet.http.HttpServletRequest;
import org.python.core.PyString;

/**
 *
 * @author btaylor
 */
public class RequestArguments {
    private HttpServletRequest request;
    private String target;

    public RequestArguments(HttpServletRequest request, String target) {
        this.request = request;
        this.target = target;
    }

    public String[] getArg(String name, String other) {
        Map params = request.getParameterMap();

        if(params.containsKey(name)) {
            return ((String[])params.get(name));
        } else {
            if(other == null) {
                return null;
            }
            return new String[]{other};
        }
    }

    public String getTarget() {
        return target;
    }
    
    public String getHeader(String name) {
        return request.getHeader(name);
    }
}
