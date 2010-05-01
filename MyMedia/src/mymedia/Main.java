/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;
import java.io.InputStream;
import org.python.util.PythonInterpreter;

/**
 *
 * @author btaylor
 */
public class Main {

    private Main() {

    }

    private void run() {
        PythonInterpreter interp = new PythonInterpreter();
        //InputStream stream = this.getClass().getResourceAsStream("/python/rss_server.py");
        //interp.execfile(stream);
        interp.exec("import rss_server");
    }
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        System.getProperties().setProperty("python.path", "lib/resources/Lib/:lib/resources/python");
        Main main = new Main();
        main.run();
    }

}
