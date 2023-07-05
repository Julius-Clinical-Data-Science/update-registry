#### PROGRAM NAME           : update_registry.R
#### NAME OF PROGRAMMER     : Wout Aarts
#### DATE OF CREATION       : 20230703
#### DESCRIPTION OF PURPOSE : Documenting export folder production
#### INPUT FILES USED       : A path to the folder or repo that needs documentation 
####                          of .R scripts and the pathand the path to the d6 output folder  
#### OUTPUT FILES CREATED   : A registry within the d6 output 
#### MODIFICTION HISTORY    : 
####                          

library(data.table)


path_to_folder <- "."
path_to_d6_output <- file.path(".", "d6_output")

# Create new subfolder in the d6 folder which can be output to DRE 
dir.create(file.path(path_to_d6_output, "registry"))


create_hash_registry <- function(path_to_folder, path_to_d6_output, write_or_return = "return") {
  #' This function creates a registry from all .R files in a repo or folder and
  #' adds a unique hash. Note that the hash that is created will be consistent 
  #' when the function is used within the same version of R
  
  # Create data.table with a column called hash_file_path with the paths to all files in the folder
  registry <- data.table(
    hash_file_path = list.files(path = path_to_folder, pattern = ".R$", recursive = TRUE)
  )
  
  # Add column with tim
  registry[, `:=` (
    # Add column with timestamp, representing when file was updated last
    timestamp = as.character(file.info(hash_file_path)$atime), #TODO this timestamp does not work! 
    # Add column with a hash code, see ?rlang::hash_file for more information
    commit_hash = rlang::hash_file(hash_file_path) 
  )]
  
  # Write to d6 output if write_or_return is set to write
  if (write_or_return =="write") {
    fwrite(registry, file.path(path_to_d6_output, 'registry', "registry.csv"))
  }
  
  # Return registry if write_or_return is set to return
  if (write_or_return == 'return') {
    return(registry)
  }
}

create_hash_registry(path_to_folder, path_to_d6_output, write_or_return = "write")




compare_folder_with_registry <- function(
    path_to_folder,
    path_to_d6_output, 
    write_or_return = "return"
) {
  #' Use the create_hash_registry function to create a registry of the current 
  #' state and compare against the orginal registry. This function will only
  #' work if there is a file called [path_to_d6_output]/registry/registry.csv 
  #' that is created with the function create_hash_registry
  #' If write_or_return is set to "write", this function outputs a folder, 
  #' which has a time stamp in the name, in the folder [path_to_d6_output]/registry 
  #' which contains a csv file with the updated scripts and a copy of the updated scripts as well
  
  # Create registry of new folder
  registry_new <- create_hash_registry(path_to_folder = path_to_folder, path_to_d6_output = NULL, write_or_return = "return")
  
  # Load on the old registry
  registry_old <- fread(file.path(path_to_d6_output, "registry", "registry.csv"))
  
  # Find the files that do not have the same commit hash
  adjusted_files <- registry_new[!registry_old, on = "commit_hash"]
  
  # If write_or_return is set to "return", return the adjusted files
  if (write_or_return == "return"){
    return(adjusted_files)
  } 
  
  
  # If write_or_return is set to "write", create a new folder within the registry subfolder
  if (write_or_return == "write") {
    
    
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
      
      # Write the registry with the adjusted hashes the new subfolder 
      fwrite(adjusted_files, file.path(path_to_d6_output, "registry", new_folder_name, "registry_adjusted_files.csv"))
    }
  }
}

compare_folder_with_registry(path_to_folder, path_to_d6_output)
compare_folder_with_registry(path_to_folder, path_to_d6_output,  write_or_return = "write")







print("")
print("System Details and Date")
print(date())
print(Sys.time())
print(Sys.Date())
print(Sys.timezone())
print(sessionInfo())