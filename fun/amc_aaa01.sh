#!/bin/bash
#
# amc_aaa01.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.1
#
# Some fun

LOGO="
######################################################################################


 .S_SsS_S.     sSSs   .S_sSSs     .S   .S_SSSs      sSSs   .S_sSSs     .S   .S_sSSs    
.SS~S*S~SS.   d%%SP  .SS~YS%%b   .SS  .SS~SSSSS    d%%SP  .SS~YS%%b   .SS  .SS~YS%%b   
S%S \`Y' S%S  d%S'    S%S   \`S%b  S%S  S%S   SSSS  d%S'    S%S   \`S%b  S%S  S%S   \`S%b  
S%S     S%S  S%S     S%S    S%S  S%S  S%S    S%S  S%|     S%S    S%S  S%S  S%S    S%S  
S%S     S%S  S&S     S%S    S&S  S&S  S%S SSSS%S  S&S     S%S    d*S  S&S  S%S    d*S  
S&S     S&S  S&S_Ss  S&S    S&S  S&S  S&S  SSS%S  Y&Ss    S&S   .S*S  S&S  S&S   .S*S  
S&S     S&S  S&S~SP  S&S    S&S  S&S  S&S    S&S  \`S&&S   S&S_sdSSS   S&S  S&S_sdSSS   
S&S     S&S  S&S     S&S    S&S  S&S  S&S    S&S    \`S*S  S&S~YSSY    S&S  S&S~YSSY    
S*S     S*S  S*b     S*S    d*S  S*S  S*S    S&S     l*S  S*S         S*S  S*S         
S*S     S*S  S*S.    S*S   .S*S  S*S  S*S    S*S    .S*P  S*S         S*S  S*S         
S*S     S*S   SSSbs  S*S_sdSSS   S*S  S*S    S*S  sSS*S   S*S         S*S  S*S         
SSS     S*S    YSSP  SSS~YSSY    S*S  SSS    S*S  YSS'    S*S         S*S  S*S         
        SP                       SP          SP           SP          SP   SP          
        Y                        Y           Y            Y           Y    Y  

VERSION ${VERSION_INSTALL}

######################################################################################
"

# Planter l'appel si on appelle ce script directement
if [[ "$0" == *amc_aaa01.sh ]];then
	if [ "$1" == "-f" ]; then
		echo "$LOGO"
	else
		echo "
######################################
MediaSPIP fun
######################################
"
	
		tput setaf 1;
		echo "Ce script ne sert à rien... quoique 
"
		tput sgr0; 
		exit 1
	fi
fi