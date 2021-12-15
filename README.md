# Log4J Tools

Some scripts to assist with Log4J remediation. These scripts rely on the fact that older version of Log4J2 either do not have the org/apache/logging/core/net/JndiManager.class or that the class does not have the log4j2 configuration string added in 2.15.0.

* find_log4j.py - Python script to find log4j2 < 2.15.0 on a linux host
* find_log4j.sh - Bash script to find log4j2 < 2.15.0 on a linux host
* find_log4j.ps1 - Powershell script to find log4j2 < 2.15.0 on a Windows host - note that this comes with a .NET 4.5 System.IO.Compression.FileSystem.dll in base64 so that it is able to run on servers without .NET installation. These lines can be removed if you know that you have .NET Framework > 4.5 on the hosts you are scanning. 