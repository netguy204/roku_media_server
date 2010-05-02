/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;
import java.io.IOException;
import java.io.InputStream;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.mortbay.jetty.Handler;
import org.mortbay.jetty.Request;
import org.mortbay.jetty.Server;
import org.mortbay.jetty.handler.AbstractHandler;
import org.python.core.PyException;
import org.python.core.PyObject;
import org.python.core.PySystemState;
import org.python.util.PythonInterpreter;

/**
 *
 * @author btaylor
 */
public class Main {

    private Main() {

    }

    private void run() throws PyException, Exception {
        java.util.Properties p = new java.util.Properties();
        p.setProperty("python.path", "Lib/:pysrc/");
        PySystemState.initialize(null, p);
        
        PythonInterpreter interp = new PythonInterpreter();
        //interp.exec("import pysrc.rss_server");
        //InputStream stream = this.getClass().getResourceAsStream("/pysrc/rss_server.py");
        interp.exec("import rss_server");

        Router router = new Router();
        interp.set("router", router);
        PyObject obj = interp.get("rss_server").invoke("build_router", interp.get("router"));
        
        Server server = new Server(8009);
        server.setHandler(router);
        server.start();
//        Router router = new Router();
//        System.out.println(interp.get("rss_server").invoke("build_routes", router));
    }

    private void testServer() throws Exception {
        Router router = new Router();
        router.addRoute("/blah", new PyResponderIfc() {
            public void GET(RequestArguments args, HttpServletResponse response) throws IOException {
                response.getWriter().println("Hello from blah");
            }
        });
        router.addRoute("/", new PyResponderIfc() {
            public void GET(RequestArguments args, HttpServletResponse response) throws IOException {
                response.getWriter().println("Default Route");
            }
        });

        Server server = new Server(8889);
        server.setHandler(router);
        server.start();
    }

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws PyException, Exception{
        Main main = new Main();
        //main.run();

        try {
            main.run();
        } catch(PyException e) {
            System.err.println(e.traceback.toString());
            e.printStackTrace();
        }
    }

}
