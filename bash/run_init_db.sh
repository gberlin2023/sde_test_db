#!/bin/bash
docker pull postgres
docker run --env=POSTGRES_USER=test_sde --env=POSTGRES_PASSWORD=@sde_password012 --env=POSTGRES_DB=demo -p 5432:5432 -d --name pg -v "/mnt/c/_work/git":/home/gberlin/git -v "/mnt/c/_work/git/sql/init_db":/docker-entrypoint-initdb.d postgres
