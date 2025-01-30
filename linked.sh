#!/bin/env bash

for FL in $(ls /usr/bin | grep "\-20"); do NWFL=${FL/-20/}; ln -s /usr/bin/$FL /usr/bin/$NWFL; done
