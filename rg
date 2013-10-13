#!/bin/bash

cd `pwd`
find . ! \( -name ".git" -prune -o -name tmp -prune -o -name log -prune \) -type f -exec grep -IHn $1 {} \;
