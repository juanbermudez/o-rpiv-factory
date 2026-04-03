#!/bin/bash
set -e

echo "Deploying web app..."
vercel --prod --archive=tgz
echo "Web app deployed. Now safe to deploy website-platform."
