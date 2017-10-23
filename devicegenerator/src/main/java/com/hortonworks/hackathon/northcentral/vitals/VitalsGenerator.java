package com.hortonworks.hackathon.northcentral.vitals;

import com.hortonworks.hackathon.northcentral.vitals.device.Device;
import org.apache.log4j.Logger;
import org.quartz.*;
import org.quartz.impl.StdSchedulerFactory;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by rcicak on 10/16/17.
 */
public class VitalsGenerator {

    static Logger log = Logger.getLogger(VitalsGenerator.class.getName());

    private Connection con;
    private List<Device> deviceList;

    public VitalsGenerator(Connection con) throws SchedulerException {

        this.con = con;
        this.deviceList = new ArrayList<Device>();

        populateVitals();

        Scheduler scheduler = new StdSchedulerFactory().getScheduler();

        scheduler.start();
        setupQuartzJob(scheduler);

    }

    public void setupQuartzJob(Scheduler scheduler) throws SchedulerException {

        for(Device device:deviceList) {

            JobKey deviceKey = new JobKey(device.getDeviceGUID(), "group1");
            JobDetail jobA = JobBuilder.newJob(Device.class)
                    .withIdentity(deviceKey)
                    .usingJobData("deviceGUID",device.getDeviceGUID())
                    .usingJobData("problemPercentage", device.getProblemPercentage())
                    .usingJobData("locationID", device.getLocationID())
                    .build();

            Trigger trigger1 = TriggerBuilder
                    .newTrigger()
                    .withIdentity(device.getDeviceGUID() + "trigger", "group1")
                    .withSchedule(
                            CronScheduleBuilder.cronSchedule("0/5 * * * * ?"))
                    .build();

            scheduler.scheduleJob(jobA, trigger1);

        }

    }

    public void populateVitals() {

        //populate List of devices
        try {
            Statement stmt = con.createStatement();

            ResultSet rs = stmt.executeQuery("select * from device");
            while (rs.next()) {

                String guid = rs.getString("DeviceGUID");
                int deviceId = rs.getInt("DeviceID");
                int deviceTypeId = rs.getInt("DeviceTypeID");
                int locationId = rs.getInt("LocationID");
                float deviceProblem = rs.getFloat("ProblemPercentage");

                String dateService = rs.getString("DateOfInitialService");

                Device device = new Device();
                device.setDateOfInitialService(dateService);
                device.setDeviceGUID(guid);
                device.setDeviceID(deviceId);
                device.setDeviceTypeID(deviceTypeId);
                device.setLocationID(locationId);
                device.setProblemPercentage(deviceProblem);

                deviceList.add(device);

            }
        } catch (SQLException e) {
            log.error("Error populating devices", e);
        }

    }

}
