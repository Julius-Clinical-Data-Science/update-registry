# update-registry

This repository provides a tool to apply version control in scripts in an automated fashion, when other users need to run the scripts in an environment that has no connection to github, and need to make local changes to the scripts.
Applying the tool correctly, will ensure consistency and reproducibility of results. 


## Instruction
- Fork the repo
- Open update-registry/data_characterisation/to_run.R
- Run all lines
- Note that a file update-registry/d6_output/registry/registry_init.csv now exists, which contains an initial hash for all .R-scripts in the folder data_characterisation
- Now change a line in one of the scripts step*.R within the data_characterisation directory and save the file
- Run the compare_folder_with_registry(path_to_folder, path_to_d6_output, write_or_return = "write") line again in the to_run.R scripts
- Note that there now exists an additional folder named after the timestamp of creation in d6_output/registry/ which contains a registry update csv file and a copy of the updated R script.


## How to apply the tool

### DESCRIPTION OF PURPOSE: 
Providing tools to create a registry that helps to keep track of local changes after a repository has been downloaded and uploaded to a server that has no connection to git

### INPUT FILES USED
A path to the folder or repo that needs documentation of .R scripts and the path to the d6 output folder  

### OUTPUT FILES CREATED: 
A file called registry/registry_init.csv within the d6 output folder, which will contain a row for all the .R files and a hash for every .R file which is created by the create_hash_registry function. When the compare_folder_with_registry is executed, it will create a folder called registry/[timestamp] which will contain a csv file  called registry_adjusted_files.csv which lists all the changed files, and the folder will also contain a copy of the updated .R file.

