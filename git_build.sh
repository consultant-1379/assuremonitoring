#!/bin/bash

if [ "$2" == "" ]; then
    echo usage: $0 \<module\> \<Branch\> \<Workspace\> \<BUILD_USER_ID\> \<D\> \<REASON\>
    exit -1
else
    versionProperties=install/version.properties
    theDate=\#$(date +"%c")
    module=$1
    branch=$2
    workspace=$3
    BUILD_USER_ID=$4
    REASON=$5
    CT=/usr/atria/bin/cleartool
    release_area=/home/$USER/eniq_events_releases
fi


function getReason {
        if [ -n "$REASON" ]; then
		REASON=`echo $REASON | sed 's/$\ /x/'`
		REASON=`echo JIRA:::$REASON | sed s/" "/,JIRA:::/g`
        else
                REASON="CI-DEV"
        fi
}


function getProductNumber {
        product=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $3}'`
	tag_product=`echo $product | sed 's/\//_/g'`
}

function setRstate {

        revision=`cat ${PWD}/build.cfg | grep $module | grep $branch | awk -F " " '{print $4}'`

        if git tag | grep $product-$revision; then
            build_num=`git tag | grep $revision | wc -l`

            if [ "${build_num}" -lt 10 ]; then
				build_num=0$build_num
			fi
			rstate=`echo $revision$build_num | perl -nle 'sub nxt{$_=shift;$l=length$_;sprintf"%0${l}d",++$_}print $1.nxt($2) if/^(.*?)(\d+$)/';`
		else
            ammendment_level=01
            rstate=$revision$ammendment_level
        fi
        echo "Building R-State:$rstate"

}


function getSprint {
        sprint=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $5}'`
}

function getSprint1 {
        sprint_stats=`cat $PWD/build.cfg | grep $module | grep 15.2 | awk -F " " '{print $5}'`
}

getSprint
getSprint1
getProductNumber
echo "PRODUCTTAG = $tag_product"
setRstate
getReason
echo "RSTATE = $rstate "
git clean -df
git checkout $branch
git pull


echo "Building for Sprint:$sprint"
echo "Building assuremonitoring_$rstate on $branch"
echo "Building rstate: $rstate"

#/proj/$USER/bin/lxb mvn clean jacoco:prepare-agent install jacoco:report pmd:pmd -Dassuremonitoring.rstate=$rstate
/proj/eiffel013_config/fem101/jenkins_home/bin/lxb mvn clean jacoco:prepare-agent install jacoco:report pmd:pmd -Dassuremonitoring.rstate=$rstate

rsp=$?

if [ $rsp == 0 ]; then
 git tag $tag_product-$rstate
 git pull
 git push --tag origin $branch
 
 cd $PWD
 mv $PWD/assuremonitoring-pkg/target/solaris/assuremonitoring.pkg assuremonitoring_$rstate.pkg
 cp assuremonitoring_$rstate.pkg $release_area/assuremonitoring_$rstate.pkg
fi  

if "${Deliver}"; then
    if [ "${DELIVERY_TYPE}" = "SPRINT" ]; then
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto events ${sprint} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $release_area/assuremonitoring_$rstate.pkg" deliver_ui
	$CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto stats ${sprint_stats} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $release_area/assuremonitoring_$rstate.pkg" deliver_ui
else
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/eu_deliver_eniq -EU events ${sprint} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $release_area/assuremonitoring_$rstate.pkg" deliver_ui
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/eu_deliver_eniq -EU stats ${sprint} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $release_area/assuremonitoring_$rstate.pkg" deliver_ui
    fi
else
   echo "The delivery option was not selected.."
    fi
exit $rsp
