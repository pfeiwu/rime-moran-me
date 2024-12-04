#!/bin/bash

echo fetching kagiroi...
git submodule foreach git fetch origin
echo done

echo replacing existing files...
cd sub/kagiroi
find ./ -type f -name 'kagiroi*' -exec cp --parents {} ../../ \;
echo done

