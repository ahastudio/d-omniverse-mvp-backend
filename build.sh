docker build --platform linux/amd64 -t d-omniverse-mvp-backend .

docker save -o d-omniverse-mvp-backend.tar d-omniverse-mvp-backend:latest

scp -rp d-omniverse-mvp-backend.tar root@64.176.229.20:/root/work/
