# Jenkins shared functions and scripts

## Overview
This directory contains shared functions and scripts meant to be used with jenkins pipelines. Jenkinsfile and pipeline are required beforehand to start a job.

## Jenkins Configuration

### Overview
Jenkins is a self-contained, open sourced automation server that can automate tasks related to building and testing. Its functionality can be expanded by installing plugins.

Jenkins main function is to launch jobs. Jobs are scripts that cover managing repositories, building and testing. Jenkins pipeline is a script that is launched by Jenkins job. Each pipeline consists of build stages that follow one another, for example: download repository, build, test, etc. Each stage consists of steps that are actual commands ran on device under a test - which is called: Node.

## Quick access to Jenkins
To gain access to a working Jenkins instance quickly, use the links provided below and follow instructions contained therein:
- https://hub.docker.com/r/jenkins/jenkins
- https://github.com/jenkinsci/docker/blob/master/README.md

## Requirements
To run tests it is required to install these plugins first:
- Branch API
- Command Agent Launcher
- Configuration as Code
- Email Extension
- External Monitor Job Type
- Folders
- Git
- Git client
- GitLab
- Job DSL
- Multijob
- Oracle Java SE Development Kit Installer
- PAM Authentication
- Pipeline Utility Steps
- Pipeline: Build Step
- Pipeline: Multibranch
- Pipeline: REST API
- Pipeline: Stage View
- SSH Agent
- SSH Build Agents

Optional but recommended plugins for graphical and security improvements:
- Blue Ocean
- Dashboard View
- JUnit
- LDAP
- Matrix Authorization Strategy
- Matrix Combinations
- OWASP Markup Formatter
- Timestamper

## Managing Jenkins

### Overview
Jenkins can be configured and managed "as a code" - it means that actual jobs and pipelines can be downloaded from a remote repository. But first, it is needed to add a job that downloads jobs definitions from the remote repository and configures Jenkins. The instructions below allow to manually trigger creating/updating jobs, but it is possible to trigger this job automatically with each push to the target repository.

### Add master executor
Before running any job, it is needed to add an executor which will run a Jenkins job. First, it is required to add an executor on the master node - which is a server containing the Jenkins instance. This executor will lunch the job and then the pipeline will be executed on the node with a label matching the "LABEL" field in the job params.

To add master executor:

- Select: "Manage Jenkins".
- Select: "Manage Nodes and Clouds".
- Select: "master" node.
- Select: "Configure".
- In the field "# of executors" type "4".
- Select: "Save".

### Add job-generating jobs
To add a Job that generates jobs from Jenkinsfile:

- Select: "New item".
- Enter jobs name, e.g. "job_creator".
- Select: "Pipeline".
- Click OK.
- In tab "General", select "GitHUB Project", enter project url, e.g.: "https://github.com/pmem/pmemkv".
- In the "Pipeline" tab, set fields as below:
    - Definition: Pipeline script from SCM
    - SCM: Git
    - Repositories:
      - Repository URL: Enter github repository with jenkins job, e.g.: "https://github.com/pmem/pmemkv".
      - Credentials: none
    - Branches to build:
      - Branch Specifier (blank for 'any'): master (or any other branch containing jenkinsfile).
    - Script Path: Enter path with the Jenkinsfile, relative to the root folder of the repository: "utils/jenkins/Jenkinsfile"
    - Lightweight checkout: yes
- Save.
- Enter the newly created job from the main dashboard.
- Click on the "Build Now".

### In-process Script Approval
By default, Jenkins will prevent running new groovy scripts which will cause our job to fail. After each fail caused by an unapproved script, it is needed to accept this script. Unfortunately, this will be necessary to repeat several times, by launching this job repeatedly (when running the job for the first time).

To approve scripts:

- Select: "Manage Jenkins".
- Select: "In-process Script Approval".
- Click "Approve".

### Test nodes
To run Jenkins jobs, it will be needed to add additional Nodes (beside of master Node) which are servers prepared to run tests. Each Node is required to have:

- Installed Java Runtime Environment.
- Installed and running an SSH server, open ssh port (22).
- The added user that Jenkins can log on, with appropriate credentials needed to run tests, e.g. "test-user".

#### Adding test nodes
In this case, we will be using a server with Fedora31 installed and user "test-user" created.

- Select: "Manage Jenkins".
- Select: "Manage Nodes and Clouds".
- Select: "New Node".
- Type name in the "Node name" field, "Server_001(fedora31)".
- Select "Permanent Agent" (after creating a node, it is possible to copy an existing configuration by selecting "Copy Existing Node").
- Click "OK".
- In the field "# of executors" type "1".
- In the field "Remote root directory" type directory that Jenkins user has credentials to access to. In our case: /home/test-user
- In the field "Labels" type an actual OS installed on the server - in our case type "fedora fedora31" NOTE: There can be multiple labels assigned to the server.
- In the field "Usage" select "Use this node as much as possible".
- In the field "Launch method" select "Launch agent agents via SSH".
- In the field "Host" type IP address of the server, in format x.x.x.x
- In the field "Credentials" click "Add" and then "Jenkins" to create new credentials: 
    - In the field "Domain" select "Global credentials (unrestricted)".
    - In the field "Kind" select "Username with password".
    - In the field "Scope" select "System (Jenkins and nodes only)".
    - In the field "Username" type username - in our case: "test-user".
    - In the field "Password" enter password.
    - In the field "ID" enter username - in our case "test-user".
    - Click "Add"
- In the field "Credentials" select newly created credentials - in our case: "test-user".
- In the field "Host Key Verification Strategy" select "Manually trusted key Verification Strategy".
- In the field "Availability" select "Keep this agent online as much as possible".
- Click "Save"

### Job overview
Jenkins jobs can be accessed from the main dashboard. To select a job click on the name of that job. To run the job, click "Build with Parameters". To access the finished job, click on the Build name in the "Build History" section or in the "Stage view" section. In the build view "Build Artifacts" can be accessed, containing "console.log". NOTE: console logs are available also by clicking on "Console Output" or "View as plain text", which is useful when a pipeline was unable to generate logs, or job failed from script errors, or Jenkins related errors, e.g. unapproved scripts.

### Running a Job
Enter the Job view and click "Build with Parameters". Some build configuration can be made. To run the job, click "Build".

