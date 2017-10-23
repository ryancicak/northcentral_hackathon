package com.hortonworks.hackathon.northcentral.sql;

import com.hortonworks.hackathon.northcentral.vitals.device.Device;
import com.hortonworks.hackathon.northcentral.Main;
import org.apache.log4j.Logger;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.Statement;

/**
 * Created by rcicak on 10/13/17.
 * <p>
 * Code taken from https://coderanch.com/t/306966/databases/Execute-sql-file-java
 */
public class SyncSQL {

    static Logger log = Logger.getLogger(Device.class.getName());

    public SyncSQL(Connection con) {

        try {

            executeDMLDDL("/root/Data-Loader/AcidTableCreationDDL.txt", con);
            executeDMLDDL("/root/Data-Loader/StaticTableCreationDDL.txt", con);

        } catch (Exception ex) {
            log.error("Error executing DML/DDL", ex);
        }

    }

    public void executeDMLDDL(String filename, Connection con) throws Exception {

        Statement stmt = null;
        FileReader fr = null;

        try {

            stmt = con.createStatement();
            //ClassLoader classLoader = Main.class.getClassLoader();

            fr = new FileReader(new File(filename));
            // be sure to not have line starting with "--" or "/*" or any other non aplhabetical character

            String s = new String();
            StringBuffer sb = new StringBuffer();
            BufferedReader br = new BufferedReader(fr);

            while ((s = br.readLine()) != null) {
                sb.append(s);
            }
            br.close();

            // here is our splitter ! We use ";" as a delimiter for each request
            // then we are sure to have well formed statements
            String[] inst = sb.toString().split(";");


            for (int i = 0; i < inst.length; i++) {
                // we ensure that there is no spaces before or after the request string
                // in order to not execute empty statements
                if (!inst[i].trim().equals("") && !inst[i].startsWith("-")) {
                    log.info(inst[i]);
                    stmt.execute(inst[i]);
                }
            }

        } finally {
            if (stmt != null) {
                stmt.close();
            }
            if (fr != null) {
                fr.close();
            }
        }

    }
}
