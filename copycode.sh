#!/bin/bash
# MLOPS Pipeline which will create the Github repositories and Jenkins Pipeline for new project
export PROJNAME=$1
export DOCKER_USER=$2
export DOCKER_PWD=$3
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
if [ ${#PROJNAME} -gt 15 ]; 
then
	echo "The length of the project name needs to be less than or equal to 15";
	exit 1 
else
	echo $PROJNAME" is of correct size of <=15 characters"
fi

# Create the base functions
function copyGit
{
	case $GITTYPE in
	I)
		export WORKDIR="mlopsTemplateInfra"
		export TargetDIR="${PROJNAME}Infra"
		;;
	D)
		export WORKDIR="mlopsTemplateDocker"
		export TargetDIR="${PROJNAME}Docker"
		;;
	T)
		export WORKDIR="mlopsTemplateTrain"
		export TargetDIR="${PROJNAME}Train"
		;;
	esac
	
	rm -rf "${WORKDIR}"
	git clone "${GITTEMPLATEURL}"
	if [ $? -eq 0 ]; 
    	then
        	#echo $GITTEMPLATEURL" cloned successfully"
			echo $WORKDIR" cloned successfully"
    	else
        	#echo $GITTEMPLATEURL" clone failed"
			echo $WORKDIR" clone failed"
        	exit 1
	fi
	mv "${WORKDIR}" "${TargetDIR}";cd "${TargetDIR}";rm -rf .git;echo ""
	sed -i "s/mlopsTemplate/$PROJNAME/g" config.prop
	#echo "Cloned to ${WORKDIR}; pushing to ${GITNEWPROJECTURL}"
	echo "Cloned to ${WORKDIR}; pushing to ${TargetDIR}"
	
	if [ $? -eq 0 ]; 
   	then
        	#echo $GITNEWPROJECTURL" initiated successfully"
			echo $WORKDIR" initiated successfully"
    	else
        	#echo $GITNEWPROJECTURL" initiation failed"
			echo $WORKDIR" initiation failed"
       		exit 1
    	fi
        #gh auth login --with-token </mycode/ghToken.txt
	gh auth login --hostname github.optum.com --with-token </mycode/ghToken.txt
	gh repo create "github.optum.com/gov-prog-mdp/"$TargetDIR --private --enable-issues=true --enable-wiki=true --confirm
	if [ $? -eq 0 ]; 
    	then
        	#echo $GITNEWPROJECTURL" created successfully"
			echo $TargetDIR" created successfully"
    	else
        	#echo $GITNEWPROJECTURL" creation failed"
			echo $TargetDIR" creation failed"
        	exit 1
    	fi
	gh auth logout --hostname github.optum.com
	rm -rf .git;rm -rf $TargetDIR
	git init
	git config --global user.email "lakshmiujwala_golla@optum.com"
 	git config --global user.name "ujwala"
	touch README.md
	git add .
	git commit -m "first commit"
	git remote add origin ${GITNEWPROJECTURL}
	if [ $? -eq 0 ]; 
    then
		#echo $GITNEWPROJECTURL" remoted successfully"
		echo $TargetDIR" remoted successfully"
   	else
		#echo $GITNEWPROJECTURL" remoting failed"
		echo $TargetDIR" remoting failed"
		exit 1
    fi
	git push -u origin master
	if [ $? -eq 0 ]; 
    then
		#echo $GITNEWPROJECTURL" pushed successfully"
		echo $TargetDIR" pushed successfully"
	else
		#echo $GITNEWPROJECTURL" push failed"
		echo $TargetDIR" push failed"
		exit 1
	fi
	cd ..;rm -rf "${WORKDIR}";echo "Done."
	
}
function copyPipeline
{
    curl -k -X GET 'https://jenkins-gov-prog-digital.origin-elr-core-nonprod.optum.com/job/mlopsTemplate'${PIPETYPE}'/config.xml' -u ${DOCKER_USER}:${DOCKER_PWD} -o config.xml
    if [ $? -eq 0 ]; 
    then
        echo "Successfully got the config.xml of mlopsTemplate"$PIPETYPE
        #cat config.xml
        export NEWREPO=${PROJNAME}${PIPETYPE}
        sed -i "s/mlopsTemplate${PIPETYPE}/${NEWREPO}/g" config.xml
        if [ $? -eq 0 ];
        then 
            echo "Successfully modified config.xml of mlopsTemplate"$PIPETYPE
                    
        else
            echo "Failed to modify config.xml of mlopsTemplate"$PIPETYPE
        fi
    else
        echo "Failed to extract the config.xml of mlopsTemplate"$PIPETYPE
        exit 1
    fi
	# File where web session cookie is saved
	COOKIEJAR="$(mktemp)"
    CRUMB=$(curl -k -s --cookie-jar "$COOKIEJAR" 'https://jenkins-gov-prog-digital.origin-elr-core-nonprod.optum.com/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -u ${DOCKER_USER}:${DOCKER_PWD})
    status=$?
    if [ $? -eq 0 ]; 
    then
        echo "CRUMB generated successfully for "$PIPETYPE
    else
        echo "Failed to generate CRUMB for "$PIPETYPE
        exit 1
    fi
    echo $CRUMB
        
    curl -k -XPOST 'https://jenkins-gov-prog-digital.origin-elr-core-nonprod.optum.com/createItem?name='${NEWREPO} -u ${DOCKER_USER}:${DOCKER_PWD} --data-binary @config.xml -H "$CRUMB" -H "Content-Type:text/xml" --cookie "$COOKIEJAR"
    if [ $? -eq 0 ]; 
    then
        echo ${NEWREPO}" pipeline created successfully"
    else
        echo "Failed to create the pipeline "${NEWREPO}
        echo $?;exit 1
    fi
}

# Lets create the repositories for the new project from the templates
export BASEGITURL="https://${DOCKER_USER}:${DOCKER_PWD}@github.optum.com/gov-prog-mdp/"
# (1) Copying the mlopsTemplateInfra repository
export GITTYPE="I"
export GITTEMPLATEURL=$BASEGITURL"mlopsTemplateInfra.git";export GITNEWPROJECTURL=$BASEGITURL$PROJNAME"Infra.git";
#echo $GITTEMPLATEURL"-->"$GITNEWPROJECTURL;
copyGit
# (2) Copying the mlopsTemplateDocker repository
export GITTYPE="D"
export GITTEMPLATEURL=$BASEGITURL"mlopsTemplateDocker.git";export GITNEWPROJECTURL=$BASEGITURL$PROJNAME"Docker.git";
#echo $GITTEMPLATEURL"-->"$GITNEWPROJECTURL;
copyGit
# (3) Copying the mlopsTemplateTrain repository
export GITTYPE="T"
export GITTEMPLATEURL=$BASEGITURL"mlopsTemplateTrain.git";export GITNEWPROJECTURL=$BASEGITURL$PROJNAME"Train.git";
#echo $GITTEMPLATEURL"-->"$GITNEWPROJECTURL;
copyGit


# Lets create the jenkins pipeline for the new project from the templates
# (1) Copy the mlopsTemplateInfra pipeline
export PIPETYPE="Infra";copyPipeline
# (2) Copy the mlopsTemplateDocker pipeline
export PIPETYPE="Docker";copyPipeline
# (3) Copy the mlopsTemplateTrain pipeline
export PIPETYPE="Train";copyPipeline

