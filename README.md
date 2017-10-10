# Northcentral Hack-a-Thon

Reducing Alarm Fatigue - What is Alarm Fatigue?
Alarm fatigue or alert fatigue occurs when one is exposed to a large number of frequent alarms (alerts) and consequently becomes desensitized to them. Desensitization can lead to longer response times or to missing important alarms.  There were 138 preventable deaths between 2010 and 2015, caused from alarm fatigue. 
 (https://en.wikipedia.org/wiki/Alarm_fatigue)
 
How can Alarm Fatigue be reduced?
Instead of only sounding an alarm, being heard by the closest nurse or doctor, a notification should be sent to the proper doctor/nurse containing a severity level and acknowledgement.     
 
What will HDP/HDF do to reduce Alarm Fatigue?
It all starts on the edge devices, being various sensors in a hospital room (Blood pressure sensor, Heart Rate Sensor, Temperature Sensor, Humidity Sensor).  For this use-case, we will assume our target hospital contains sensors with active connections to raspberry pi device(s), one per room.  The raspberry pi device will gather logs from the sensors, therefore we will install MiNiFi and tail the logs.  MiNiFi will then bi-directionally communicate with a centralized NiFi instance located at the hospital (this is where things get fun). 
