package com.hortonworks.hackathon.northcentral;

import com.hortonworks.hackathon.northcentral.sql.SyncSQL;
import com.hortonworks.hackathon.northcentral.vitals.VitalsGenerator;
import com.hortonworks.hackathon.northcentral.vitals.device.Device;
import org.apache.log4j.Logger;

import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Created by rcicak on 10/13/17.
 */
public class Main {

    static Logger log = Logger.getLogger(Main.class.getName());

    private static String driverName = "org.apache.hive.jdbc.HiveDriver";

    public static void main(String... args) throws Exception {

        try {
            Class.forName(driverName);
        } catch (ClassNotFoundException e) {
            log.error("error with driver", e);
        }

        Connection con = DriverManager.getConnection("jdbc:hive2://localhost:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2", "hive", "");

        new SyncSQL(con);

        // populate devices
        new VitalsGenerator(con);


    }


}
