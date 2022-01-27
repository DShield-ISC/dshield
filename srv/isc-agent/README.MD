# README #

## What is this repository for? ##

[TODO: add description]

## How do I get set up? ##

1. Install [docker](https://docs.docker.com/get-docker/) by following the steps in the link provided.
2. Clone the repository to your computer.
    ```shell script
    git clone git@github.com:DShield-ISC/dshield.git {{ project location }}
    ``` 
3. Go to the project directory and change the branch to `epic/ISC-1-web-rebuild`
    ```shell script
    cd {{ project location }}
    git checkout epic/ISC-1-web-rebuild
    git pull
    ``` 
4. Run the following command to cd into the isc-agent directory.
    ```shell script
    cd srv/isc-agent
    ```
5. Run the following command to start the project.
    ```shell script
    # This command should be ran anytime new packages are added to the project.
    # It is good habit to rebuild everytime you pull down new code.
    make docker-up
    ```

### IDE Setup ###

#### PyCharm ####

1. Open preferences > Project > Project Structure > expand `srv` and then right click the `isc-agent` folder and choose `Sources`.

1. Go to Python Interpreter (should be the menu item right above Project Structure) and click the gear icon to add a new
   interpreter.

1. Click on `Docker` on the left side menu. In the form on the right, paste `./srv/isc-agent/docker-compose.yml` into the `Configuration File` field and for images choose `sans-isc-agent`. Everything else shouldn't need
   to be modified.

1. Click apply and close the window. You should be all set.

## Who do I talk to? ##

If any questions or issues arise please contact [Benson Myrtil](bmyrtil@sans.org) or [John Drew](jdrew@sans.org).

* A common troubleshooting step which will probably fix 75% of all issues is to run the following
  commands `make undeploy && make build && make deploy`

## Makefile ##

**Commands prefixed with `ops-` should not be modified or changed in any way as they are used specifically for
deployment purposes.**

Helpful commands have been added to the Makefile within this project. Feel free to add any command which makes
development easier for you.

### Common recipes ###

 ```shell script
make shell # Open a sh terminal in the contianer
make lint # Run linter against the application
make security # Run a security scan against the code
make test # Run all test with coverage. HTML output can be found in ./.generated/coverage/htmlcov/index.html
```
