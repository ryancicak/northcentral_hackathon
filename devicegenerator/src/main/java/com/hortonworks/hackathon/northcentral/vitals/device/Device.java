package com.hortonworks.hackathon.northcentral.vitals.device;

import org.apache.log4j.Logger;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

import java.io.*;
import java.sql.Timestamp;
import java.util.Random;

/**
 * Created by rcicak on 10/16/17.
 */
public class Device implements Job {

    static Logger log = Logger.getLogger(Device.class.getName());

    private String deviceGUID;
    private int deviceID;
    private int deviceTypeID;
    private int locationID;
    private float problemPercentage;
    private String dateOfInitialService;

    private static final int lowPulse = new Random().nextInt(70-40) + 40;
    private static final int highPulse = new Random().nextInt(100-70) + 70;
    private static final int gobackPulse = 200;
    private static int overPulse = 100;
    private static int pulseCount = 0;


    public String getDeviceGUID() {
        return deviceGUID;
    }

    public void setDeviceGUID(String deviceGUID) {
        this.deviceGUID = deviceGUID;
    }

    public int getDeviceID() {
        return deviceID;
    }

    public void setDeviceID(int deviceID) {
        this.deviceID = deviceID;
    }

    public int getDeviceTypeID() {
        return deviceTypeID;
    }

    public void setDeviceTypeID(int deviceTypeID) {
        this.deviceTypeID = deviceTypeID;
    }

    public int getLocationID() {
        return locationID;
    }

    public void setLocationID(int locationID) {
        this.locationID = locationID;
    }

    public float getProblemPercentage() {
        return problemPercentage;
    }

    public void setProblemPercentage(float problemPercentage) {
        this.problemPercentage = problemPercentage;
    }

    public String getDateOfInitialService() {
        return dateOfInitialService;
    }

    public void setDateOfInitialService(String dateOfInitialService) {
        this.dateOfInitialService = dateOfInitialService;
    }



    public void execute(JobExecutionContext context)
            throws JobExecutionException {

        BufferedWriter bw = null;
        FileWriter fw = null;

        try {

            String data = String.format("%s,%d,%d,%d,%d,%d,%.1f,%s%n",
                    getDeviceGUID(),
                    5,
                    generateRespiration(),
                    generatePulse(),
                    generateBloodPressureSystolic(),
                    generateBloodPressureDiastolic(),
                    generateTemperature(),
                    generateTimestamp());

            String directory = "/tmp/device-transmission/";
            File file = new File(directory + "device-data.txt");

            // if file doesnt exists, then create it
            if (!file.exists()) {
                new File(directory).mkdirs();
                file.createNewFile();
            }

            // true = append file
            fw = new FileWriter(file.getAbsoluteFile(), true);
            bw = new BufferedWriter(fw);

            bw.write(data);
            log.debug(data);

        } catch (IOException e) {

            log.error("Error writing log file", e);

        } finally {

            try {

                if (bw != null)
                    bw.close();

                if (fw != null)
                    fw.close();

            } catch (IOException ex) {

                ex.printStackTrace();

            }
        }
    }

    public int generatePulse() {

        Random r = new Random();

        float chance = new Random().nextFloat();

        if (problemPercentage > 0 && (chance <= problemPercentage || pulseCount > 0)) {

            if(pulseCount == 0)
                pulseCount = 20;

            pulseCount -= 1;

            return gobackPulse - r.nextInt(overPulse) + 1;
        }

        return r.nextInt(highPulse-lowPulse) + lowPulse;
    }

    // Generate between 12 and 16 - no rule in SAM
    public int generateRespiration() {

        Random r = new Random();
        int Low = 12;
        int High = 16;

        return r.nextInt(High-Low) + Low;

    }

    // Generate between 120 and 100 - no rule in SAM
    public int generateBloodPressureSystolic() {

        Random r = new Random();
        int Low = 100;
        int High = 120;

        return r.nextInt(High-Low) + Low;
    }

    // Generate between 60 and 80 - no rule in SAM
    public int generateBloodPressureDiastolic() {

        Random r = new Random();
        int Low = 60;
        int High = 80;

        return r.nextInt(High-Low) + Low;
    }

    //Generate between 92 - 98.6
    public double generateTemperature() {

        Random r = new Random();
        double Low = 92;
        double High = 98.6;

        return r.nextDouble() * (High - Low) + Low;

    }

    public String generateTimestamp() {

        Timestamp timestamp = new Timestamp(System.currentTimeMillis());

        return timestamp.toString();
    }
}
