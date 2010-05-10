/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;
import java.awt.Desktop;
import java.awt.Image;
import java.awt.MenuItem;
import java.awt.PopupMenu;
import java.awt.SystemTray;
import java.awt.Toolkit;
import java.awt.TrayIcon;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.URI;
import javax.servlet.http.HttpServletResponse;
import javax.swing.JOptionPane;
import org.ini4j.IniPreferences;
import org.mortbay.jetty.Server;
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

        p.setProperty("python.path", "Lib" + File.pathSeparator + "pysrc");
        PySystemState.initialize(null, p);
        
        PythonInterpreter interp = new PythonInterpreter();
        interp.exec("import rss_server");

        // ask python to build our url routes for us
        Router router = new Router();
        interp.set("router", router);
        PyObject obj = interp.get("rss_server").invoke("build_router", interp.get("router"));

        // figure out what port we're supposed to start on
        File config = new File("config.ini");
        String _port = "8001";
        if(config.exists()) {
            IniPreferences prefs = new IniPreferences(new FileInputStream(config));
            _port = prefs.node("config").get("server_port", "8001");
        }
        final String port = _port;

        // add ourselves to the system tray if that's supported
        if(SystemTray.isSupported()) {
            SystemTray tray = SystemTray.getSystemTray();
            Image img = Toolkit.getDefaultToolkit().getImage("lib/tray.png");

            PopupMenu menu = new PopupMenu();
            MenuItem quit = new MenuItem("Stop Server");
            quit.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    System.exit(0);
                }
            });
            menu.add(quit);

            MenuItem browser = new MenuItem("Open Browser");
            browser.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    try {
                        Desktop.getDesktop().browse(new URI("http://localhost:" + port));
                    } catch (Exception err) {
                        JOptionPane.showMessageDialog(null,
                                "Could't launch your browser.\n" +
                                "Open it manually and go to http://localhost:" + port);
                    }
                }
            });
            menu.add(browser);
            
            TrayIcon icon = new TrayIcon(img, "My media", menu);
            tray.add(icon);
        }

        // fire it off!
        Server server = new Server(Integer.parseInt(port));
        server.setHandler(router);
        server.start();
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
