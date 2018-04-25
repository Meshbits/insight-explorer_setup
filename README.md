# insight-explorer setup

## Important

- Setup requires you to be **root**
- Tested and support on **Ubuntu LTS 16.04 x64 only**

## What this will do

- System optimisation
  - Stop unnecessary services
  - Enable swapfile - necessary for vps/cloud offerings
  - Create a user - default: meshbits
- Setup requisite packages for komodo
  - Install **komodo** in `/home/$USER/komodo`


## To run setup

```
git clone https://github.com/Meshbits/insight-explorer_setup.git
cd insights-explorer_setup
./bin/setup.sh
```

### To start assetchains

```
su - meshbits
~/.komodo/bin/ac_start_all.sh
```

## To run test


This can be helpful when komodo and requisites have already been compiled and
you only want to test the configuration changes

```
git clone https://github.com/Meshbits/insight-explorer_setup.git
cd insights-explorer_setup
./test/run.sh
```

## to-do

- Setup insight-explore
  - Use `bitcore_insight_explorer.tar.bz2` as the code; _This is a dirtier way of setting things up for now; we'll eventually code the setup scripts to use git repo._
  - Setup configuration based on `komodod/$ASSETCHAIN`
