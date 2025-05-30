# Jenkins Docker container agent

## Introduction 

Here we will learn how to spin up a Docker container as a Jenkins build agent.

![](images/Architecture.png)

We will use terraform for resource deployments.

Terraform will deploy all the resources required, including two Vms, one which will run Jenkins on a Docker container; the other will run the Docker agent container.

Both Vms have script extensions to configure basic dependencies upon creation.

The Docker agent container will use a custom Docker image; the dockerfile can be found in this repository.

## Notes about terraform

- Don't forget to change `terraform.tfvars` to set vm admin username, etc.;

- The Virtual machines password will NOT be on the output, instead they can be securely found in the `terraform.tfstate` file;


## Steps

- Deploy the resources using terraform.

On the `agentVm`, edit the `docker.service` file to open `port 4243` allowing tcp connection: `remember to be on the right directory`

    sudo vi usr/lib/systemd/system/docker.service

modify the current line: 

`ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock`

![](images/dockerserviceModification.png)


Restart docker services:

    sudo systemctl daemon-reload

and

    sudo systemctl restart docker

you can test the connection using the other Vm:

    curl http://<agentvmip>:4243/version

![](images/curlTest.png)

>`the ip was censored`

- Proceed with the basic jenkins installation on the `master Vm`. You will need to install the `Docker plugin`:

![](images/JenkinsInititalSetup.png)

>`masterVm running Jenkins master`

- Head to `Manage Jenkins > Clouds`, add a new cloud of type docker;

- On the docker host url, insert the agent vm url as follows:

>`tcp://<agentvmIp>:4243`

![](images/NewCloudConfiguration.png)

>`the ip was censored`

- Test the connection and enable it, also expose `DOCKER_HOST`;

- Set the container cap;

- Now on `docker template`, add a new template;

- Set the label and name;

- On the docker image option set the image you want to use, in our case we will use a custom docker image:
`nokorinotsubasa/agent175:v5`

- Set the `"Remote File system Root"` as `/home/ubuntu`:

![](images/DockerAgentTemplateConfiguration.png)

- On the connect method option choose connect with ssh;

- On `ssh key`, select `"Use configured SSH credentials"`;

- On credential, add an `"Username and password"` type of credentials;

- Set username as `jenkins` and password as `jenkins`, this was defined on the custom docker image which will run the docker agent;

- On Host key Verification Strategy, choose `"Non verifying Verification Strategy"`;

>`this is not recommended and will be done just for demonstration`

![](images/DockerAgentTemplateSSHConfiguration.png)

>`final configuration`

- That's it, now on the `freestyle pipeline` configuration, set the `"Restrict where this build can run"` with the name of the label you defined on the docker template configuration.
In case of a `pipeline script`, set as:
`"agent {label 'label'}"`

- E.g.

![](images/pipelineScript.png)

- As you can see, a new docker container was deployed, it was used to run the pipeline, and then was destroyed:

![](images/docker-agent-pipeline.png)

>`Running on docker-agent-00000kac0e5xb on docker-agent in /home/ubuntu/workspace/docker-agent-pipeline`

- If you head into `Cloud statistics`, you can check some information on the agents:

![](images/Jenkins%20Cloud%20Statistics.png)

