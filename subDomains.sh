#!/bin/bash

RefreshResolvers(){
    echo "Enter number of threads:"
    read numThreads
    echo "start refresh resolvers list. Wait few minutes"
    docker run --rm -t dnsvalidator -tL https://raw.githubusercontent.com/BonJarber/fresh-resolvers/main/resolvers.txt -threads $numThreads --no-color --silent > resolvers.txt 	
}

CreateFilename(){
  file=$(echo $1 | cut -f 1 -d '.');
  fileName=$(touch $file.txt);
  echo $file.txt
}



FindDomain(){

    # TODO:
    # Manual entering path to config files for gathering information

    amass enum -passive -d $1 -config ~/pentesting/configs/amass/config_passive.ini -o amass.result;
    subfinder -d $1 -config ~/pentesting/configs/subfinder/config.yaml -all --silent -o subfinder.result;
    chaos -d $1 -silent -o chaos.result;
    findomain -t $1 -q -u findomain.result;
    github-subdomains -d $1 -o github-subdomains.result;
    crobat -s $1 -u >> corbat.result;
    
}

fileName=$(CreateFilename $1);


FiltredResult(){

    echo "Crated file with name $fileName"
    cat github-subdomains.result subfinder.result chaos.result amass.result findomain.result corbat.result | sort -u -o $fileName 
    rm  *.result
}

ResolveAllResult(){

    # TODO:
    # resolve httpx to different ports
    ## small: 80, 443
    ## medium: 80, 443, 8000, 8080, 8443
    ## large: 80, 81, 443, 591, 2082, 2087, 2095, 2096, 3000, 8000, 8001, 8008, 8080, 8083, 8443, 8834, 8888, 9000, 9090, 9443
    ## huge: 80, 81, 300, 443, 591, 593, 832, 981, 1010, 1311, 2082, 2087, 2095, 2096, 2480, 3000, 3128, 3333, 4243, 4567, 4711, 4712, 4993, 5000, 5104, 5108, 5800, 6543, 7000, 7396, 7474, 8000, 8001, 8008, 8014, 8042, 8069, 8080, 8081, 8088, 8090, 8091, 8118, 8123, 8172, 8222, 8243, 8280, 8281, 8333, 8443, 8500, 8834, 8880, 8888, 8983, 9000, 9043, 9060, 9080, 9090, 9091, 9200, 9443, 9800, 9943, 9980, 9981, 12443, 16080, 18091, 18092, 20720, 28017


    shuffledns -d $1 -list $fileName -r resolvers.txt -o $fileName.resolved;
    httpx -l $fileName.resolved -threads 20 -o httpxFullInfo.$fileName -ip -content-length -follow-redirects -status-code -no-color -fc 503,502,501;
    awk '{print $1}' httpxFullInfo.$fileName | sort -u -o httpx.$fileName
}


NucleiFastCheck(){
    nuclei -l httpxFullInfo.$fileName -t ~/nuclei-templates/ -silent -nc -o nuclei.$fileName
}

echo "Do u wanna update resolvers list [y/N]?"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ; then
    RefreshResolvers;
fi

FindDomain $1;
FiltredResult;

echo "Do u wanna resolve gathering domains? [y/N]"
read answer2

if [ "$answer2" != "${answer2#[Yy]}" ] ; then
    ResolveAllResult $1;
fi

echo "Do u wanna sending resolved resulting to nuclei?"
echo "All host with all status code will checking. Maybe slow speed."

read answer3

if [ "$answer3" != "${answer3#[Yy]}" ] ; then
    NucleiFastCheck;
fi