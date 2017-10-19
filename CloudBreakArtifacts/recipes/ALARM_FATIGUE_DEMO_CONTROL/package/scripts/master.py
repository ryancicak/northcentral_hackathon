import sys, os, pwd, signal, time, shutil
from subprocess import *
from resource_management import *

class DemoControl(Script):
  def install(self, env):
    self.configure(env)
    import params
  
    if not os.path.exists(params.install_dir):  
        os.makedirs(params.install_dir)
    os.chdir(params.install_dir)
    if not os.path.exists(params.install_dir+'/Data-Loader'):
        Execute('wget -O simulator.zip '+params.download_url)
        Execute('unzip simulator.zip')
        os.chdir(params.install_dir+'/Data-Loader')
    os.chdir(params.install_dir)
    Execute(params.install_dir+'/CloudBreakArtifacts/recipes/alarmfatigue-demo-sam-install.sh')

  def start(self, env):
    self.configure(env)
    import params
    Execute('echo Start Simulation')
    Execute('nohup java -cp '+params.install_dir+'/Data-Loader/devicegenerator-1.0-SNAPSHOT.jar:/usr/hdp/current/hive-server2/jdbc/*:dependency-jars/* com.hortonworks.hackathon.northcentral.Main & 2>&1 & ')
    Execute('ps -ef|grep "Data-Loader/devicegenerator-1.0-SNAPSHOT.jar"| grep -v grep| awk \'{print $2}\' > /var/run/VitalSim.pid')
    
  def stop(self, env):
    self.configure(env)
    import params
    Execute('echo Stop Simulation')
    Execute ('kill -9 `ps -ef|grep "Data-Loader/devicegenerator-1.0-SNAPSHOT.jar"| grep -v grep| awk \'{print $2}\'` >/dev/null 2>&1') 
    Execute ('rm -f /var/run/VitalSim.pid')
    
  def status(self, env):
    import params
    env.set_params(params)
    check_process_status('/var/run/VitalSim.pid')
    
  def configure(self, env):
    import params
    env.set_params(params)

if __name__ == "__main__":
  DemoControl().execute()
