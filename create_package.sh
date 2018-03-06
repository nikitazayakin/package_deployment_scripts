#!/bin/bash
#generates package for deployment
#overwrites current package if presents
set -e

BUILD=false

while getopts b: option
do
case "${option}"
in
b) BUILD=${OPTARG};;
esac
done

#parameters
#GloriaJeans-ECommerce
cid_and_pi=glj-ec
ver=0.0.1
hybris_dir=/opt/hybris6_6
#array or environments values, can be: (dev,qa,stage,prod)
declare -a environments=(dev)

#generated vars
script_dir=/opt/dep_packages
basefiles_dir=$script_dir/basefiles
package_name=$(printf "%s_v%s" "$cid_and_pi" "$ver")
pwd=$(pwd)
package_dir=$pwd/$package_name
hybris_packages_dir=$hybris_dir/hybris/temp/hybris/hybrisServer
dev_config_dir=$hybris_dir/hybris/config
package_config_dir=$package_dir/hybris/config
package_bin_dir=$package_dir/hybris/bin
#remove 'cp' to 'cp -i' alias if any
#unalias cp 2>/dev/null

echo script starts
#echo basefiles dir $basefiles_dir
#echo curdir+pack $pwd/$package_name
#echo package dir $package_dir
#echo hybris_packages_dir $hybris_packages_dir

#remove folder if exists
if [ -d "$package_dir" ]; then
  echo package folder already exists, removed old package folder
  rm -rf $package_dir
fi

if [ -f "$package_dir.zip" ]; then
  echo package zip already exists, renamed it
  #append file modification datetime to package zip file
  file_date=$(stat -c%y $package_dir.zip | cut -d'.' -f1 | tr ' ' '_')
  mv "$package_dir.zip" "$package_dir$file_date.zip"
fi

echo create directory structure
if [ ! -d "$package_bin_dir" ]; then
  mkdir -p "$package_bin_dir"
fi
if [ ! -d "$package_config_dir" ]; then
  mkdir -p "$package_config_dir"
fi

#build packages
if [ "$BUILD" = true ] ; then
  echo building packages
  cd $hybris_dir/hybris/bin/platform
  ant production #2>/dev/null
  cd $script_dir
else
  echo omitting package creatiion
fi

echo create metadata.properties
cp $basefiles_dir/metadata.properties $package_dir
echo copy packages into /hybris/bin
yes | cp -rf $hybris_packages_dir/hybrisServer-Platform.zip $package_dir/hybris/bin
yes | cp -rf $hybris_packages_dir/hybrisServer-AllExtensions.zip $package_dir/hybris/bin

echo create config
echo ${#environments[@]} is number of environments

if [ ${#environments[@]} -gt 1 ]; then
  # create config for every environment
  echo creating config for more than one environment isn\'t ready yet;
  exit $ERRCODE;
else
  echo creating config for one environment;
  cp $dev_config_dir/local.properties $package_config_dir/customer.properties
  cp $dev_config_dir/localextensions.xml $package_config_dir/localextensions.xml
fi
  echo config created

echo creating archive
zip -r $package_name.zip $package_name

echo package created
echo create MD5 file
md5sum $package_name.zip > $package_name.md5
echo check MD5 file
md5sum -c $package_name.md5

