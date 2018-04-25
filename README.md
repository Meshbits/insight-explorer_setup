# Insight explorer setup

## What this will do

- System optimisation
 - Stop unnecessary services
 - Enable swapfile - necessary for vps/cloud offerings
 - Create a user - default: meshbits
- Setup requisite packages for komodo
 - Install komodo in `/home/$USER/komodo`


## To run setup

```
git clone git@bitbucket.org:meshbits/insights-explorer_setup.git
cd insights-explorer_setup
./bin/setup.sh
```

## To run test

This can be helpful when komodo and requisites have already been compiled and
you only want to test the configuration changes

```
git clone git@bitbucket.org:meshbits/insights-explorer_setup.git
cd insights-explorer_setup
./bin/setup.sh
```
