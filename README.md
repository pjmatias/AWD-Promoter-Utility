# AWD-Promoter-Utility
A utility for automating the deployment of models and forms from one AWD environment to another.

AWD Promoter Utility
Version 1.0 - August 13, 2018

----------------
Contents
----------------
1 - Overview
2 - Requirements
3 - Installation and configuration
4 - Known issues
5 - Instructions for use
6 - License

----------------
Overview
----------------

The AWD Promoter Utility is a ruby-based, command-line program for automating the deployment of models and forms from one AWD environment to another.  It is designed to assist AWD system administrators in migrating change between non-production environments and in promoting changes to production.  The utility was designed specifically for DST hosted environments (both DPC and DB2) but can function on most self-hosted or cloud-hosted configurations as well.

The current version supports migrating individual models.  Support for migrating forms, design packages, and configuration options is currently planned for future versions.

----------------
Requirements
----------------

This utility requires Ruby.  It was built and tested on version 2.5.1.  The installation site must also have access to the targeted AWD environments.

----------------
Installation and configuration
----------------

All files should be extracted to a single directory.

To configure:
	1 - Open the env_config.rb in a text editor.
	2 - Modify the $server, $server_dpc_non and $server_dpc_prod values to match the location of your AWD installation.  The $server value should be used if you have a consistent server location for both prod and non-prod environments.  The $server_dpc_non and $server_dpc_prod should be used if you have different locations for prod and non-prod.
	3 - Save the file
	4 - If specific certificates are required to access your AWD installation, replace the cacert.pem file with a pem file containing those specific certificates.
	
	
----------------
Known issues
----------------

1 - The utility does not support using different passwords for different environments.  Currently, use must use the same credentials for both source and target environments.

----------------
Instructions for use
----------------

The AWD Promoter Utility supports three different use cases: 1) comparing deployed model versions between two different AWD environments, 2) staging a list of models for deployment from one environment to another, and 3) deploying models between environments.  The compare models function can be used in a stand-alone capacity to identify differences between environments.  The stage/deploy functions are designed to be used sequentially.

Common instructions:
- For all functions, you will be prompted for the name, dpc status, and credentials of both a source environment and target environment.
- Source environment refers to the environment you wish to export models from.
- Target environment refers to the environment you wish to export models to.
- The DPC flag allows you to switch between the endpoints configured in the env_config.rb file.  'N' triggers the $server value, 'Y' triggers to $server_dpc_non and 'P' triggers the $server_dpc_prod.
- You must enter valid credentials for each environment.  The user must have permission to the AWD Design Studio.

Compare models:
To use the compare models function, launch the Deploy.rb file and enter '1' at the 'Enter number' prompt.  Enter the desired environment information and user credentials for the source and target environments.  The utility will compare deployed models and version numbers in both environments and generate a deploy_service.csv file listing the models that are not in sync.

Stage models:
Staging models is the first step of migrating models between environments.  To use this function, you must have a file deploy_service.csv with a list of models you wish to migrate.  Each model should be listed on a separate line and the name must exactly match the name in the source environment.  To use, launch the Deploy.rb file and enter '2' at the 'Enter number' prompt.  Enter the desired environment information and user credentials for the source environment.  The utility will obtain the version number and GUID of the currently deployed version of each model listed in the deploy_service.csv file and append it to the model names in that file.  If any models do not have a deployed version, or if the model cannot be found, the text 'None' will appear in the deploy_service.csv in place of the version number and GUID.  You should troubleshoot these models prior to moving on to the deploy models function.

Deploy models:
The deploy models function is the final step in migrating models and will physically export/import models from the source environment to the target environment.  Prior to executing this step, you must have completed the stage models step and have a deploy_service.csv file containing valid version numbers and GUIDs.  To use, launch the Deploy.rb file and enter '3' at the 'Enter number' prompt.  Enter the desired environment information and user credentials for the source and target environments. At the 'Ready to deploy?' prompt you have the option to either save the models as a draft in the target environment, or deploy them.  Entering 'Y' will deploy the models; entering 'S' will save them.  The utility will then migrate the models and either save or deploy based on your selected option.

----------------
License
----------------
This project is licensed under the MIT License - see LICENSE for details.
