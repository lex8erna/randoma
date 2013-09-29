#!/bin/bash

# Getopt for syntax
ARGS=`getopt -o "ihvr:adcm:s" -l "interactive,help,verbose,repeat:,analytic,dice,coin,minimum:,silent" \
      -n "getopt.sh" -- "$@"`

# Checking for bad arguments
if [ $? -ne 0 ];
then
  exit 1
fi

eval set -- "$ARGS"

# Flags
interactive=
verbose=
analytic=
dice=
coin=
repeat=
minimum=
silent=

# Option parsing
while true;
do
  case "$1" in
    -h|--help)
      echo "Syntax: random "
      exit 1;;
      
    -s|--silent)
      interactive=
      verbose=
      analytic=
      silent=1
      shift;;
      
    -i|--interactive)
      silent=
      interactive=1
      shift;;
      
    -v|--verbose)
      silent=
      verbose=1
      shift;;
 
    -r|--repeat)
      if [[ $2 = *[!0-9]* ]]; then
        echo "Non-number argument(s) found for repetition mode: $2"
        exit 1
      elif [[ $2 < 1 ]]; then
        echo "Invalid repetition argument: $2"
        exit 1
      fi
      repeat=$2
      shift 2;;
    
    -m|--minimum)
      if [[ $2 = *[!0-9]* ]]; then
        echo "Non-number argument(s) found for lower bound: $2"
        exit 1
      fi
      minimum=$2
      shift 2;;
    
    -a|--analytic)
      silent=
      verbose=1
      analytic=1
      shift;;
 
    -d|--dice)
      dice=1
      shift;;
      
    -c|--coin)
      coin=1
      shift;;
    
    --)
      shift
      break;;
      
  esac
done

# Repetition mode
if [[ $repeat && !($silent)]]; then
  echo "Repeating $repeat times"
  iterations=$repeat;
else
  iterations=1;
fi

for ((j=0; j<iterations; j++))
do
  # Check for no args
  if [[ $# -eq 0 ]]; then
    echo "Insufficient arguments."
    exit 1
  fi
  
  # Check for non-number args
  for i in $@
  do
    if [[ $i = *[!0-9]* ]]; then
      echo "Non-number argument(s) found: $i"
      exit 1
    fi
  done
  
  # Collecting information from arguments
  if [[ $coin ]]; then
    iterations=$1
    range=2
  elif [[ $# -eq 1 ]]; then
    iterations=1
    range=$1
  else
    iterations=$1
    range=$2
  fi
  
 # Start of random number generation
  if ! [[ $silent ]]; then
    echo "==Start=="
  fi

  # Setting up upper and lower bounds
  if [[ $minimum ]]; then
    if [[ $minimum -gt $range ]]; then
      echo "Invalid range: Lower bound $minimum larger than upper bound $range."
      exit 1
    elif [[ $minimum -eq $range ]]; then
      echo "Invalid range: Lower bound $minumum = Upper bound $range."
      exit 1
    fi
    ((diff=range-minimum))
    
    if ! [[ $silent ]]; then
      echo "Rolling $iterations""d$diff+$minimum"
    fi
  else
    minimum=1
    if ! [[ $silent ]]; then
      echo "Rolling $iterations""d$range"
    fi
  fi
     
  avg=0.0
  sum=0
  
  for (( i=1; i<=iterations; i++)); do
    if [[ $interactive ]]; then
      read
    fi
    
    ((curr= $RANDOM % (range-minimum+1) + minimum))
    ((sum+= $curr))
    ((results[curr]++))
    
    # Verbose dialog
    if [[ $verbose ]]; then
      if [[ $coin ]]; then
        case $curr in
          1) echo "Heads!";;
          2) echo "Tails!";;
        esac
      else
        echo "Rolled a $curr! (Total=${results[$curr]})"
      fi
      
      if [[ $analytic ]]; then
        avg=$(echo "scale=2;($avg*($i-1)+$curr)/$i" | bc -l)
        echo "Average: $avg"
      fi
    fi
  done
  
  
  if [[ $silent ]]; then
    echo $sum
  else
    echo "Results:"
    if [[ $coin ]]; then
      echo "Heads: ${results[1]}"
      echo "Tails: ${results[2]}"
    else
      for (( i=$minimum; i<=$range; i++))
      do
        echo "$i : ${results[$i]}";
      done
      echo Total: $sum
    fi
  fi
  
  unset results
done
