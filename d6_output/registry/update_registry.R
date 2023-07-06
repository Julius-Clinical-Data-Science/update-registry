#### PROGRAM NAME           : update_registry.R
#### NAME OF PROGRAMMER     : Wout Aarts
#### DATE OF CREATION       : 20230703
#### DESCRIPTION OF PURPOSE : Providing tools to create a registry that helps to
####                          keep track of local changes after a repository has
####                          been downloaded and uploaded to a server that has 
####                          no connection to git
#### INPUT FILES USED       : A path to the folder or repo that needs documentation 
####                          of .R scripts and the path to the d6 output folder  
#### OUTPUT FILES CREATED   : A file called registry/registry.csv within the d6  
####                          output folder, which will contain a row for all the .R files
####                          and a hash for every .R file which is created by the
####                          create_hash_registry function. When the compare_folder_with_registry
####                          is executed, it will create a folder called
####                          registry/[timestamp] which will contain a csv file 
####                          called registry_adjusted_files.csv which lists all 
####                          the changed files, and the folder will also contain
####                          a copy of the updated .R file
#### MODIFICATION HISTORY  : 
if(!require(janitor)){
  install.packages("janitor")
}

if(!require(data.table)){
  install.packages("data.table")
  library(data.table)
}
library(data.table)

create_hash_registry <- function(path_to_folder, path_to_d6_output, write_or_return = "return") {
  #' This function creates a registry from all .R files in a folder and
  #' adds a unique hash. Note that the hash that is created will be consistent 
  #' when the function is used within the same version of R
  
  # Create data.table with a column called hash_file_path with the paths to all files in the folder
  registry <- data.table(
    hash_file_path = list.files(path = path_to_folder, pattern = ".R$", recursive = TRUE)
  )
  
  registry[, `:=` (
    # Add column with timestamp, representing when file was updated last modified
    timestamp = as.character(file.info(hash_file_path)$mtime), #TODO this timestamp does not work! 
    # Add column with a hash code, see ?rlang::hash_file for more information
    commit_hash = rlang::hash_file(hash_file_path) 
  )]
  
  # Write to d6 output if write_or_return is set to write
  # Return registry if write_or_return is set to return
  if (write_or_return == "write") {
    fwrite(registry, file.path(path_to_d6_output, 'registry', "registry.csv"))
  } else if (write_or_return == 'return') {
    return(registry[])
  }
}

compare_folder_with_registry <- function(
    path_to_folder,
    path_to_d6_output, 
    write_or_return = "return"
) {
  #' Use the create_hash_registry function to create a registry of the currently 
  #' saved versions of all scripts, and compare against the orginal registry. 
  #' This function will only work if there is a file called [path_to_d6_output]/registry/registry.csv 
  #' that is created with the function create_hash_registry
  #' If write_or_return is set to "write", this function outputs a folder, 
  #' which has a time stamp in the name, in the folder [path_to_d6_output]/registry 
  #' which contains a csv file with the names, new hash and latest modification
  #' time of the  updated scripts and a copy of the updated scripts as well
  #' (except when there are no updated scripts, then it will not create anything)
  #' If write_or_return is set to 'return" the function will return the dataframe 
  #' that lists all the adjusted scripts in the console. 
  
  # Create registry of new folder
  registry_new <- create_hash_registry(path_to_folder = path_to_folder, path_to_d6_output = NULL, write_or_return = "return")
  
  # Load on the old registry
  registry_old <- fread(file.path(path_to_d6_output, "registry", "registry.csv"))
  
  # Find the files that do not have the same commit hash
  adjusted_files <- registry_new[!registry_old, on = "commit_hash"]
  
  # If write_or_return is set to "return", return the adjusted files
  # If write_or_return is set to "write", create a new folder within the registry subfolder
  
  if (write_or_return == "return") {
    return(adjusted_files[])
  } else if (write_or_return == "write") {
    # Only create a new folder if there are adjusted files
    if (dim(adjusted_files)[1] > 0) {
      # The name of the folder will be a time stamp representing the time of creation 
      new_folder_name <- janitor::make_clean_names(Sys.time())
      
      # Create new subfolder 
      dir.create(file.path(path_to_d6_output, "registry", new_folder_name))
      
      # Copy all scripts that have been changed to the new subfolder
      lapply(
        adjusted_files[, hash_file_path], 
        function(x) file.copy(x, file.path(path_to_d6_output, 'registry', new_folder_name),
                              recursive = FALSE,  copy.mode = TRUE)
      )
      
      # Write the registry with the adjusted hashes in the new subfolder 
      fwrite(adjusted_files, file.path(path_to_d6_output, "registry", new_folder_name, "registry_adjusted_files.csv"))
    }
  }
}
