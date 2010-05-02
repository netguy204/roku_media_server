/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package mymedia;
import java.io.InputStream;
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

    private void run() throws PyException {
        java.util.Properties p = new java.util.Properties();
        p.setProperty("python.path", "Lib/:pysrc/");
        PySystemState.initialize(null, p);
        
        PythonInterpreter interp = new PythonInterpreter();
        //interp.exec("import pysrc.rss_server");
        //InputStream stream = this.getClass().getResourceAsStream("/pysrc/rss_server.py");
        interp.exec("from rss_server import *");
        interp.exec("from common import *");
        interp.exec("config = parse_config(config_file)");
        PyObject pyobj = interp.eval("getdoc('music', '.', key_to_path(config, 'music'), 'az', config, False).to_xml()");
        System.out.println("result => " + pyobj.toString());
    }
    
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws PyException{
        Main main = new Main();
        main.run();
    }

}
