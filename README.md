# Pentaho 4 PDI Buildpack

The pentaho-pdi-buildpack is a Cloud Foundry buildpack for running Pentaho Data Integration (PDI) jobs. It is intended to allow projects based on the standard PDI template, [pentaho4-pdi](https://github.com/voxgen/pentaho4-pdi), to be deployed to a Stackato PaaS, but it makes minimal assumptions about the actual package to be deployed.

## Usage
If this buildpack has been uploaded to Stackato then you only need to include a `kettle.properties` file in the directory you are pushing from for it to be used. In this case you can simply change to the directory containing the tar file to deploy and the `kettle.properties` file and execute `stackato push`.

Alternatively, there are two ways to manually specify this buildpack - either specify the URI of this GitHub repository as a parameter when pushing an application to Cloud Foundry:

```bash
stackato push --buildpack https://github.com/voxgen/pentaho4-pdi-buildpack.git
```

or else specify it within the `manifest.yml` in the directory that you are pushing from:

```
applications:
- name: my-app
  buildpack: https://github.com/voxgen/pentaho4-pdi-buildpack.git
  ...
```

Note that deploying a Pentaho PDI application can take some time as the packaged staged application (droplet) is very large. During the creation and upload of the droplet no log entries are created, which can mean that the Stackato command line client ends with the following message: `Error: Application is taking too long to start (121 seconds since last log entry), check your logs`. 

In this case, the push process is still running and you can monitor it by tailing the log stream via `stackato logs --follow`, but you can also avoid this situation by increasing the timeout on the push command, e.g. to allow 5 minutes without log entries, use

```
stackato push --timeout 5m
```

## Requirements for a Deployable App

In addition to the usual `manifest.yml` file, the directory that you are pushing from must contain a `kettle.properties` file containing the usual settings as used in the template PDI projects along with a `.tar.gz` package containing the ETL jobs, transformations, scripts etc. In addition, it can include a `hlpr_call_entry_points_friendly_names.csv` file to specify the configured DNIS numbers.

### Tar file

There must also be exactly one `.tar.gz` package in the directory or the push will fail. Furthermore the tar package must itself contain exactly one top-level directory, under which all the ETL files are stored. This is the default packaging created by the Maven build in the template PDI projects.

### kettle.properties

The presence of `kettle.properties` is used to determine whether the package can be deployed by this buildpack. As part of the staging of the application the following variables will be set in `kettle.properties` (if they are already specified then the existing setting will be overwritten):

```
PDI_DIR - location of the Pentaho PDI installation
ETL_DIR - location of the Kettle jobs
```

Any scripts in the app to be deployed should make use of these variables, rather than using hardcoded paths, so that they can run in the staged environment. Scripts can do this by sourcing the `kettle.properties` file, e.g.

```
source ~/.kettle/kettle.properties

cd $PDI_DIR/data-integration/
./kitchen.sh -file $ETL_DIR/jobs/Load_Helper_Files.kjb
```

Note that the scripts in the latest revisions of the Pentaho 4 PDI template ([pentaho4-pdi](https://github.com/voxgen/pentaho4-pdi)) already take this approach.

### hlpr_call_entry_points_friendly_names.csv

This file contains a list of the DNIS numbers used as entry points to the IVR. Since this typically needs to be set by OSS rather than developers, this file can be included in the deployment directory as an external file (i.e. not packaged in the tar file). 

If this file is present in the deployment directory then it will override any file with the same name included in the tar file.

## Staging Process
The buildpack extracts and deploys the package provided in the push directory and then performs the following steps:

### Install Dependencies
The following dependencies are installed:

- Java OpenJDK
- Pentaho Data Integration (PDI)
- Liquibase

The URLs to retrieve these dependencies from are taken from the `config/dependencies.properties` file in the buildpack. This file can be changed to specify different versions of dependencies if required.

A Postgres JDBC driver is also added to the Liquibase installation so that it does not need to be specified when executing liquibase commands.

### App Re-Configuration
The extracted package is re-configured in order to run in the staged container. This involves setting variables such as `PDI_DIR` and `ETL_DIR` in `kettle.properties` (as described above), adding the installed Java and Liquibase executables to the `PATH` and exposing the following additional environment variables:
- `KETTLE_HOME`: location of the `kettle.properties` file
- `LIQUIBASE_HOME`: location of the `liquibase` exexcutable

### Database Configuration
The buildpack checks the `kettle.properties` file and if the database specified via the `REPORTING_DB_...` variables does not exist then it creates it. It then checks that the `dw` and `mart` schemas exist, and creates them if they don't.

The buildpack also checks for `LOGGING_X_DB_...` variables (X=1,2,..) which are used to specify one or more call logging databases to use as input. For each specified database, the buildpack checks whether the database exists, and creates it if it doesn't.

Note that the buildpack only ensures that the required databases exist and have the correct schemas - it does not run any DDL to create tables, indexes etc, or helper jobs to load data. This is left to the deployed application to do via staging hooks, or as part of its execution. The reason for this is to allow each application to deploy its own schema using whatever process is most appropriate (e.g. SQL scripts, Liquibase changelogs etc). 

## Manifest Settings
The `manifest.yml` required to push a PDI project differs slightly from that for a standard web application. These differences are described below.

### No URL

Because a PDI project does not contain a web application, the running app should not be assigned a URL (otherwise Stackato will wait for a response from that URL to test whether the app is running). To do this specify `url: []` in the manifest file.

### Cron

The PDI project will run jobs scheduled by cron. You can use the Stackato 'cron' extension in the manifest file to set-up the required schedules, e.g. to run the `scripts/loadIncremental.sh` script every minute:

```
stackato:
  cron:
    - "*/1 * * * * $HOME/scripts/loadIncremental.sh >> $HOME/log/loadIncremental.log"
```

### Logging

Scripts run with cron normally redirect their output to a log file (as shown above). In order to include that log file in the log stream for your app you can set the `STACKATO_LOG_FILES` environment variable (see [Application Logs](http://docs.stackato.com/user/deploy/app-logs.html) for more details):

```
stackato:
  env:
    STACKATO_LOG_FILES: incremental=app/log/loadIncremental.log:$STACKATO_LOG_FILES
```

You will also need to ensure the log file exists when the application starts running. You can do this by using a post-staging hook as shown below:

```
stackato:
  hooks:
    post-staging:
    - touch $HOME/log/loadIncremental.log
```

Note that if a job runs regularly then its log file will become very large and possibly exceed the disk space allocated to the docker container. You should consider implementing log rotation using `logrotate` scheduled via `cron` as described in [Application Logging](http://docs.stackato.com/user/deploy/app-logs.html).

## Database Setup and Helper Jobs
As noted above, the buildpack ensures that any required databases exist, but it is the responsibility of the application to create the required relations, indexes etc. This can be done by including a schema creation script and executing it via a post-staging hook. The staged container will include the `psql` utility which can be used to run SQL scripts, and also contains `liquibase` in order to run Liquibase changesets (which is the preferred approach). 

For example, the following runs the `report_db_schema.sh` script included in [pentaho4-pdi](https://github.com/voxgen/pentaho4-pdi) in order to setup the report database once the app has been staged:

```
stackato:
  hooks:
    post-staging:
    - $HOME/db/report_db_schema.sh
```

In the latest version of [pentaho4-pdi](https://github.com/voxgen/pentaho4-pdi) it is no longer necessary to run a `loadHelpers` job to set-up helper dimensions - this is now done as part of the `loadIncremental` job. If you do, however, need to run a manual ETL job before starting the scheduled jobs then it can be executed via a `pre-running` hook, as shown below:

```
stackato:
  hooks:
    pre-running:
    - $HOME/scripts/myJob.sh
```

Note that any ETL jobs or transformations that rely on the `ETL_DIR` variable in `kettle.properties` can *not* be run in a post-staging hook - the reason for this is that the `ETL_DIR` variable will be set to the required location for the running app, but the job and transformation files will actually be in a different (temporary) location whilst staging. ETL jobs that rely on this variable can therefore only be run once staging is complete and the app is about to enter a running state. 

One final thing to note is that any jobs that are going to be run automatically via hooks should be able to be run more than once without causing any damage. Scripts run via `post-staging` will be executed whenever the app is deleted and re-pushed, and those run via `pre-running` will execute whenever the app is stopped and started. If a job really cannot be run more than once (and cannot be changed to do so) then it will need to be done manually by SSHing into the deployed app and running the required script before the scheduled jobs start.

## Memory Settings
By default each job execution (via kitchen.sh) will be assigned a max heap size of 512MB. This can be changed by setting the `PENTAHO_DI_JAVA_OPTIONS` environment variable as below:

```
stackato:
  env:
    PENTAHO_DI_JAVA_OPTIONS: -Xmx768m
```

It is important to check whether more than one job may be executing at the same time and ensure that the overall memory assigned to the container in the `manifest.yml` is large enough to accommodate this. E.g. if there may be 2 jobs executing at once and each has the default 512MB assigned then the container needs more than 1GB to allow both jobs to run plus any other processes that are running in the container.

It should also be possible to set the above environment variable on a per-job basis by including it as part of the cron command for a particular job.

## Example Manifest File
The following is an example of a manifest to deploy a PDI project, including setting up the database, loading helper tables and configuring the crontab:

```
applications:
- name: pdi-dpdng
  memory: 768M
  disk: 1G
  url: []
  stackato:
    hooks:
      post-staging:
      - $HOME/db/report_db_schema.sh
      - touch $HOME/log/loadIncremental.log 
      pre-running:
      - $HOME/scripts/loadHelpers.sh
    env:
      STACKATO_LOG_FILES: incremental=app/log/loadIncremental.log:$STACKATO_LOG_FILES
    cron:
      - "*/1 * * * * $HOME/scripts/loadIncremental.sh >> $HOME/log/loadIncremental.log"   
```

- No URL is assigned to the running app 
- The post-staging hooks run a script to create the report database and create the log file for the incremental job
- The pre-running hook runs a job to load helper dimensions immediately before the app starts
- The log file for the incremental job is added to the app log stream
- The execution of the incremental job is scheduled via cron

## Building Packages
The buildpack can be packaged up so that it can be uploaded to Stackato using the `stackato create-buildpack` and `stackato update-buildpack` commands. In order to create a package, clone the buildpack then run the `bin/package` script - the resulting zip file will be created in the `build` directory of the buildpack:

```
$ bin/package
Staging buildpack
Creating zip file
  adding: bin/ (stored 0%)
  adding: bin/package (deflated 55%)
  adding: bin/detect (deflated 11%)
  adding: bin/compile (deflated 56%)
  adding: bin/release (deflated 6%)
  adding: config/ (stored 0%)
  adding: config/dependencies.properties (deflated 40%)
  adding: lib/ (stored 0%)
  adding: lib/config.sh (deflated 64%)
  adding: lib/web_proc.sh (deflated 30%)
  adding: lib/output.sh (deflated 35%)
  adding: lib/database.sh (deflated 71%)
  adding: lib/dependencies.sh (deflated 61%)
  adding: lib/package.sh (deflated 59%)
  adding: profile/ (stored 0%)
  adding: profile/setenv.sh (deflated 40%)
done
```

By default, this will create an online package that will download dependencies via the Internet. In the case of PDI, this download can take some time which means that the deployment of the app can be quite slow. To avoid this, you can include the required dependencies within the deployed buildpack by adding the `--cached` argument to the package command. The zip file created will contain all the required artefacts and will run without needing access to the Internet:

```
$ bin/package --cached
Staging buildpack
Packaging dependencies with the buildpack
Downloading https://download.run.pivotal.io/openjdk/precise/x86_64/openjdk-1.8.0_60.tar.gz
######################################################################## 100.0%
Downloading http://downloads.sourceforge.net/project/pentaho/Data%20Integration/4.4.0-stable/pdi-ce-4.4.0-stable.tar.gz
######################################################################## 100.0%
Downloading https://github.com/liquibase/liquibase/releases/download/liquibase-parent-3.4.1/liquibase-3.4.1-bin.tar.gz
######################################################################## 100.0%
Creating zip file
  adding: bin/ (stored 0%)
  adding: bin/package (deflated 55%)
  adding: bin/detect (deflated 11%)
  adding: bin/compile (deflated 56%)
  adding: bin/release (deflated 6%)
  adding: dependencies/ (stored 0%)
  adding: dependencies/liquibase-3.4.1-bin.tar.gz (deflated 1%)
  adding: dependencies/openjdk-1.8.0_60.tar.gz (deflated 1%)
  adding: dependencies/pdi-ce-4.4.0-stable.tar.gz (deflated 0%)
  adding: config/ (stored 0%)
  adding: config/dependencies.properties (deflated 40%)
  adding: lib/ (stored 0%)
  adding: lib/config.sh (deflated 64%)
  adding: lib/web_proc.sh (deflated 30%)
  adding: lib/output.sh (deflated 35%)
  adding: lib/database.sh (deflated 71%)
  adding: lib/dependencies.sh (deflated 61%)
  adding: lib/package.sh (deflated 59%)
  adding: profile/ (stored 0%)
  adding: profile/setenv.sh (deflated 40%)
done
```

The buildpack zip file can be uploaded to Stackato using:

```
stackato create-buildpack <name> <zip file>
```

You can set options such as `--position` in order to determine where in the list of buildpacks it should be added (Stackato tries each buildpack in sequence starting at postion 1 until it finds one that can deploy the package being pushed).
